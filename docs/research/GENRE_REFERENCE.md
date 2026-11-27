# Genre Reference: Crime Extraction Sandbox

Notes from a public beginner guide for a released game in the same genre (note.com article, Nov 2026, summarizing a streamer's video; figures are unofficial).
Purpose: learn which **mechanics** make the genre work. We do not copy names, characters, art, maps, or text. Everything we build uses our own names and assets.

## What the reference game does

| Area | Mechanic | Numbers (unofficial) |
|---|---|---|
| Session | Servers wipe on a fixed cycle; some progress carries over (meta rank) | 7-day cycle |
| World | City split into tiers by distance from center; better gear, cars, loot in higher tiers | Tier 1 → Tier 2 at ~1,000,000 |
| Onboarding | Quest-giver NPC at the starting motel teaches controls; a large debt as long-term goal | debt 1,000,000 |
| Roles | Police or gang. Police have limited slots, fight without risking own gear, earn points per arrest | slots limited |
| Heists | Store robbery steps: find alarm box at back, disable it (some can't be), enter back door, aim at clerk so they can't call police, break cameras, loot, leave | |
| Keys | Tiered keys: low key opens room with higher key, chain to best loot | |
| Selling | Loot cashed in at fixed cash-in points inside the dangerous world (ambush hotspots, open vs underground) | |
| Carry | Bags increase carry capacity; capacity limits trips | |
| Notoriety | Higher level = better loot quality and sell price. Solo starts higher than parties | solo Lv4 vs party Lv1; solo ~+30% sell, ~+15% loot quality |
| Items | "Progress" item: carried during crimes it charges up, then sells for a multiple of its cost | ~3x |
| Housing | Buy plots (max per sector), storage base, landlords earn rent; bases are raidable with a consumable breach item vs security level | 10 houses/sector, house ~150,000 |
| Vehicles | Capacity cars (slow, carry more) vs speed cars (escape); upgrade parts matter | |
| Punishment | Jail time tied to activity at cycle end | |

## Gap analysis vs FinalRun today

| Mechanic | FinalRun now | Gap |
|---|---|---|
| Carry capacity / bag tiers | none (bag unlimited) | **Missing, core to risk/reward** |
| Multi-step heists (alarm, clerk, cameras) | lockpick vs smash only | Shallow |
| Tiered keys / locked rooms | none | Missing |
| Solo vs party balance | none | Missing (parties of 3 dominate) |
| Police slot cap | none | Missing, easy |
| Sell location risk | sell at Center (shared, no combat) | Design choice: safe sell vs risky cash-in |
| Raidable bases | House is a safe shared map | Design choice |
| Server wipe cycle + meta progression | none | Missing (Phase 7 scope) |
| Onboarding quests | none | Missing |
| Vehicle classes | police vehicle placeholder only | Missing |
| Arrest penalty beyond loot | surrender/cuff loses bag only | Could add jail timer |

Decisions on which gaps to adopt are recorded in `docs/ROADMAP.md`.
