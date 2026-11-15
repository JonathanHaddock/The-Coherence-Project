# Rule 26: carrier excites (adds memory)

Zig and JS give identical flash totals with rule 26 on: 16,385,183 (one_cell · sync · core 8 · motion + EM + excite, seed 1, 150 ticks). The pixel field matches the engine in all 10 checked combinations (`scripts/pixel-parity.js`).

## What happened

**The world runs away.** Within 10 ticks every pixel flashes every tick, and it stays that way. That holds in all 24 sun / open-edge / EM runs (`experiments/sun/table.tsv`, rows with excite = on: flashing 1.000 at ticks 500 to 3,000, every seed).

Trace, one_cell · sync, core 0, default seed (no sun, edge closed, no motion):

| tick | 1 | 2 | 3 | 5 | 10 | 20 | 40 | 60 |
|---|---|---|---|---|---|---|---|---|
| share flashing | 0.13 | 0.37 | 0.67 | 0.98 | 1.00 | 1.00 | 1.00 | 1.00 |
| memory per pixel | 2.3 | 4.5 | 9.2 | 21.9 | 55.9 | 119.8 | 235.4 | 339.5 |
| carrier per pixel | 0.37 | 1.22 | 1.47 | 1.51 | 1.50 | 1.50 | 1.50 | 1.50 |

Memory per pixel keeps growing by about 6 per tick, with no ceiling.

## Why

Rule 26 itself conserves: 3 carrier units become 3 memory units. But **hearing a mismatch creates memory from nothing.** Each neighbour's flash adds +1 memory to every cell that differs (rule 1 bookkeeping), and that has never been conserved. Until now the carrier carried that excess away and lost it at the box edge (rule 5). Rule 26 turns the excess back into memory, so it piles up, and every pixel stays above the trigger forever.

So rules 1–5 were only stable because carrier was a drain. With carrier acting on pixels, the source of the extra energy (memory made by hearing) shows up.

Not struck: that's Jono's call. Options that come out of this, none built:
1. Make hearing conserve: a heard flash moves memory rather than creating it, for example the shouting pixel's released share split among its 6 neighbours instead of +1 per mismatched cell.
2. Let rule 26 apply only to carrier that arrives from elsewhere, not carrier a pixel released itself.
3. Pair rule 26 with a drain somewhere else.
