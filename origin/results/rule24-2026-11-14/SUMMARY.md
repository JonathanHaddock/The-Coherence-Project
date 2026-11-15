# Rule 24 (PLAN-fields F-0): motion

There are 48 runs, each 600 ticks on the 48³ lattice with core 8 and seeds 1–3. They cover display (one_cell, flip_all) × update (sync, sweep) × 3 carriers (rule 23 off, on) × motion (off, on). Zig and JS give identical flash totals with rule 24 on: 5,607,251 (one_cell · sync, seed 1, 200 ticks) and 885,055 (flip_all · sweep · channels, seed 2, 150 ticks).

| File | What it holds |
|---|---|
| `table.tsv` | per setting: flashing and swaps (mean over ticks 450–600), where the core's starting pixels are at tick 600 |
| `over-time.tsv` | every 50 ticks, every run |
| `run.js`, `commands.txt` | how to rerun (from this folder) |

"Core pixels" = the pixels that started inside radius 8. With no motion their mean distance from the centre stays 5.97.

## What happened

- **The core comes apart.** With motion on, the core's pixels spread outward in every setting. At tick 600 their mean distance from the centre is 7.2–9.0 in six of the eight settings, and 29–57% of them have left the core.
- **The exception is flip_all · sweep**, which hardly moves: radius 5.98 (no channels) and 6.24 (channels). Flashing there drops to 0.008, so few pixels flash and few move.
- **Motion changes how much the world flashes,** in both directions. It cuts flashing in most settings (most of all flip_all · sweep: 0.077 → 0.008) and raises it in flip_all · sync (0.062 → 0.097).
- **Up to about 5,000 swaps per tick** (out of 110,592 sites).

## Reading

Under rule 24, a pixel that flashes moves toward the carrier it just made. The core is a hole in the flashing (see the earlier findings), so carrier piles up outside it, and the core's pixels drift out toward it. Mass doesn't hold itself together under this motion rule. That fits "mass is a hole, not a source" (open decision 1), and it's what F-6 (gravity as a pull) has to fix.

Rule 24 isn't struck: pixels do move, which was the pass test. Whether it's the right motion rule is Jono's call (it's a default).
