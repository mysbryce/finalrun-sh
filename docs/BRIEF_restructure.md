# Brief: Restructure to Conventions (Phase 1.5)

Pure refactor. **Behavior must not change.** All existing tests must keep passing with the same assertions.

Read `docs/CONVENTIONS.md` first; it is binding. Read `docs/ARCHITECTURE.md` for how the current code works.
All docs and comments in English. Do not run git.

## Godot binary
The WinGet `godot_console` link works now (GodotSharp junction added). A `.NET Sdk not found` error during `--import` is harmless (GDScript only).

## 1. Move files to the convention layout
| From | To |
|---|---|
| `core/Instance.gd` | `features/instance/Instance.gd` |
| `core/Party.gd` | `features/party/Party.gd` |
| `player/*` | `features/player/*` |
| `world/Lootable.gd`, `world/LootDrop.gd` | `features/heist/` |
| `maps/Motel.tscn` etc. | `maps/motel/Motel.tscn`, `maps/looty_bay/LootyBay.tscn`, `maps/house/House.tscn`, `maps/center/Center.tscn` |
| `tests/test_core.gd` | split per subject under `tests/` mirroring source (see 4) |

Move each `.gd.uid` together with its script. Update every `res://` path, `preload`, `load`, and `ext_resource` in `.tscn` and `project.godot`. Remove the empty old folders.

## 2. Split `ServerManager.gd` (~1000 lines)
`autoload/ServerManager.gd` stays the autoload and RPC entry point (RPC method names and node path unchanged, clients depend on them), but delegates:
- `features/instance/InstanceRegistry.gd`: create/find/free instances, `select_instance`, `format_instance_id`, empty-instance timer, reservations.
- `features/party/PartyService.gd`: create, invite/accept, leave, kick, pending invites, leader rules.
- `features/transfer/TransferService.gd`: route check (`is_route_allowed`), transfer state, ack wait, timeout, disconnect cleanup.
Target: `ServerManager.gd` under ~300 lines. Services are `RefCounted` or plain Nodes owned by `ServerManager`; no new autoloads.

## 3. Shared code into `lib/`
- `lib/constants/GameConst.gd` (`class_name GameConst`): every magic number and name now scattered in scripts: map names, capacities, port, max clients, timeouts, mask channel seconds, move-cancel distance, surrender range and reward ratio, notoriety divisor and cap, collision masks. Scripts reference `GameConst.X`.
- `lib/net/NetUtil.gd` (static): sender validation helpers, `rpc_to_members` / `rpc_to_specific_members` logic (Instance keeps thin wrappers if needed), visibility grant/revoke helpers.
- `lib/utils/` only if a helper is used in 2+ places (rule of two). Do not create empty utils.
- Pure rule functions (`can_attack_roles`, surrender/death outcome, `sell_multiplier`, `select_instance`, `is_route_allowed`) must be static and take plain data, so tests need no scene tree.

## 4. Tests
- `tests/run_tests.gd` (extends SceneTree): finds and runs every `tests/**/test_*.gd`, prints per-file results, then `ALL TESTS PASSED (<n> assertions)` and `quit(0)`, else `quit(1)`.
- Split current assertions into e.g. `tests/features/party/test_party.gd`, `tests/features/instance/test_instance_registry.gd`, `tests/features/player/test_role_rules.gd`, `tests/features/transfer/test_routes.gd`. Same assertion count (60) or more, none removed.
- A tiny shared assert helper may live in `tests/TestCase.gd`.

## 5. Docs
- Update `docs/ARCHITECTURE.md` (English): file paths, the ServerManager split, the test command. Keep everything else.
- Update the test command in `README.md` only if it differs from `res://tests/run_tests.gd`.

## Verification (must pass before finishing)
```
godot_console --headless --path . --import
godot_console --headless --path . -s res://tests/run_tests.gd
```
Also run the headless server + client smoke test you used before (initial Motel spawn, Motel → LootyBay transfer) and report its result.
Final answer: moved-file table, new files, line counts of ServerManager before/after, test output.
