# Design: Downed (Knock) State

Players do not die at 0 HP. They are **knocked down** first, and while downed their body is a **loot node** other players can search.

## State flow

```
ALIVE --(HP <= 0)--> DOWNED --(bleed-out timer ends | finished off | disconnect)--> DEAD
                       |
                       +--(revived by party member)--> ALIVE (low HP)
```

## Rules (defaults, tune in GameConst)

| Rule | Default |
|---|---|
| Where | `LootyBay` only (other maps have no combat) |
| Bleed-out timer | 60 s (`DOWNED_BLEEDOUT_SECONDS`) |
| Downed player can | crawl slowly, talk; cannot shoot, interact, or take the mask off |
| Revive | party member holds interact 5 s (`REVIVE_SECONDS`), returns with 25% HP; cancelled if reviver takes damage |
| Finish off | any player allowed to attack the downed player (`can_attack`) holds interact 2 s → immediate DEAD |
| Disconnect while downed | counts as DEAD (no combat logging) |
| Damage while downed | speeds up bleed-out, does not skip it |

## Body as loot node

- While DOWNED the player exposes a `LootContainer` component (shared with `LootDrop` and `Lootable`, lives in `lib/components/`).
- Who can search: anyone `can_attack(looter, downed)` allows, plus party members (to hold items for a teammate).
- Searching: hold interact to open, take items one by one from `loot_bag` and `equipped_gear`. Server validates range, LOS, and that the target is still DOWNED.
- **Cop searching a downed Criminal = seizure**: seized value pays the cop (same ratio as surrender) and items are removed, not transferred.
- On DEAD: whatever is left becomes a `LootDrop` at the body position (existing death rule).
- Revived players keep only what was not taken.

## Role outcome

- CRIMINAL → DEAD: respawn at Motel as **CITIZEN** (run is over). Fixes the current bug where a dead criminal respawns still masked.
- COP → DEAD: off duty, respawn CITIZEN (current rule).
- CITIZEN: cannot be attacked by players, so normally never downed.

## Implementation notes

- `PlayerRoleController` gets a separate life state: `enum LifeState { ALIVE, DOWNED, DEAD }`, independent from `Role`. Synced via the player synchronizer.
- Pure rule functions (who can revive / search / finish, outcome on death) stay static and testable without a network.
- One `LootContainer` component serves downed bodies, `LootDrop`, and `Lootable` (reuse rule of two).
