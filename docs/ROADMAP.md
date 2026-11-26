# Roadmap

Status: `[x]` done · `[~]` in progress · `[ ]` planned. Each item ships as one brief → dsh run → review → commit.

## Phase 0: Foundation `[x]`
- [x] Repo, Conventional Commits, `CLAUDE.md`, `dsh-worker` skill
- [x] `docs/CONVENTIONS.md`: folder layout, `lib/`, reuse rules
- [x] README

## Phase 1: Core systems `[~]`
- [~] Server ID `SV-SPACE-XXXX`, instance registry (Motel/LootyBay instanced, House/Center shared)
- [~] Instance isolation: own `World3D` per instance, per-instance spawner, synchronizer visibility, member-only RPC
- [~] Party (max 3), party-aware LootyBay matchmaking, cross-map transfers
- [~] Role state machine: Citizen / Criminal (3 s mask) / Cop
- [~] Surrender (lose bag, keep gear) vs death (drop all), notoriety multiplier
- [~] Lootable: silent lockpick vs loud heist alert
- [~] Headless logic tests, `docs/ARCHITECTURE.md`

## Phase 1.5: Restructure `[ ]`
- [ ] Move to `features/` + `lib/` layout, split `ServerManager` (registry, party, transfer)
- [ ] `lib/constants/GameConst.gd`, `lib/net/` helpers, pure rule functions
- [ ] `tests/run_tests.gd` single entry, remove scratch files

## Phase 2: Playable slice `[ ]`
- [ ] Player controller + camera, client input → server movement, interpolation
- [ ] Health, hitscan weapons (server raycast in instance world), safezone weapon lock
- [ ] Interact system (`lib/components/InteractArea`), basic HUD (role, mask timer, bag value)
- [ ] Local 1 server + 3 clients smoke test script

## Phase 3: Heist loop `[ ]`
- [ ] Items and loot tables as Resources (`lib/data/`, `data/*.tres`)
- [ ] Lockpick and smash interactions, big heist objective with timer
- [ ] Extraction zone flow, loot drop pickup
- [ ] PvE guards (simple AI)

## Phase 4: Cops `[ ]`
- [ ] Police station duty, free loadout and vehicle
- [ ] Surrender prompt and arrest flow, seizure rewards
- [ ] Heist alert UI and map markers

## Phase 5: Economy and housing `[ ]`
- [ ] Motel cash stash
- [ ] Center market: sell with notoriety multiplier, upgrades, player trading
- [ ] House plots, storage, laundering desk (dirty → clean cash)

## Phase 6: Persistence and scale `[ ]`
- [ ] Player save data (DB), auth
- [ ] Multiple big servers, server browser / matchmaker
- [ ] Linux dedicated server export, Docker deploy

## Phase 7: Polish `[ ]`
- [ ] Art, audio, VFX
- [ ] Server-side anti-cheat checks (speed, fire rate, range)
- [ ] Performance pass, network bandwidth budget
