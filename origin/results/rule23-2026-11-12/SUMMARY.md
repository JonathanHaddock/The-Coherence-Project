# Rule 23 (build spec R-C): three carriers, each conserved separately

There are 54 Zig recordings: hold, one_cell and flip_all × sync and sweep × {feedback off, rule 6 reinforce, rule 23 channels} × seeds 1–3, all 1,500 ticks with core 8. There are also 18 Node runs measuring each pixel kind under rule 23 (`kinds.js`, in `kinds.tsv`).

Zig and JS match exactly with rule 23 on. Over 200 ticks, flash totals and carrier totals agree in all 6 display × update combinations, for example one_cell · sync = 6,736,762 flashes and carrier 714,862.319 in both.

| File | What it holds |
|---|---|
| `table.tsv` | lattice measures per setting |
| `kinds.tsv` | per-kind population, flash rate and absorbed share per channel |
| `runs/` | the raw recordings |
| `commands.txt` | the commands that produced the runs |

## Whole-lattice results (last third)

| Setting | flash, off | rule 6 | rule 23 | core / outside, rule 23 |
|---|---|---|---|---|
| one_cell · sync | 0.046 | 0.232 | 0.184 | 0.26 |
| one_cell · sweep | 0.077 | 0.201 | 0.187 | 0.67 |
| flip_all · sync | 0.047 | 0.189 | 0.166 | 0.50 |
| flip_all · sweep | 0.113 | 0.105 | 0.133 | **2.37** (seeds: 5.99, 0.29, 0.82) |
| hold (both) | 0.98 | 0.98 | 0.98 | 0.20 |

- **The world keeps flashing, much as with rule 6,** and the carrier falloff goes flat (slope about 0).
- **flip_all · sweep, seed 1, has the brightest core seen so far:** the core flashes at 0.295 against 0.049 outside, 6.0× more. The other two seeds have quiet cores, so this is a rare branch again, like lead A in the 2026-11-10 sweep.

## By pixel kind (one_cell and flip_all, mean over 3 seeds)

| Kind | Population share (random = 0.125 / 0.375) | Flash rate | Absorbed: weak / EM / strong |
|---|---|---|---|
| neutrino (0 filled) | **0.025–0.106** (depleted) | **0.23–0.28** (highest) | 1.00 / 0 / 0 |
| down (1) | 0.34–0.41 | 0.15–0.20 | 0.38 / 0.31 / 0.31 |
| up (2) | 0.40–0.49 | 0.12–0.18 | 0.34 / 0.35 / 0.31 |
| electron (3) | 0.08–0.16 | 0.13–0.18 | 0.50 / 0.50 / 0 |

## Against the spec's checks

- **Do neutrinos stay invisible to everything but weak?** Yes, but by construction: the rule says so. What *emerges* is that neutrino pixels are the rarest kind and flash the most.
- **Do charged leptons sit between the poles?**
  - **By absorbed mix:** electrons split 50/50 between EM and weak, selectivity S = 0.37. The triangle note gives 0.38–0.48 for charged leptons.
  - **But the quark pole is wrong:** quarks absorb about equally on all three channels (S ≈ 0). The triangle has them dominantly strong (S = 0.59–0.89). An equal split can't produce "dominantly strong".
  - **By flash rate:** electrons don't sit between the poles. They flash at or below the quarks.
- **Population:** quarks are enriched (up 40–49%, against 37.5% at random); neutrinos and electrons are depleted.

Rule 23 is not struck.
