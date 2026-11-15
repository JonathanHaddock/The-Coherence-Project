# Rule 25 (PLAN-fields F-1): signed EM field

There are 36 runs, each 600 ticks on the 48³ lattice with core 8 and seeds 1–3. They cover display (one_cell, flip_all) × update (sync, sweep) × condition: `still` (no motion), `move` (rule 24 only) and `move_em` (rules 24 + 25). Zig and JS give identical flash totals with 24 + 25 on: 5,021,236 (one_cell · sync, seed 1, 200 ticks) and 960,586 (flip_all · sweep, seed 2, 150 ticks).

| File | What it holds |
|---|---|
| `table.tsv` | per setting, ticks 450–600, all seeds |
| `over-time.tsv` | every 50 ticks, every run |
| `run.js`, `commands.txt` | how to rerun (from this folder) |

Measures, both compared with the same pixels placed at random:
- `opp_ratio`: the share of neighbouring charged pairs that have opposite signs. 1 = chance, above 1 = opposites gather.
- `ee_ratio`: how often two electrons sit next to each other. 1 = chance, below 1 = electrons keep apart.

| Setting | opp_ratio still | move | move + EM | ee_ratio still | move | move + EM |
|---|---|---|---|---|---|---|
| one_cell · sync | 0.59 | 0.58 | **0.63** | 5.5 | 5.2 | **1.5** |
| one_cell · sweep | 0.59 | 0.58 | **0.67** | 4.9 | 4.9 | **1.6** |
| flip_all · sync | 0.56 | 0.58 | **0.64** | 5.7 | 6.8 | **1.5** |
| flip_all · sweep | 0.27 | 0.36 | **0.52** | 6.9 | 6.4 | **3.5** |

## What happened

- **EM pushes in the right direction in every setting.** Opposite charges become neighbours more often, and electrons stop clumping. Electron clumping falls from 5–7× chance to 1.5–3.5×. All three seeds agree (opp_ratio spread at most 0.075 per setting).
- **But it never gets past chance.** Even with EM on, opposite charges sit together only 0.52–0.67 as often as chance, and electrons still sit together more than chance. The engine's own ordering (neighbours copy each other's pattern, which means the same charge) is stronger than the EM pull.
- **EM calms the world.** Flashing falls to 0.017–0.027 in every setting (from 0.036–0.097 with motion alone), and with it the number of moves.

## Reading

The pass test was "opposite charges close distance, like charges separate". Rule 25 does that **relative to the world without it**, but the lattice still prefers like next to like. It isn't struck. Whether that counts as a pass is Jono's call. If pairs of opposite charges (atoms) are wanted, something will have to outweigh the pattern copying, which is the neighbour agreement rules 1–3 produce.

## Longer runs (added 2026-11-14, found while watching the 3D viewer)

The 600-tick runs above stop too early. one_cell · sync, core 0, default seed, 3,000 ticks, share of pixels flashing:

| ticks | 500 | 1000 | 1500 | 2000 | 2500 | 3000 |
|---|---|---|---|---|---|---|
| rules 1–5 | 0.058 | 0.049 | 0.042 | 0.042 | 0.040 | 0.039 |
| + motion (24) | 0.038 | 0.022 | 0.042 | 0.036 | 0.034 | 0.032 |
| + motion + EM (24 + 25) | 0.048 | 0.015 | 0.005 | 0.002 | 0.0006 | **0** |

**With EM on, the world goes completely dark by about tick 2,750.** Nothing flashes and nothing moves. Without EM it keeps flashing at 3–4%. EM moves each charged pixel to where it is most at ease, and once every pixel is there, nothing is left to drive a flash. One seed and one setting so far.
