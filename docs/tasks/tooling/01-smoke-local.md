# tooling 01: local smoke test launcher (1 server + 3 clients)

Roadmap Phase 2: "Local 1 server + 3 clients smoke test script". Only create `tools/smoke_local.ps1` and add one README line. No game code.

## Facts
- Godot binaries on PATH: `godot` (GUI) and `godot_console` (console). Project root is the repo root.
- `main/Main.gd`: `--server` (engine arg or after `--`) starts the ENet dedicated server on port 7777; no flag = client connecting to 127.0.0.1:7777. Client user arg `--ui-dev` loads the web UI from the Vite dev server instead of `ui/dist`.
- Existing script style: `tools/install_godot_cef.ps1` (`param(...)`, `$ErrorActionPreference = "Stop"`, `$PSScriptRoot`).

## Steps
1. Create `tools/smoke_local.ps1`:
   ```powershell
   # Starts 1 headless server and N windowed clients for a local smoke test.
   # Usage (repo root): pwsh tools/smoke_local.ps1 [-Clients 3] [-UiDev] [-Stop]
   param([int]$Clients = 3, [switch]$UiDev, [switch]$Stop)
   ```
   Behaviour:
   - `$root = Resolve-Path (Join-Path $PSScriptRoot "..")`; logs go to `$root\.smoke\` (create it; add `.smoke/` to `.gitignore` if not already ignored).
   - `-Stop`: stop every process started by a previous run (PIDs saved in `.smoke\pids.txt`), delete the file, exit.
   - Otherwise: if `.smoke\pids.txt` exists, stop those PIDs first. Start the server: `godot_console --headless --path $root -- --server`, stdout/stderr redirected to `.smoke\server.log` / `.smoke\server.err.log` (`Start-Process -PassThru -RedirectStandardOutput ... -RedirectStandardError ... -WindowStyle Hidden`). Wait until `server.log` contains the server-ready line or 15 s pass: find the exact text Main/ServerManager prints when the server is listening (search `print(` in `main/Main.gd` and `autoload/ServerManager.gd`) and match on it; on timeout print the last 20 log lines and exit 1.
   - Start `$Clients` clients: `godot --path $root --position X,Y --resolution 960x540` (positions tiled: 0,0 / 980,0 / 0,580 / 980,580, then repeat) with `-- --ui-dev` appended when `-UiDev`; each client's output to `.smoke\client<N>.log` / `.err.log`, `-PassThru`.
   - Save all PIDs to `.smoke\pids.txt`, one per line, and print a summary: PIDs, log folder, how to stop (`pwsh tools/smoke_local.ps1 -Stop`).
   - Check the Godot 4.7 CLI help (`godot_console --help`) for the exact `--position` / `--resolution` flag names before using them; if a flag does not exist, drop it and say so.
2. `README.md`: in the section that explains how to run the game (search for `--server`), add one line: `Local smoke test (1 server + 3 clients): pwsh tools/smoke_local.ps1 (stop with -Stop).`
3. Run it once: `pwsh tools/smoke_local.ps1 -Clients 1`, confirm the server log shows the ready line and the client process is alive after 10 s, then `pwsh tools/smoke_local.ps1 -Stop` and confirm no process from `pids.txt` is left.

## Do not
- No changes outside `tools/`, `.gitignore`, `README.md`. Do not touch `ui/`. Do not run git.

## Done when
- The run in step 3 works and `-Stop` cleans up.
- Final answer: files created/changed, the server-ready line you matched, flags you dropped (if any), output of the step 3 run.
