# Rule 36: slow driving at a fixed rate (2026-11-19)

Setting of rule 35 (allowed, neutral, core 10, motion, tension), seed 20261110, 6,000 ticks; measured over ticks 3,000–6,000. The outside adds r memory units per tick (sites from a fixed seeded sequence, cells r, g, b, u, d in turn). Zig only.

Energy ledger (memory + carrier + string energy + edge loss − driven): drift 0 at every rate.

| r (units/tick) | flashes per tick, ticks 1k…5k | mean (3k–6k) | exchanges | var/mean | hazard of a pixel's next change, gaps 1 / 2 / 5 / 10 / 20 |
|---|---|---|---|---|---|
| 0 | 129 126 125 125 126 | 125 | 50 | 0.0 | periodic: 0.80 / 0.85 / 0.00 / – / – |
| 1 | 106 96 35 18 15 | 24 | 2 | 2.8 | 0.29 / 0.88 / 0.13 / 0.08 / 0.005 |
| 10 | 222 103 158 153 132 | 165 | 24 | 10.9 | 0.30 / 0.32 / 0.035 / 0.016 / 0.006 |
| 100 | 1548 1895 1819 1911 1974 | 1886 | 272 | 9.3 | 0.22 / 0.24 / 0.054 / 0.040 / 0.027 |
| 1000 | 14675 16659 16689 14496 10733 | 12612 | 1988 | 514 | 0.33 / 0.33 / 0.13 / 0.073 / 0.041 |

- r = 0: the world never goes quiet. About 110 tiny lepton clusters (1–5 pixels) at the box walls trade u ↔ d and swap places forever on fixed memory (185,042 units), creeping along the walls (one moved ~4 cells in 200 ticks). Strictly periodic.
- Even the smallest drive (r = 1) breaks that clockwork: the wall floor dies down to ~15–24 flashes per tick.
- r = 10 and 100: steady states. The hazard loses its period structure and falls smoothly; at r = 100 its tail is the flattest of any run so far (0.033 → 0.025 over gaps 11–19), but still falling, so not constant-chance decay.
- r = 1000: not steady by 6,000 ticks (a slow rise and fall).
- No criticality signature: no heavy tail in the per-tick flash count at any rate (no tick above twice the mean).

Files: drive-<r>.tsv (per tick; last lines: #changes and #hazard, gaps 1–40).
