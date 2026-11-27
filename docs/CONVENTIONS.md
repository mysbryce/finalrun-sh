# Project Conventions

Every brief and every worker run must follow this file. If a task needs a rule this file does not cover, the supervisor adds it here first.

## Folder structure

```
res://
  autoload/            # Singletons only. Thin orchestration, no reusable logic.
    ServerManager.gd
  lib/                 # Our shared, reusable code. Must NOT import anything from features/, maps/, ui/.
    constants/         # GameConst.gd: map names, capacities, ports, timings. Single source for magic numbers.
    utils/             # Pure static helpers (class_name + static func, no state, no Node access).
    net/               # RPC and visibility helpers: send to member peers, validate sender, grant/revoke visibility.
    components/        # Reusable Nodes/scenes used by composition (e.g. ChannelTimer, InteractArea, Health).
    data/              # Resource class definitions (ItemData, LootTableData). Instances (.tres) go in data/.
  features/            # Gameplay, one folder per domain. May use lib/. Should not reach into another feature's internals.
    instance/          # Instance.gd (SubViewport instance root), instance registry logic
    party/             # Party.gd
    player/            # Player.tscn, Player.gd, PlayerRoleController.gd
    heist/             # Lootable.gd, LootDrop.gd
  maps/                # One folder per map: maps/motel/Motel.tscn + map-only scripts.
  ui/                  # All client UI. See docs/design/WEB_UI.md.
    hud/               # Godot side: Hud.gd hosts the CefTexture and speaks the IPC protocol.
    web/               # Web UI source (Vite + React + TS + Zustand + Tailwind + TanStack). Has .gdignore.
    dist/              # Built web UI (npm run build in ui/web/). Generated and committed; never hand-edit.
  data/                # .tres content (items, loot tables, map configs).
  assets/              # models/, textures/, audio/, fonts/ (imported art only, no scripts).
  addons/              # Third-party code and Godot plugins only. Never edit vendored code in place.
  main/                # Boot scene (Main.tscn, Main.gd): server/client entry.
  tests/               # Mirrors source tree: tests/lib/utils/test_xxx.gd, tests/features/party/test_party.gd
  tools/               # Dev-only scripts and scenes (smoke drivers in tools/smoke/). Never loaded by the game.
    run_tests.gd       # Single entry: runs every test_*.gd, prints ALL TESTS PASSED, exits 0/1.
```

### Dependency direction (one way only)
`main/ -> autoload/ -> features/ -> lib/`, and `maps/`, `ui/` -> `features/`, `lib/`.
`lib/` depends on nothing in the project except other `lib/` files. A cycle is a bug.

## Naming
- Folders: `snake_case`.
- Script and scene files: `PascalCase.gd` / `PascalCase.tscn`, same as their `class_name`.
- Tests: `test_<subject>.gd`.
- One `class_name` per file. Constants `UPPER_SNAKE`, private members `_leading_underscore`.

## Reuse rules
1. **Search before writing.** Before adding a helper, check `lib/`. Extend an existing helper instead of writing a near copy.
2. **Rule of two.** Logic needed in a second place moves to `lib/` in that same change. No copy-paste between features.
3. **No magic numbers in features.** Capacities, ranges, timings, prices live in `lib/constants/GameConst.gd` or a `.tres`.
4. **Pure logic is separate from Nodes.** Rules (can_attack, pick_instance, surrender outcome) are static or RefCounted functions that take data and return data, so tests run without a network or scene tree. Nodes call them.
5. **Composition over inheritance.** Reusable behavior is a component Node/scene in `lib/components/`, configured with `@export` vars. Inheritance only for true "is-a" (max 1 level of project base classes).
6. **Networking goes through `lib/net/`.** Features never call raw `rpc()` broadcast; they use the net helpers that target instance members and validate the sender.
7. **Data as Resources.** Item/loot definitions are `Resource` subclasses in `lib/data/` with `.tres` files in `data/`, not hardcoded dictionaries.
8. **No speculative abstractions.** No base class, interface, or manager for a single user. Add it when the second user appears (rule 2).

## Code
- Typed GDScript everywhere (`var x: int`, typed params and returns, typed arrays).
- Comments in English, explain why, not what.
- Server-authoritative: client code only sends requests; the server validates and applies.
- Web UI talks to Godot only through the IPC protocol in `docs/design/WEB_UI.md`. Never put game rules in the web UI; it displays state and sends requests.
