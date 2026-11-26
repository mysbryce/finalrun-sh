# FinalRun

![Vibe Project](https://img.shields.io/badge/vibe-project-ff69b4) ![Godot 4.7](https://img.shields.io/badge/Godot-4.7-478cbf)

> Mask up. Grab the loot. Get out alive.

> [!NOTE]
> **Vibe Project.** Code is AI-written: Claude plans, briefs, and reviews; a DeepSeek agent (`dsh`) writes the code. Expect rough edges.

A 3D multiplayer extraction crime sandbox built with **Godot 4.7** and server-authoritative ENet networking.

## The loop

| Map | Vibe |
|---|---|
| **Motel** | Safezone. Stash cash, form a crew of 3. |
| **Looty Bay** | The job. PvPvE heists, cops on patrol, extract or lose it all. |
| **House** | Shared neighborhood. Build, store, launder. |
| **Center** | Shared market. Sell hot goods, trade, upgrade. |

**Citizen** walks free. **Criminal** wears the mask and takes the risk. **Cop** hunts criminals for the bounty.
Surrender and you lose the bag. Die and you lose everything.

## Run it

```bash
godot_console --path . -- --server   # dedicated server (port 7777)
godot_console --path .               # client
godot_console --headless --path . -s res://tests/run_tests.gd   # tests
```

## Docs

- [Architecture](docs/ARCHITECTURE.md): instancing, sync isolation, transfer flow
- [Conventions](docs/CONVENTIONS.md): folder layout, `lib/`, reuse rules
