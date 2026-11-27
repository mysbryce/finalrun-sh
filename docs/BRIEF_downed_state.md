# Brief: Downed (Knock) State (Phase 2)

Implement `docs/design/DOWNED_STATE.md`. That doc is the gameplay spec; this brief fixes where code goes and resolves every open detail. If the two disagree, **this brief wins**.
Read first: `docs/CONVENTIONS.md`, `docs/ARCHITECTURE.md`, `docs/design/DOWNED_STATE.md`.
Revised after `egm-implementation-readiness` and `egm-codebase-details` reviews.

**Implement in this order:** §1, §2 (bug fixes), §3, §5, §4, §6, §7, §8, §9, §10, §11.

## 1. Constants (`lib/constants/GameConst.gd`)
Add: `DOWNED_BLEEDOUT_SECONDS = 60.0`, `DOWNED_HIT_PENALTY_SECONDS = 5.0`, `DOWNED_CRAWL_SPEED = 1.2`, `REDOWN_WINDOW_SECONDS = 30.0`, `REVIVE_SECONDS = 5.0`, `REVIVE_HP_RATIO = 0.25`, `FINISH_SECONDS = 2.0`, `CUFF_SECONDS = 3.0`, `SEARCH_OPEN_SECONDS = 1.5`, `SEIZURE_COP_REWARD_RATIO = 0.25`, `INTERACT_RANGE = 2.5`, `DOWNED_CHANNEL_MAX_MOVE = 0.75`. No literals for these anywhere else.

## 2. Existing bugs to fix first
- `features/player/PlayerRoleController.gd:138` calls `target.has_node_or_null(...)` (not a Node method) → use `get_node_or_null`. Add a test that calls `can_attack` with a real `PlayerCharacter`-shaped node, not only controllers.
- `Player.gd` client input: today input is sent only on change (`Player.gd:142-145`). When §3 makes the RPC unreliable, resend current input every `PLAYER_INPUT_SEND_INTERVAL` while non-zero, plus one zero vector when it stops.

## 3. Life state (`features/player/`)
- `PlayerRoleController`: `enum LifeState { ALIVE, DOWNED, DEAD }`, signal `life_state_changed(old, new, cause)`, and the single writer `server_set_life_state(new_state: int, cause: String, now_ms: int) -> void` (idempotent). Allowed causes: `damage`, `bleedout`, `finish`, `disconnect`, `redown`, `revive`, `cuff`, `respawn`.
- `Player.gd`: replicated `life_state` (setter callback like `role`) and `downed_deadline_ms`. Add both to the `SceneReplicationConfig` in `Player.tscn` with `REPLICATION_MODE_ON_CHANGE`.
- Clock: all server time comparisons take `now_ms: int` as a parameter. Source = `int(Time.get_unix_time_from_system() * 1000.0)`. Client shows bleed-out seconds as `max(0, downed_deadline_ms - client_unix_ms) / 1000`.
- `Player.take_damage` (`Player.gd:94-103`): remove the direct `handle_player_death` call. In `LootyBay`: ALIVE at 0 HP → DOWNED (`damage`), unless the last revive was within `REDOWN_WINDOW_SECONDS` → DEAD (`redown`). DOWNED + damage → HP stays 0, deadline moves `DOWNED_HIT_PENALTY_SECONDS` earlier; if deadline <= now → DEAD (`bleedout`). Outside `LootyBay` 0 HP goes straight to the death path.
- `server_request_move` (in `Player.gd`) becomes `@rpc("any_peer", "call_remote", "unreliable")`. Server physics uses `DOWNED_CRAWL_SPEED` while DOWNED, zero while DEAD.
- `setup_server` starts ALIVE with full HP. `life_state` is not in `PlayerRoleController.export_state`.

## 4. Channel component (`lib/components/ChannelTimer.gd`)
- A `Node` (no feature imports) parented under the actor's player node. `start(duration: float, actor: Node3D, max_move: float, cancel_check: Callable)`. `cancel_check()` returns `""` to continue or a reason string. Signals `completed`, `cancelled(reason: String)`. `cancel(reason)` public.
- Reason strings exactly: `moved`, `out_of_range`, `no_los`, `damaged`, `disconnected`, `target_state`, `actor_state`, `left_instance`, `invalid_state`.
- Move the mask channel (`_mask_timer` / `MaskChannelTimer`, `_process` move/map check, `notify_damage`) onto ChannelTimer. Keep signals `mask_channel_started` / `mask_channel_cancelled` and reasons `moved`, `damaged`, `left_instance`, `invalid_state`. There are no mask tests today: add them.
- On `completed`, the owner must re-check permission and target state before applying (first finished timer wins; later ones fail the re-check).

## 5. Items
- Item format `{uid: int, id: String, value: int, issued: bool, source: "bag"|"gear"}` (`source` is set when listed for search, not stored).
- uid counter `_next_item_uid` lives in `PlayerService` (stateful). `lib/utils/ItemUtils.gd` stays stateless: `make_item(uid, id, value, issued := false)`, `find_by_uid`, `remove_by_uid`, `lootable_only(items)` (drops `issued`). Assign uids to items missing one in `apply_state` (transfer snapshots).
- `PlayerRoleController`: add `receive_item(item: Dictionary, source: String)` (keeps the uid) and `remove_item_by_uid(uid: int) -> Dictionary` (also lowers this player's notoriety by the item value, clamped at 0). Keep `grant_loot` / `grant_gear` as wrappers that build an item via `ItemUtils.make_item` with a uid from `PlayerService`. Update callers: `Lootable.gd:55`, tests in `tests/features/player/test_role_outcomes.gd`.
- Cop loadout: `COP_LOADOUT` (`PlayerRoleController.gd:22-26`) and `server_go_on_duty` mark items `issued: true` with uids. Update `test_cop_death_goes_off_duty` setup so the cop pistol is `issued`.

## 6. Line of sight
Move `PlayerService._has_line_of_sight(instance, from, target)` (`PlayerService.gd:356`) to a public static `PlayerService.has_line_of_sight(...)`. Existing callers (lines ~203, ~348) and the new downed actions all use it.

## 7. Downed actions (`features/downed/DownedService.gd`)
- `RefCounted`, owned by `ServerManager` like the other services. It owns no Nodes: channels are `ChannelTimer` nodes under the actor's player; bleed-out is checked in `DownedService.tick(now_ms)` called from `ServerManager._process`.
- RPCs on `ServerManager` (thin, delegate): `server_request_revive(target_peer_id)`, `server_request_finish(target_peer_id)`, `server_request_cuff(target_peer_id)`, `server_request_search_open(target_peer_id)`, `server_request_search_take(target_peer_id, item_uid)`, `server_request_search_close(target_peer_id)`. Client-side: `client_search_contents(target_peer_id, items: Array)`, `client_search_closed(target_peer_id, reason: String)`. Matching `request_*` helpers. Use `NetUtil.rpc_to_peer`.
- Non-ALIVE sender gate: add `_can_accept_alive_request(sender)` next to `_can_accept_request` in `ServerManager` and use it for every request in spec §7. The downed actions use their own checks (actor must be ALIVE, target must be DOWNED).
- Pure static rules on `DownedService` (exact signatures):
  - `can_revive(actor_role, actor_life, target_role, target_life, same_party: bool, has_active_reviver: bool) -> bool` (same party, same role, actor ALIVE, target DOWNED, no other reviver)
  - `can_finish(attack_allowed: bool, actor_life, target_life) -> bool`
  - `can_cuff(actor_role, actor_life, target_role, target_life) -> bool` (COP on CRIMINAL)
  - `can_search(actor_role, actor_life, target_role, target_life) -> bool` (actor CRIMINAL: any downed body; actor COP: CRIMINAL body only; CITIZEN actor: never)
  - `seizure_reward(item: Dictionary, source: String) -> int` = `floori(value * SEIZURE_COP_REWARD_RATIO)` for `bag`, `0` for `gear`
- Every request and every take re-checks: same instance, `INTERACT_RANGE`, LOS, permission. A search session closes (`client_search_closed`) when any of those fail, when either side's life state changes, or on disconnect.
- Search list = `lootable_only(loot_bag)` tagged `bag` + `lootable_only(equipped_gear)` tagged `gear`. Contents go only to the viewer; updates only to open viewers.
- Take: CRIMINAL → `remove_item_by_uid` on victim, `receive_item` on taker (same uid; taker gains notoriety for bag items via the normal rule). COP → seizure: item removed and destroyed, cop `cash += seizure_reward`.
- Cuff: call `server_apply_surrender(cop)` on the criminal with the cuffing cop (do NOT call `PlayerService.surrender`, it searches for a cop itself), then `transfer_to_motel` and `_refresh_police_vehicle`. The cuffed player never becomes DEAD and gets no LootDrop; `setup_server` resets them to ALIVE.
- Finish / bleed-out / disconnect → DEAD.

## 8. Death path (`features/player/PlayerService.gd`, `PlayerRoleController.gd`)
- Extract `PlayerService.gd:248-260` into `_resolve_death(player, instance)`: apply death outcome and spawn the LootDrop, no transfer. `handle_player_death` = `_resolve_death` + transfer to Motel. `handle_peer_left` calls `_resolve_death` **before** `detach_peer` when the player is DOWNED.
- Order on DEAD: cancel channels where the player is actor or target → close search sessions (body or viewer) → LootDrop → despawn (`call_deferred`) → transfer. Never despawn inside a `life_state_changed` handler.
- `death_outcome` / `server_apply_death` (`PlayerRoleController.gd:293-342`): dead CRIMINAL → role CITIZEN. Dead COP → issued items removed (never dropped), non-issued items drop like anyone else's, off duty, CITIZEN. Keep `_saved_civilian_gear` restore. Update the doc comment.
- LootDrop is created even if empty only when the body had items; if nothing is left, no drop.

## 9. LootContainer (`features/heist/LootContainer.gd`)
- Items + viewers + take-by-uid, with injected `can_access: Callable` and `on_take: Callable`. Used by the downed-body search and by `LootDrop`.
- `LootDrop`: keep its current pickup behavior through `can_access` / `on_take`; no new RPC. Stop sending full item lists to every member: `Instance.spawn_loot_drop`, `sync_state_to_peer`, `client_add_loot_drop` mirror only position + placeholder. Call `client_remove_loot_drop` when a drop is emptied.

## 10. Party rules and extraction
- `can_attack_roles(..., same_party: bool = false)` (appended, default keeps existing tests valid) → false when `same_party`. `PlayerService.attack` computes `same_party` via `_parties.get_party(peer_id)` and `has_member(target)`, and passes it to `can_attack(target, same_party)`.
- Pure static `party_role_conflict(member_roles: Array, requested_role: int) -> bool`. Mask is rejected if any party member is COP; cop duty is rejected if any is CRIMINAL.
- Extraction: ALIVE check inside `PlayerService._handle_extraction` (it runs deferred). Add `GameInstance.get_zone(name) -> Area3D`; after a revive, if the player overlaps `ExtractZone`, run extraction.

## 11. Client test controls (`main/Main.gd`)
Update the controls `print` line. Target = nearest other player. `R` revive, `X` finish, `C` cuff, `E` open search (print contents), `T` take first item, `Q` close search, `K` attack target (calls `request_attack`). Print own life state and bleed-out seconds when they change.

## 12. Tests (mirror source; keep all existing assertions)
Spec §8 list, plus: `can_attack` with real node shape (§2), mask channel cancel reasons, ChannelTimer reasons, `same_party` default, item uid kept on transfer, victim notoriety lowered, seizure gear = 0, cuff never creates LootDrop, dead COP drops no issued item, redown → DEAD, deadline penalty math with injected `now_ms`.

## 13. Docs
Update `docs/ARCHITECTURE.md` (English): life state, DownedService, ChannelTimer, RPC list, item format, death table §8.2 (dead CRIMINAL → CITIZEN; COP drops non-issued items), LootDrop privacy. Fix the `handle_peer_left` owner (PlayerService). Do not edit the design doc.

## Verification (must pass)
```
godot_console --headless --path . --import
godot_console --headless --path . -s res://tests/run_tests.gd
```
Smoke test: headless server + 2 clients, driver under `logs/` (delete after). The driver may call a **server-side test hook** (behind a `--smoke` cmdline flag only) to grant B one bag item and one gear item and to teleport A next to B. Steps: A and B (no party) join LootyBay, both mask (CRIMINAL); A attacks B until DOWNED; A opens search, takes the bag item; A finishes B. Driver prints exactly: `DOWNED`, `SEARCH_TAKE ok`, `DEAD`, `LOOTDROP`, `RESPAWN Motel CITIZEN`.
Final answer: files changed/created, RPC list, test summary, smoke output, anything not implemented.
