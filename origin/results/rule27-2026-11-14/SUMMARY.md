# Rule 27: hearing conserves (from the Bak-Tang-Wiesenfeld sandpile)

There are 96 runs, each 3,000 ticks on the one-pixel field (`viewer/pixel-model.js`), with motion (24) on, core 0 and seeds 1–3. They cover display/update (one_cell · sync, flip_all · sweep) × rule 26 (off, on) × EM (off, on) × sun (off, on) × edge (closed, open).
- **Matching:** the pixel field matches engine.js in 13 rule combinations, including 27, 26 + 27, and 23–27 together (`scripts/pixel-parity.js`). Zig and JS give identical totals with 24–27 on: 291,085 (one_cell · sync, seed 1) and 147,467 (flip_all · sweep, seed 2), 150 ticks each.

| File | What it holds |
|---|---|
| `table.tsv` | flashing at ticks 100, 500, 1000 and 3000, plus memory and carrier per pixel at the end |
| `over-time.tsv` | every 100 ticks, every run |
| `run.js`, `commands.txt` | how to rerun (from this folder) |

## What happened

- **No more runaway, but the world now goes quiet in every one of the 96 runs, within about 100 ticks.** Rule 26 on or off, EM on or off, sun or no sun, open or closed edge: by tick 100 flashing is 0, or 0.0001 (the 7 forced sun pixels).
- **Energy is now conserved.** Memory + carrier starts at about 1.5 per pixel (the random start) and stays there apart from what leaks out at the edge. With the edge open, nothing leaks (0.90 memory + 0.58 carrier per pixel at the end in one_cell · sync).

Trace, one_cell · sync, rules 24 + 26 + 27, default seed:

| tick | 1 | 5 | 10 | 20 | 40 | 100 |
|---|---|---|---|---|---|---|
| share flashing | 0.125 | 0.150 | 0.131 | 0.063 | 0.011 | 0.0001 |
| memory per pixel | 1.50 | 1.42 | 1.28 | 1.08 | 0.93 | 0.90 |
| carrier per pixel | 0.00 | 0.07 | 0.20 | 0.37 | 0.43 | 0.33 |

## Why

The world doesn't have enough energy to keep going. A pixel needs 3 units of memory to flash, and the world holds about 1.5 per pixel on average, spread evenly. Once the first flashes have spread it out, almost no pixel reaches 3. Carrier spreads thin too (about 0.3 per site), and rule 26 needs 3 at one site, so it never fires either.

This is what the sandpile literature predicts. A conserved sandpile below the critical density stops, and Bak-Tang-Wiesenfeld keep theirs going by **adding grains slowly from outside** (slow driving), with loss at the edge. Origin now has the loss (rule 5's edge) but no input. The "sun" in these runs forces flashes, but under rule 27 a flash with no memory hands out nothing, so the sun adds no energy.

Not struck: rule 27 did what it was for (no energy from nothing, no runaway). The next test is to drive it: a sun that adds energy, for example one unit of memory per tick at a random site (the BTW drive), or one pixel's worth (3 units) per tick at the centre.
