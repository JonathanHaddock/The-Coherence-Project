# Rule 22 (build spec R-B): exclusion on the pattern

There are 72 runs, all 1,500 ticks on the 48³ lattice with core 8 and seeds 1–3. They cover display (hold, one_cell, flip_all) × update (sync, sweep) × feedback (off, reinforce = rule 6) × exclusion (off, on). Zig and JS match exactly with rule 22 on: 200-tick totals agree in all 6 display × update combinations, for example one_cell · sync = 52,635 flashes in both.

| File | What it holds |
|---|---|
| `table.tsv` | all measures per setting |
| `flashing-over-time.tsv` | flashing share every 50 ticks |
| `commands.txt` | the commands that produced the runs |
| `runs/` | the raw recordings |

## Flash share (last third)

| Setting | off | exclusion |
|---|---|---|
| one_cell · sync | 0.046 | **0.000** |
| one_cell · sweep | 0.077 | **0.000** |
| flip_all · sync | 0.047 | **0.000** |
| flip_all · sweep | 0.113 | **0.000** |
| hold · sync | 0.984 | **0.282** |
| hold · sweep | 0.985 | **0.396** |

With rule 6 also on, the results are the same, apart from 0.001 in one_cell.

## What happened

- **Freezing doesn't stop; it gets total.** With one_cell and flip_all, the lattice jams by about tick 20 (one_cell · sync: 0.080 → 0.004 by tick 10 → 0). Most ready pixels want a pattern a neighbour already shows, so they wait. A waiting pixel sends nothing, so its neighbours wait too.
- **Agreement drops to random or below** (0.485–0.521, against 0.86–0.93 without exclusion). Exclusion forbids exactly the matching that built order.
- **Hold:** exclusion turns the runaway (98% of pixels flashing every tick) into a flat steady state, 28.2% (sync) or 39.6% (sweep), identical from tick 20 to 1,500. The profile outside the core is flat (0.26–0.31 at every distance), with no shells or layers. Hold never changes a pattern, so this is the fixed set of pixels whose own pattern no neighbour shares.
- **No shell or layer structure appears** in any setting.

Rule 22 is not struck. As written ("a blocked flash waits"), it jams every rule that changes patterns. The spec's other option, "goes to the next free slot", would need a choice of which slot comes next, and that's Jono's call.
