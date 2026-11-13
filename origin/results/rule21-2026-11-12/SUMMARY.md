# Rule 21 (build spec R-A): carrier cancels memory

There are 36 runs, all 1,500 ticks on the 48³ lattice with core 8 and seeds 1–3. They cover display (one_cell, flip_all) × update (sync, sweep) × feedback (off, reinforce = rule 6, cancel = rule 21). Zig and JS give identical totals with rule 21 on (300 ticks, one_cell, sync, core 8: 629,553 flashes in both).

| File | What it holds |
|---|---|
| `table.tsv` | all measures per setting: mean ± spread over seeds |
| `flashing-over-time.tsv` | flash share every 50 ticks, every run |
| `commands.txt` | the commands that produced the runs (run from this folder) |
| `runs/` | the raw recordings |

## Results (last third of each run)

| Setting | off | reinforce (6) | cancel (21) |
|---|---|---|---|
| one_cell · sync | 0.046 | 0.232 | **0.001** |
| one_cell · sweep | 0.077 | 0.201 | **0.000** |
| flip_all · sync | 0.047 | 0.189 | **0.001** |
| flip_all · sweep | 0.113 | 0.105 | **0.000** |

Core / outside flash ratio (below 1 means mass shows as a hole):

| Setting | off | reinforce | cancel |
|---|---|---|---|
| one_cell · sync | 0.28 | 0.12 | 0.02 |
| one_cell · sweep | 0.67 | 0.45 | no flashing |
| flip_all · sync | 0.04 | 0.87 | 0.02 |
| flip_all · sweep | 0.25 | 0.10 | no flashing |

## What happened

- **Rule 21 shuts the engine down in every setting.** In one_cell · sync (seed 1), flashing falls from 0.14 to 0.019 by tick 30, to 0.006 by tick 150, and to 0 by tick 1350. With feedback off, the same run settles at about 0.04 and keeps going. Carrier annihilating memory removes what the trigger needs, so nothing refills it.
- **Mass stays a hole under every feedback mode**, which bears on open decision 1. Reinforce makes the world flash 2–5× more, but the core stays quieter than its surroundings in every setting's mean. The one exception is a single seed of flip_all · sync · reinforce (spread ±0.98), the bright-core branch already seen in the 2026-11-10 sweep (lead A). Cancel deepens the hole until everything is dark.
- **Agreement:** cancel leaves sync worlds less uniform (0.81–0.82 against 0.89 with feedback off). The world freezes before it has organized.
- **Not tested:** whether separate regions attract, repel or merge. The code only has a single-core start, and a two-core start would be a new setting. That's your call.

Rule 21 is not struck. It isn't proven false, but as written it leaves no running engine to test anything else against.
