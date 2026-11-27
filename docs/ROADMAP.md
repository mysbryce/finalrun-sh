# Roadmap

Status: `[x]` done · `[~]` in progress · `[ ]` planned. Each item ships as one brief → dsh run → review → commit.

## Phase 0: Foundation `[x]`
- [x] Repo, Conventional Commits, `CLAUDE.md`, `dsh-worker` skill
- [x] `docs/CONVENTIONS.md`: folder layout, `lib/`, reuse rules
- [x] README

## Phase 1: Core systems `[x]`
- [x] Server ID `SV-SPACE-XXXX`, instance registry (Motel/LootyBay instanced, House/Center shared)
- [x] Instance isolation: own `World3D` per instance, per-instance spawner, synchronizer visibility, member-only RPC
- [x] Party (max 3), party-aware LootyBay matchmaking, cross-map transfers
- [x] Role state machine: Citizen / Criminal (3 s mask) / Cop
- [x] Surrender (lose bag, keep gear) vs death (drop all), notoriety multiplier
- [x] Lootable: silent lockpick vs loud heist alert
- [x] Headless logic tests, `docs/ARCHITECTURE.md`

## Phase 1.5: Restructure `[x]`
- [x] Move to `features/` + `lib/` layout, split `ServerManager` (registry, party, transfer)
- [x] `lib/constants/GameConst.gd`, `lib/net/` helpers, pure rule functions
- [x] `tests/run_tests.gd` single entry, remove scratch files

## Phase 2: Playable slice `[~]`
- [x] Player controller + camera, client input → server movement, interpolation
- [ ] Health, hitscan weapons (server raycast in instance world), safezone weapon lock
- [x] Downed (knock) state before death: bleed-out, revive, finish off, body as searchable loot node ([design](design/DOWNED_STATE.md))
- [x] Shared `LootContainer` component for downed bodies, `LootDrop`, `Lootable`
- [x] Fix: criminal death respawns as Citizen
- [ ] Interact system (`lib/components/InteractArea`), basic HUD (role, mask timer, bag value)
- [ ] Base character: CC0 low-poly modular humanoid + animations, male/female on one skeleton ([art direction](design/ART_DIRECTION.md))
- [ ] Appearance foundation: `AppearanceData` Resource (body type, slot → item id), synced once on spawn, modular character rig with swappable slots. Built now so later cosmetics are data only, no code changes.
- [ ] Local 1 server + 3 clients smoke test script

## Phase 3: Heist loop `[ ]`
Adopted from [genre reference](research/GENRE_REFERENCE.md) (owner decision 2026-11-27).
- [ ] Items and loot tables as Resources (`lib/data/`, `data/*.tres`)
- [ ] **Bag capacity + bag tiers**: loot has size/weight, bag tier sets capacity, bigger bags bought in Center
- [ ] **Multi-step heists**: alarm box to disable (some cannot be), clerk NPC held at gunpoint or calls police, cameras to break, loot, escape
- [ ] **Key chains**: tiered keys; a low key opens a room holding a higher key, chaining to the best loot
- [ ] Lockpick and smash interactions, big heist objective with timer
- [ ] Extraction zone flow, loot drop pickup
- [ ] **Fence points** inside LootyBay: sell at a bonus, PvP hotspot (Center stays the safe, normal-price market)
- [ ] PvE guards (simple AI)

## Phase 4: Cops `[ ]`
- [ ] Police station duty, free loadout and vehicle
- [ ] **Cop slot cap** per LootyBay instance
- [ ] Surrender prompt and arrest flow, seizure rewards
- [ ] Heist alert UI and map markers

## Phase 5: Economy and housing `[ ]`
- [ ] Motel cash stash
- [ ] **Solo bonus**: solo players start with higher notoriety (better loot quality and sell price) to balance vs parties of 3
- [ ] Center market: sell with notoriety multiplier, upgrades, player trading
- [ ] House plots, storage, laundering desk (dirty → clean cash)
- [ ] **Raidable houses**: breach consumable vs house security level. Open design question: House is a no-combat zone today, so decide how raids work (raid window, combat allowed only inside a breached house, owner offline rules) in a design doc first.

## Phase 6: Customization and skins `[ ]`
All cosmetics are `CosmeticData` Resources (`id`, `slot`, `mesh/material`, `rarity`). Pure visual: no stat changes.
- [ ] Character creator: body type (male / female), skin tone, face, hair style and color
- [ ] Clothing slots: top, bottom, shoes, hat, glasses, accessories
- [ ] Mask skins (shown only while Criminal; masked players hide name tags)
- [ ] Vehicle skins: paint, wraps, rims (cop vehicles keep fixed police livery)
- [ ] Loot bag skins
- [ ] Weapon skins
- [ ] Wardrobe at Motel and House, cosmetic shop in Center
- [ ] Owned cosmetics inventory (persisted in Phase 7)

## Phase 7: Persistence and scale `[ ]`
- [ ] Player save data (DB), auth
- [ ] Multiple big servers, server browser / matchmaker
- [ ] Linux dedicated server export, Docker deploy
- [ ] Server wipe cycle with carry-over meta progression (cycle length decided here)

## Phase 8: Polish `[ ]`
- [ ] Art, audio, VFX
- [ ] Server-side anti-cheat checks (speed, fire rate, range)
- [ ] Performance pass, network bandwidth budget
