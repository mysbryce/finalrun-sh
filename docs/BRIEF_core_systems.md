# Brief: Core Systems (Phase 1) — Godot 4.7 GDScript

You are the implementer. Work ONLY inside `d:\FinalRun`. Godot is installed: `godot_console` (4.7.2 mono, use GDScript only).
Write clean, typed GDScript (`var x: int`, typed signals/returns). Code comments in English. No placeholder TODO stubs for anything listed below.

## Game summary (original game, our own names/assets)
3D multiplayer extraction crime sandbox. One Godot dedicated server process = one "big server" with ID `SV-SPACE-XXXX` (4 random digits).
Inside it there are 4 maps:
| Map | Kind | Notes |
|---|---|---|
| Motel | instanced, sub-sessions `Motel-01`, `Motel-02`... | safezone: no weapons. Cash stash. Party create (max 3). Cap 16 players/instance |
| LootyBay | instanced, `LootyBay-01`... | PvPvE heist zone. Party must land in SAME instance -> pick instance with free slots >= party size, else create new. Cap 12 |
| House | shared, single instance `House` | everyone in the big server sees each other. Housing, storage, laundering desk |
| Center | shared, single instance `Center` | market, sell loot, trade, upgrade |

## Mandatory architecture (do not change)
- Server authoritative. ENet `ENetMultiplayerPeer`. Clients never decide role, damage, loot, or transfers; they only send *requests* via `@rpc("any_peer", "call_remote", "reliable")` and the server validates `multiplayer.get_remote_sender_id()`.
- **Instance isolation (the key requirement):**
  1. Every instance root is a `SubViewport` with `own_world_3d = true` at path `/root/Main/Instances/<instance_id>`. Separate World3D = separate physics space, so raycasts/bullets can never cross instances. On the server do NOT set `disable_3d = true` (physics needs the world) — set `render_target_update_mode = UPDATE_DISABLED` instead. On the client, the client only holds its current instance, wrapped in a `SubViewportContainer` (stretch = true, full rect) so the same node path exists on both sides.
  2. Each instance has its own `MultiplayerSpawner` (spawn_path = its `Players` node, players spawned with a custom `spawn_function`).
  3. Every player scene's root `MultiplayerSynchronizer` uses `public_visibility = false`; visibility is granted with `set_visibility_for(peer_id, true)` ONLY for peers in the same instance (update on join/leave of instance). Godot only replicates spawns/sync to peers that can see the synchronizer — this hides players of other sub-sessions.
  4. Never use broadcast `rpc()` for gameplay events from the server. Use helper `Instance.rpc_to_members(callable_name, args)` that loops `rpc_id` over that instance's member peers only.
  5. Server rejects any client gameplay request whose sender is not a member of the instance that owns the target node (e.g. trying to hit a player in another room).
- Hit detection: server does the raycast in the shooter's instance World3D (`get_world_3d().direct_space_state`).

## Deliverables
1. `project.godot` (Godot 4.7, Forward+ ok), autoloads: `ServerManager`.
2. Folder structure:
```
res://
  autoload/ServerManager.gd
  core/Instance.gd            # script on each instance SubViewport: members, capacity, kind, safezone flag, rpc_to_members, visibility updates
  core/Party.gd               # RefCounted: id, leader, members (max 3)
  player/Player.tscn          # CharacterBody3D + MultiplayerSynchronizer + PlayerRoleController node
  player/Player.gd            # minimal movement (client input -> server), enough to test
  player/PlayerRoleController.gd
  world/Lootable.gd           # minimal: value, lockpick (silent) vs smash (loud alert)
  world/LootDrop.gd           # dropped bag/gear container on death
  maps/Motel.tscn, LootyBay.tscn, House.tscn, Center.tscn   # placeholder floor + spawn points + zone Area3Ds (ExtractZone in LootyBay, PoliceStation area in LootyBay)
  main/Main.tscn + Main.gd    # boots as server with `--server` cmdline arg (port 7777) else client connecting to 127.0.0.1
  tests/test_core.gd          # headless self-check: `godot_console --headless -s res://tests/test_core.gd`
docs/ARCHITECTURE.md          # scene tree diagram (server + client), sync/isolation rules, transfer flow (in English)
```
3. `ServerManager.gd` (autoload):
   - `server_id` = `"SV-SPACE-%04d" % randi_range(0, 9999)` generated at server start.
   - Instance registry: create/destroy instances on demand, naming `Motel-01`, `LootyBay-03`. Shared House/Center created at start. Empty non-shared instances are freed after 60 s.
   - Party: create, invite/accept, leave, kick, leader transfer on leave. Max 3. Party lives only while members are in Motel/House/Center/LootyBay of this server.
   - `request_join_map(map_name)` from client: if in party, only leader can trigger for LootyBay; whole party moves together; find instance with `capacity - members >= party_size` (prefer fullest that still fits, to fill rooms), else create.
   - Transfer: server despawns player from old instance, revokes visibility both ways, rpc_id client `client_load_instance(instance_id, map_name)`, waits for client `client_instance_ready()` ack, then spawns player at spawn point and grants visibility with all members. Handle disconnect at any step.
   - Allowed routes: Motel <-> LootyBay, Motel <-> House, Motel <-> Center, House <-> Center. LootyBay exit only through ExtractZone (sets role back via controller) or death/surrender (goes to Motel).
4. `PlayerRoleController.gd` (Node child of Player, server authoritative, role synced via the synchronizer):
   - `enum Role { CITIZEN, CRIMINAL, COP }`, signal `role_changed(old, new)`.
   - Mask: request -> 3.0 s channel (server Timer), cancelled if player moves > 0.5 m, takes damage, or leaves LootyBay. Only in LootyBay, only from CITIZEN. Becomes CRIMINAL.
   - CRIMINAL -> CITIZEN only via successful extraction from LootyBay (called by ServerManager on ExtractZone exit). Mask cannot be removed manually.
   - COP: go on duty only inside PoliceStation area in LootyBay, only as CITIZEN; grants cop loadout + spawns a police vehicle placeholder. Off duty at station.
   - `can_attack(target) -> bool`: false in safezone (Motel) and in House/Center; CITIZEN never; CRIMINAL can attack CRIMINAL and COP; COP can attack only CRIMINAL.
   - Inventory model: `loot_bag: Array[Dictionary]` (`{id, value}`) and `equipped_gear: Array[Dictionary]`.
   - Notoriety: `notoriety` += looted value this run; `sell_multiplier() = 1.0 + min(notoriety / 10000.0, 1.5)`; reset on death/surrender/extraction-sale as you see fit but document it.
   - Surrender: CRIMINAL requests; server requires a COP within 6 m with line of sight in the same instance. Cop receives loot_bag value as reward (fixed % e.g. 50%), loot_bag cleared, equipped_gear KEPT, role -> CITIZEN, sent to Motel.
   - Death: CITIZEN dies -> keeps everything, respawn Motel. CRIMINAL dies -> spawn `LootDrop` at death position containing loot_bag + equipped_gear, both cleared, respawn Motel. COP dies -> drops nothing (gear is free issue), off duty.
5. Lootable: lockpick = silent; smash/big heist = server alerts (`rpc_to_members`) only to COP and CRIMINAL members of that instance, with position.
6. `tests/test_core.gd` (extends SceneTree, no network needed): asserts for: server id format, party max 3, instance pick puts a 3-party into an instance with >= 3 free slots and creates new when none fits, `can_attack` matrix, surrender keeps gear/clears bag, criminal death drops all, citizen death drops nothing. Print `ALL TESTS PASSED` and `quit(0)`, else `quit(1)`.
   Design the logic so it is testable without a live network (pure functions / methods that take data).

## Verification you must run before finishing
- `godot_console --headless --path d:\FinalRun --import` (or `--editor --quit`) must show no script parse errors.
- `godot_console --headless --path d:\FinalRun -s res://tests/test_core.gd` must print `ALL TESTS PASSED`.
Fix until both pass. In your final answer list files created and paste the test output.
