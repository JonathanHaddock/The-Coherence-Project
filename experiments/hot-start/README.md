# Hot start (2026-11-14)

Question (Jono): with fields on links (rule 28) and Higgs-like mass (rule 29), the world froze after tick 1 because there was too little energy. If the world starts hot, does it run down?

Research basis: inflation and reheating (Kofman, Linde & Starobinsky 1997). The universe started with its energy in fields, not at rest. This tests the moment just after reheating: the force fields already excited.

**Starting condition only, no rule.** Each of weak, EM and strong on every link starts at a random whole number 0..2T (mean T), the same for every generation. It uses its own random stream, so the engine's own start is unchanged. T is the experiment's variable (like jostling in `experiments/precompression`). Fixed: one_cell · sync, core 8, rule 28 on, 3,000 ticks, seeds 1–3, run on the one-pixel field.

```sh
node run.js 3 off 1 3000      # T, higgs, seed, ticks
sed 's/^node run.js //' commands.txt | xargs -P 8 -L 1 node run.js   # all 30 runs
```

| File | What it holds |
|---|---|
| `over-time.tsv` | ticks 1–5, then every 100: flashing, memory, field, energy (per pixel), share of pixels that could express (a selected field with a link difference of 2 or more) |
| `table.tsv` | means over 3 seeds |

## Results (share of pixels flashing)

| T | Higgs | t1 | t100 | t500 | t1000 | t2000 | t3000 | could express, t3000 |
|---|---|---|---|---|---|---|---|---|
| 0 (rule 28 as logged) | off | 0.141 | 0.0001 | 0.0001 | | | 0.0001 | |
| 1 | off | 0.141 | 0.209 | 0.209 | 0.209 | 0.209 | **0.209** | 0.14 |
| 2 | off | 0.141 | 0.458 | 0.445 | 0.437 | 0.426 | **0.418** | 0.44 |
| 3 | off | 0.141 | 0.548 | 0.526 | 0.518 | 0.503 | **0.490** | 0.56 |
| 5 | off | 0.141 | 0.623 | 0.563 | 0.559 | 0.555 | **0.550** | 0.66 |
| 10 | off | 0.141 | 0.677 | 0.610 | 0.583 | 0.579 | **0.581** | 0.72 |
| 1 | on | 0.015 | 0.006 | 0.006 | 0.006 | 0.006 | **0.006** | 0.006 |
| 2 | on | 0.015 | 0.020 | 0.020 | 0.020 | 0.020 | **0.020** | 0.024 |
| 3 | on | 0.015 | 0.022 | 0.022 | 0.022 | 0.022 | **0.022** | 0.027 |
| 5 | on | 0.015 | 0.021 | 0.020 | 0.020 | 0.020 | **0.020** | 0.025 |
| 10 | on | 0.015 | 0.028 | 0.016 | 0.017 | 0.016 | **0.016** | 0.022 |

Seeds agree closely (at t3000 the spread is under 0.002 in every row). Energy per pixel is identical at tick 1 and tick 3,000 in every run (for example T 3: 27.963), so rules 28 and 29 conserve it exactly.

## What happened

- **A hot start keeps the world going.** Every hot run is still flashing at tick 3,000, where the cold start (T 0) froze after tick 1.
- **Hotter means busier, up to a point.** Without Higgs mass, flashing settles at 21% (T 1) to 58% (T 10). The gain flattens above T 5.
- **It is running down, slowly, at T 2 and T 3.** Flashing falls about 0.01 per 1,000 ticks (T 3: 0.548 at tick 100 → 0.490 at tick 3,000), and the usable share (could express) falls with it. T 1 is flat, and T 5–10 nearly flat. 3,000 ticks isn't enough to tell whether the decline stops or reaches zero.
- **Mass slows everything but doesn't stop it.** With rule 29, flashing settles at 0.6–2.8% and stays flat from tick 100 to 3,000. It alternates from tick to tick (T 3, seed 1: about 720, then 2,420 flashes). The heavier the matter, the less it changes.
- **Not an exact loop.** Checked at T 1 (Higgs off) and T 3 (Higgs on): the patterns don't repeat with any period under 20 ticks.

## Reading

Energy never leaves (closed box), so "running down" can only mean the energy becoming too even to use. A hot start puts the world far enough from even that it lasts at least 3,000 ticks, and in most settings shows no sign of stopping. The slow decline at T 2–3 is the thing to watch; a longer run (20,000+ ticks) would show whether it levels off.
