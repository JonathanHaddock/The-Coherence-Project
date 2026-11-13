# Parameter sweep, 2026-11-10

This sweep used only the existing parameters; no rules were added or changed. It covers 150 recorded runs of 1,500 ticks each on the 48³ lattice:

- **Lattice:** `display` (hold, one_cell, flip_all) × `update` (sync, sweep) × `core` (0, 4, 8) × `gravity` (off, on), with seeds 1–3.
- **Lepton modes:** v1, signed and turing, each with core 0 and core 8, seeds 1–3.
- **Control:** p = 0.05 and p = 0.2, seeds 1–3.
- **Follow-up:** 12 more seeds for flip_all/sync/core 8/gravity on, and 6 more for one_cell/sync/core 8/gravity on.

All numbers are averages over the last third of each run, given as mean ± spread across seeds. The full table is in `table.tsv`, and `analyze.py runs groups.json` rebuilds it.

## Against the four "notable" tests

| Test | Result |
|---|---|
| 1. Steady flashing at a constant chance per tick (decay) | **No setting passes.** The control's hazard is flat: its CV is 0.003–0.009. Every engine setting that keeps flashing has a hazard CV of 0.9–1.8, with strong even/odd rhythms. Hold runs away to 98–100% flashing, while v1 and turing freeze at 0%. |
| 2. Dense core flashes **more** than its surroundings | **1 run in 15** (see lead A). Every other run has a quiet core, with core/outside ratios of 0.00–0.67. Mass shows up as a hole in the flashing, as the handoff already noted. |
| 3. Carrier falls off as 1/distance | **No clean result** (see lead B). The exponent moves toward −1 as the core grows, but the box edge may be causing that. |
| 4. Ratios near 2/3 or 1/3, beating the control | **Nothing convincing.** one_cell/sync/gravity: 62% of flash gaps are even, short of 2/3. one_cell/sweep: 28–31% even, short of 1/3. Mean fill is 0.50 everywhere except v1. |

## Leads worth your eye

**A. flip_all + sync + gravity + core 8, seed 2: the core becomes a bright source.**
The core flashes at 0.57 per tick against 0.20 outside, 2.9× more. That is the opposite of every other run. The other 14 seeds have ratios of 0.00–0.13, and one_cell does it in none of 9 seeds. It's a rare branch, not typical behavior for this setting, but it is the only state in the sweep where "mass flashes more" (your open question 1) happens. To reproduce it, run from `origin/`:

```sh
zig-out/bin/origin record mode=lattice display=flip_all update=sync core=8 gravity=on seed=2 ticks=1500
```

**B. Without gravity, the carrier falloff steepens as the core grows.**
Fitted exponent outside the core, consistent across seeds (spread ≤ 0.07):

| Core | Exponent |
|---|---|
| 0 | −0.29 to −0.35 |
| 4 | −0.50 to −0.59 |
| 8 | −0.70 to −0.76 |

The 1/distance value is −1.00. **Caveat:** the fit window is shells core+3 through 19 in a box of half-width 24, with carrier lost at the edge. A bigger core pushes the window toward the edge, which makes the falloff steeper by itself, so this may be geometry rather than the engine. It needs a larger box or wrapped edges to tell.

**C. Gravity removes the falloff entirely.**
With gravity on, the exponent is about 0.00 in every setting. Gravity also raises flashing from about 0.05 to about 0.20 (sync).

**D. Lepton v1 freezes with every cell filled.**
Mean fill is 1.000 and agreement is 1.000, so every pixel ends up an electron in all 6 runs. Turing freezes at mean fill 0.50 with agreement 0.74. Signed runs away (99% flashing). None of these modes keeps a mix of kinds.

## Not done

- No rules were changed or invented. The open decisions in `HANDOFF-engine.md` still drive what can work.
- I didn't check the falloff on a larger box, because the lattice size is a compile-time constant (`grid3.side = 48`).
