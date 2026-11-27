# Design: Downed (Knock) State

Players do not die at 0 HP. They are **knocked down** first, and while downed their body is a **searchable loot node**.
Reviewed by `egm-design` and `egm-inventive-catalyst`; gameplay decisions confirmed by the owner (2026-11-27).

## 1. State model

`LifeState { ALIVE, DOWNED, DEAD }` is separate from `Role { CITIZEN, CRIMINAL, COP }`.

```
ALIVE --(HP <= 0)--> DOWNED --(bleed-out | finished off | cuffed | disconnect)--> DEAD / ARRESTED
                       |
                       +--(revived)--> ALIVE (low HP)
```

- Only one server function changes life state: `controller.server_set_life_state(new_state, cause)`. It is idempotent (same state = no-op). Nothing else writes it.
- `Player.take_damage()` at 0 HP routes to DOWNED, never straight to death. DOWNED + (bleed-out | finish | disconnect) routes to the existing death path. Cuff routes to the surrender path.
- Replication: `Player.life_state` (setter callback, like `Player.role`) and `Player.downed_deadline_ms` (sent once, not per tick) are added to the `SceneReplicationConfig` in `Player.tscn`.
- `life_state` is not part of `export_state()`; `setup_server()` always starts ALIVE with full HP.
- Any life state change cancels every channel on that player (mask, revive, finish, cuff, search) and closes all search sessions on their body.

## 2. Rules

All numbers live in `GameConst`.

| Rule | Value / behavior |
|---|---|
| Where | `LootyBay` only |
| Bleed-out | `DOWNED_BLEEDOUT_SECONDS = 60`. Each hit taken while downed removes `DOWNED_HIT_PENALTY_SECONDS = 5` from the remaining time |
| Downed player can | crawl at `DOWNED_CRAWL_SPEED`, chat |
| Downed player cannot | attack, interact, mask, cop duty, surrender, map join, enter extraction (see §5) |
| Re-down | downed again within `REDOWN_WINDOW_SECONDS = 30` of a revive → straight to DEAD |
| Disconnect while downed | DEAD (death outcome + LootDrop) before despawn |

## 3. Actions on a downed player

Each is a hold-interact channel using `lib/components/ChannelTimer` (the mask channel moves to it too). Channels cancel when the actor moves out of range, loses LOS, takes damage, disconnects, or the target's life state changes. Server timer that finishes first wins.

| Action | Who | Time | Result |
|---|---|---|---|
| Revive | party member who is ALIVE and same role as the downed player; one reviver at a time | `REVIVE_SECONDS = 5` | ALIVE with `REVIVE_HP_RATIO = 0.25`; keeps items not yet taken |
| Finish off | anyone `can_attack(actor, target)` allows | `FINISH_SECONDS = 2` | DEAD |
| Cuff | COP on a downed CRIMINAL | `CUFF_SECONDS = 3` | Same as surrender: bag cleared, gear kept, cop paid `SURRENDER_COP_REWARD_RATIO` (50%) of bag, criminal → CITIZEN, sent to Motel |
| Search | see §4 | open: `SEARCH_OPEN_SECONDS = 1.5` | Opens the body's item list |

Payout order is deliberate: **cuff (50% of bag) > seizure (25% of bag) > finish (0)**, so cops prefer arrests.

## 4. Body as loot node

### Who may search
Only **CRIMINAL** or **COP**. Citizens can never search.
- CRIMINAL: any downed body (enemy criminal, cop, or own party member to hold items for them).
- COP: downed CRIMINAL only. Taking items = **seizure**: items are destroyed, cop is paid `SEIZURE_COP_REWARD_RATIO = 0.25` of the bag value taken. Seized gear pays nothing.

### Items
- Every item gets a server-assigned `uid` (`{uid, id, value, issued}`). Take requests name a `uid`; the server checks it still exists, removes it, and updates open viewers only (via `lib/net/`). Two searchers can never take the same item.
- `issued: true` items (cop loadout) are not lootable and are not shown. `_saved_civilian_gear` is never exposed.
- Taking loot items calls `grant_loot` for the taker (notoriety rises for the taker, falls for the victim). See §6 for party transfers.
- On DEAD, everything left becomes a `LootDrop` (existing rule).

### Component
- `features/heist/LootContainer.gd` (not `lib/`: it needs role and party rules). Stores items, tracks viewers, handles take-by-uid. Access check and take callback are injected, so the downed body and `LootDrop` share it.
- `Lootable` stays separate (lock/smash value node, not an item list).

## 5. Party and role rules (owner decisions)

- **Party friendly fire is off.** `can_attack` returns false for members of the same party (this also blocks finish-off by teammates).
- **A party cannot mix COP and CRIMINAL.** Mask request is rejected if any party member is COP; cop duty is rejected if any party member is CRIMINAL. Citizens may be in either kind of party. Max party size stays 3.
- Extraction requires ALIVE. On revive inside `ExtractZone`, re-check `get_overlapping_bodies()` (no new `body_entered` fires).

## 6. Outcomes

| Event | CITIZEN | CRIMINAL | COP |
|---|---|---|---|
| DEAD | n/a (cannot be attacked) | LootDrop with what is left, respawn Motel as **CITIZEN**, notoriety reset | issued gear removed, no drop of issued items, off duty, respawn Motel as CITIZEN |
| Cuffed | n/a | surrender outcome (above) | n/a |
| Revived | n/a | ALIVE, stays CRIMINAL | ALIVE, stays COP |

- Notoriety transfer between criminal party members is allowed but cannot be farmed: friendly fire is off, so teammates cannot down each other.
- This changes ARCHITECTURE.md §8.2 (dead criminal used to respawn still CRIMINAL). Update it in the same change.

## 7. Requests blocked while not ALIVE

Server rejects from a non-ALIVE sender: `server_request_attack`, `server_request_mask`, `server_request_cop_duty`, `server_request_surrender`, `server_request_join_map`, `server_request_sell_loot`, party create/invite/accept, and every interact/search/revive/finish/cuff request. `server_request_move` stays allowed (crawl speed).

## 8. Tests (pure, no network)

- State machine: ALIVE→DOWNED at 0 HP, DOWNED→DEAD on bleed-out/finish/disconnect, revive, re-down window, idempotent set.
- Permissions matrix: revive, finish, cuff, search by role × party × life state.
- Payouts: cuff 50% > seizure 25% > finish 0; issued items never lootable.
- Party: no friendly fire; mask rejected with a COP in party; duty rejected with a CRIMINAL in party.
- Concurrency: two takes on one `uid` → second fails.
- Outcomes table in §6.
