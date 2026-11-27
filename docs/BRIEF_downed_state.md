# Brief: Downed (Knock) State (Phase 2)

Implement `docs/design/DOWNED_STATE.md` exactly. That doc is the spec; this brief says where the code goes.
Read first: `docs/CONVENTIONS.md`, `docs/ARCHITECTURE.md`, `docs/design/DOWNED_STATE.md`.

## 1. Constants (`lib/constants/GameConst.gd`)
Add every number from the design doc: `DOWNED_BLEEDOUT_SECONDS`, `DOWNED_HIT_PENALTY_SECONDS`, `DOWNED_CRAWL_SPEED` (1.2), `REDOWN_WINDOW_SECONDS`, `REVIVE_SECONDS`, `REVIVE_HP_RATIO`, `FINISH_SECONDS`, `CUFF_SECONDS`, `SEARCH_OPEN_SECONDS`, `SEIZURE_COP_REWARD_RATIO`, `INTERACT_RANGE` (2.5). No literals for these anywhere else.

## 2. Life state (`features/player/`)
- `PlayerRoleController`: `enum LifeState { ALIVE, DOWNED, DEAD }` and the single entry `server_set_life_state(new_state: int, cause: String) -> void` (idempotent). It cancels all channels on this player and closes search sessions on its body (signal `life_state_changed(old, new, cause)`; other services listen).
- `Player.gd`: add replicated `life_state` (setter callback like `role`) and `downed_deadline_ms`. Add both to the `SceneReplicationConfig` in `Player.tscn`. `take_damage` at 0 HP → DOWNED (not death). Damage while DOWNED applies the bleed-out penalty. Server physics uses `DOWNED_CRAWL_SPEED` while DOWNED.
- `server_request_move` becomes `@rpc("any_peer", "call_remote", "unreliable")`.
- `setup_server` starts ALIVE with full HP; `life_state` is not in `export_state`.
- Re-down window: track last revive time; DOWNED within `REDOWN_WINDOW_SECONDS` → DEAD.

## 3. Channel component (`lib/components/ChannelTimer.gd`)
Generic, no feature imports: `start(duration, actor_node, max_move, cancel_check: Callable)`, signals `completed`, `cancelled(reason)`. Cancels on actor move > `max_move`, on `cancel_check()` returning a reason, or `cancel(reason)`. Move the existing mask channel in `PlayerRoleController` onto it (behavior unchanged, existing mask tests must pass).

## 4. Downed actions (`features/downed/DownedService.gd`, owned by `ServerManager` like the other services)
- New RPCs on `ServerManager` (thin, delegate to `DownedService`): `server_request_revive(target_peer_id)`, `server_request_finish(target_peer_id)`, `server_request_cuff(target_peer_id)`, `server_request_search_open(target_peer_id)`, `server_request_search_take(target_peer_id, item_uid)`, `server_request_search_close(target_peer_id)`. Matching client helpers `request_*`.
- Every request: validate sender, same instance, both ALIVE/DOWNED as the spec requires, range `INTERACT_RANGE`, LOS (reuse the existing LOS helper; move it to a shared place if a second caller needs it).
- Permissions and payouts as **pure static functions** (testable): `can_revive`, `can_finish`, `can_cuff`, `can_search`, `seizure_reward`. Follow spec §3-§5 exactly (revive: same party + same role, one reviver; search: CRIMINAL any body, COP only CRIMINAL bodies, never CITIZEN).
- Bleed-out timer per downed player on the server; expiry → DEAD.
- Cuff → reuse the surrender outcome path (`surrender_outcome` / `server_apply_surrender`), sending the criminal to Motel as CITIZEN.
- DEAD → existing death path (`handle_player_death`), with spec §6 changes: dead CRIMINAL respawns as CITIZEN; COP issued items are removed and never dropped.
- Disconnect while DOWNED (`PlayerService.handle_peer_left`) → DEAD outcome + LootDrop before despawn.
- Extraction (`PlayerService._handle_extraction` / zone enter) requires ALIVE; on revive, re-check `ExtractZone` overlapping bodies.
- Reject every request listed in spec §7 from non-ALIVE senders (add the check where each request is handled).

## 5. Items and LootContainer
- Items become `{uid, id, value, issued}`. Server assigns `uid` (unique per server run) in `grant_loot`/`grant_gear`/loadout. Extend `lib/utils/ItemUtils.gd` (e.g. `make_item`, `find_by_uid`, `remove_by_uid`, `lootable_only`). Old saved states without `uid` get one assigned on `apply_state`.
- COP loadout items have `issued: true`. Issued items are never shown in a search or dropped.
- `features/heist/LootContainer.gd`: item list + viewers + take-by-uid, with injected `can_access: Callable` and `on_take: Callable`. Used by the downed body and by `LootDrop` (refactor `LootDrop` to use it). `Lootable` stays as is.
- Search contents go only to the viewer (`rpc_id` via `lib/net/NetUtil`), and updates go only to open viewers. Taking: CRIMINAL → item moves to taker via `grant_loot`/`grant_gear`; COP → seizure (item destroyed, cop paid `seizure_reward`).

## 6. Party rules (`features/party/`, `features/player/`)
- `can_attack_roles` gains a `same_party: bool` input → false when true. `can_attack` passes it.
- Mask request rejected if any party member is COP; cop duty rejected if any party member is CRIMINAL. Pure static check `party_role_conflict(member_roles: Array, requested_role) -> bool`.

## 7. Client test controls (`main/Main.gd`, temporary)
Target = nearest other player in the instance. `R` revive, `X` finish, `C` cuff, `E` open search (print contents), `T` take first lootable item, `Q` close search. Show own life state and bleed-out seconds in the existing debug label.

## 8. Tests (add under `tests/`, mirror source; keep all 107 existing assertions)
Cover every bullet in spec §8: state machine, permission matrix (role × party × life state), payout ordering (cuff 50% > seizure 25% > finish 0), issued items never lootable, party FF off, party role conflict, double-take of one uid fails, outcomes table, ChannelTimer cancel reasons.

## 9. Docs
Update `docs/ARCHITECTURE.md` (English): new life state, DownedService, RPC list, §8.2 death table (criminal → CITIZEN), item format. Do not edit the design doc.

## Verification (must pass)
```
godot_console --headless --path . --import
godot_console --headless --path . -s res://tests/run_tests.gd
```
Plus a headless server + 2 clients smoke test (driver under `logs/`, delete after): clients A and B, not in a party, both join LootyBay and both mask up (CRIMINAL). B gets one loot item. A attacks B until DOWNED, A opens search on B, takes the item, then finishes B → B is DEAD, a LootDrop exists, B respawns in Motel as CITIZEN. Report the output.
Final answer: files changed/created, new RPC list, test summary, smoke output, any spec point you could not implement.
