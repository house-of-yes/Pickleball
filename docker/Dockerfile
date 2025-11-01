# Minimal container for the Pickleball daemon (Starlette-only)
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    EXCALIBUR_WORKSPACE=/workspace \
    EXCALIBUR_ALLOWLIST=. \
    EXCALIBUR_TEST_CMD="PYTHONPATH=. pytest -q" \
    EXCALIBUR_LOG_FILE=.ide-bridge.log \
    PORT=8765

WORKDIR /app
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app/

# Workspace volume (mount your repo here)
VOLUME ["/workspace"]

EXPOSE 8765
CMD ["python", "app_starlette.py"]
