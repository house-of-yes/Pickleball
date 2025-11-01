# Development Protocols


---

## Ex Rule (Exigent Directory)

- The **first executable line** of every bash patch/script is an explicit `cd <path>` that will succeed regardless of the starting directory (exigent).
  - ✅ `cd "$HOME/Pickleball"`
  - ✅ `cd "$HOME/Pickleball/HouseOfYes/king_of_swing"`
  - ❌ `cd .` / `cd ..` / `cd Pickleball` (ambiguous)

- **No literal “PATCH” header** inside bash patches. Comments are fine, but every line must be valid shell or a `#` comment. A bare word like `PATCH` yields **rc=127** and is a **Code-1 foul**.


---

## Whiff

A **whiff** happens when the assistant swings at the ball but doesn’t quite connect —  
for example, dropping a patch with an error. If the assistant immediately notices the miss  
and replays with a corrected artifact, that’s a whiff.

- ✅ Whiffs are **self-corrected errors**. They’re not fouls because the user never had to call them out.  
- ❌ If the user has to call it out, it’s no longer a whiff — it’s a **foul**.  

Whiffs keep the rally moving fast: small misses are just part of the game,  
as long as they’re corrected immediately without needing an Umpire Call. 🏓
