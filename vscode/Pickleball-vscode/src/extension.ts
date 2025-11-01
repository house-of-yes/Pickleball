import * as vscode from 'vscode';

// Read config with sensible fallbacks
function cfg() {
  const c = vscode.workspace.getConfiguration('Pickleball');
  return {
    baseUrl: (c.get<string>('baseUrl') || 'http://127.0.0.1:8765').replace(/\/+$/, ''),
    token: c.get<string>('token') || '',
    runTestsOnApply: !!c.get<boolean>('runTestsOnApply'),
  };
}

function headersJSON(token: string) {
  const h: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) h['X-Pickleball-Token'] = token;
  return h;
}

async function applyCurrentBuffer() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showWarningMessage('No active editor.');
    return;
  }
  const { baseUrl, token, runTestsOnApply } = cfg();
  const doc = editor.document;
  const relPath = vscode.workspace.asRelativePath(doc.uri, false);
  const content = doc.getText();

  const payload = {
    path: relPath,
    content,
    run_tests: runTestsOnApply,
  };

  const p = vscode.window.withProgress(
    { location: vscode.ProgressLocation.Notification, title: `Pickleball: applying ${relPath}`, cancellable: false },
    async () => {
      const res = await fetch(`${baseUrl}/apply`, {
        method: 'POST',
        headers: headersJSON(token),
        body: JSON.stringify(payload),
      });
      if (!res.ok) {
        const txt = await res.text();
        throw new Error(`Apply failed: ${res.status} ${txt}`);
      }
      const data = await res.json();
      const tests = data.tests;
      if (tests) {
        const status = tests.status === 'pass' ? '✅' : '❌';
        vscode.window.showInformationMessage(`${status} Tests ${tests.status} (${tests.duration_sec}s)`);
      } else {
        vscode.window.showInformationMessage('✅ Applied (tests skipped)');
      }
    }
  );

  try { await p; } catch (e: any) {
    vscode.window.showErrorMessage(String(e.message || e));
  }
}

async function getFile() {
  const { baseUrl, token } = cfg();
  const relPath = await vscode.window.showInputBox({
    prompt: 'Enter relative path to fetch (e.g., roles/example.py)',
    ignoreFocusOut: true,
  });
  if (!relPath) return;

  try {
    const url = new URL(`${baseUrl}/get`);
    url.searchParams.set('path', relPath);
    const res = await fetch(url, { headers: headersJSON(token) });
    if (!res.ok) {
      const txt = await res.text();
      throw new Error(`GET failed: ${res.status} ${txt}`);
    }
    const data = await res.json();
    const doc = await vscode.workspace.openTextDocument({ content: data.content, language: guessLanguage(relPath) });
    await vscode.window.showTextDocument(doc, { preview: false });
    vscode.window.showInformationMessage(`📄 Opened ${data.relpath} (${data.size} bytes)`);
  } catch (e: any) {
    vscode.window.showErrorMessage(String(e.message || e));
  }
}

function guessLanguage(path: string): string | undefined {
  if (path.endsWith('.py')) return 'python';
  if (path.endsWith('.ts')) return 'typescript';
  if (path.endsWith('.js')) return 'javascript';
  if (path.endsWith('.json')) return 'json';
  if (path.endsWith('.md')) return 'markdown';
  if (path.endsWith('.yml') || path.endsWith('.yaml')) return 'yaml';
  return undefined;
}

let ws: WebSocket | null = null;
let statusItem: vscode.StatusBarItem | null = null;

function connectEvents(context: vscode.ExtensionContext) {
  const { baseUrl, token } = cfg();
  const wsUrl = baseUrl.replace(/^http/, 'ws') + '/events';

  if (!statusItem) {
    statusItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
    statusItem.text = 'Pickleball: $(plug)';
    statusItem.tooltip = 'Pickleball events';
    statusItem.show();
    context.subscriptions.push(statusItem);
  }

  if (ws) {
    ws.close();
    ws = null;
  }

  try {
    // @ts-ignore Node 18+ has global WebSocket in VSCode extension host
    ws = new WebSocket(wsUrl);
  } catch (e: any) {
    vscode.window.showErrorMessage(`WebSocket not available: ${e?.message || e}`);
    return;
  }

  ws.onopen = () => {
    statusItem!.text = 'Pickleball: $(broadcast)';
    statusItem!.tooltip = `Connected to ${wsUrl}`;
    vscode.window.showInformationMessage('🔌 Pickleball: connected to events');
  };

  ws.onmessage = (ev: MessageEvent) => {
    try {
      const data = JSON.parse(String(ev.data));
      if (data.type === 'tests_done') {
        const ok = data.status === 'pass';
        const icon = ok ? '✅' : '❌';
        statusItem!.text = ok ? 'Pickleball: $(check)' : 'Pickleball: $(error)';
        vscode.window.showInformationMessage(`${icon} Tests ${data.status} (${data.duration_sec}s)`);
      } else if (data.type === 'file_applied') {
        statusItem!.text = 'Pickleball: $(sync)';
      }
    } catch {
      // ignore non-JSON lines
    }
  };

  ws.onclose = () => {
    statusItem!.text = 'Pickleball: $(debug-disconnect)';
    statusItem!.tooltip = 'Disconnected';
    vscode.window.showWarningMessage('Pickleball: events disconnected');
    ws = null;
  };

  ws.onerror = () => {
    statusItem!.text = 'Pickleball: $(issue-opened)';
  };
}

export function activate(context: vscode.ExtensionContext) {
  context.subscriptions.push(
    vscode.commands.registerCommand('Pickleball.applyBuffer', applyCurrentBuffer),
    vscode.commands.registerCommand('Pickleball.getFile', getFile),
    vscode.commands.registerCommand('Pickleball.connectEvents', () => connectEvents(context)),
  );
}

export function deactivate() {
  if (ws) { try { ws.close(); } catch {} ws = null; }
  if (statusItem) { statusItem.dispose(); statusItem = null; }
}
```0
