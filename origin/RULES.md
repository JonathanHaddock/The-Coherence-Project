# Engine rules: running list

One list, numbered in order. A new rule takes the next number. **No rule is ever deleted.** A rule proven false is struck through, with a note saying what proved it false and where.

The master log is `engine-rules.txt`, kept outside the repo. This list was rebuilt from code comments and commit messages on 2026-11-12, so check it against that log. Where the wording comes only from a commit message, it says so.

| # | Rule | Where | Status |
|---|---|---|---|
| 1 | **Display**, what a pixel shows when it flashes. `fill_empty` (first run): filled where reinforcement beats conserved share; this was a mistranslation, kept only to reproduce that run. `hold`: the pattern stays and the difference goes to memory. `one_cell`: flip the one cell with the largest mismatch surplus (§12). `flip_all`: flip every cell where mismatches outweigh matches. | pixel.zig | active (variants) |
| 2 | **Trigger:** a pixel flashes when its conserved share totals 3, one full pixel of cells. | pixel.zig | active |
| 3 | **No memory:** a flash releases the whole conserved share as the neutrino flash and clears reinforcement. | pixel.zig | active |
| 4 | **Update order:** synchronous ticks, or a sequential sweep. | pixel.zig | active (variants) |
| 5 | **Carrier:** the released neutrino share spreads one hop per tick to the 6 neighbours and is lost at the box edge. Measurement only. | grid3.zig | active |
| 6 | **Gravity feedback:** each whole pixel's worth of carrier (3 units) at a site reinforces every cell of the pattern shown. | grid3.zig | active (switch) |
| 7 | **Lepton mode:** cells are e, μ, τ, and the conserved share on cell k goes into carrier channel k. | lepton.zig | active (mode) |
| 8 | **Lepton channels** spread one hop per tick on wrapped edges, with nothing lost. | lepton.zig | active (mode) |
| 9 | **Absorption:** a whole unit in channel k acts as a flash showing k filled. It reinforces k if filled, otherwise it adds to memory on k. | lepton.zig | active (mode) |
| 10 | **Signed:** channels carry "shown filled" or "shown empty". | lepton.zig | active (switch) |
| 11 | **Turing:** carrier cancels memory (gravity as inhibitor). | lepton.zig | active (switch) |
| 12 | **Photograph:** a flash realizes the pattern shown after it. | photo.zig | active (mode) |
| 13 | **The neutrino is unrealized possibility.** Its makeup is the share of unrealized patterns with each position filled, weighted over all 7 others (`all7`) or only the 3 one-flip neighbours (`next`). | photo.zig | active (variants) |
| 14 | **Neutrinos** travel as a 3-channel field, one hop per tick, wrapped, with no effect on pixels. | photo.zig | active |
| 15 | **Delivery by information, not space:** each neutrino goes in the same tick to pixels linked by pattern (`same`, or `unreal` = the 7 unrealized). | photo.zig | active (variants) |
| 16 | **Arrival as memory:** whole units become +1 conserved; fractions wait. | photo.zig | active |
| 17 | **Weak events:** only a flipped cell (a quark flash) emits a neutrino. | engine.js (Zig port pending) | active |
| 18–19 | From commit 12e07ac only: "beta-type antineutrinos act on filled cells, capture-type neutrinos on empty cells", logged as rules 17–19 together. The exact split between 18 and 19 needs checking against the log. | engine.js | active |
| 20 | **Handedness:** antineutrinos (beta) and neutrinos (capture) are kept apart. | engine.js | active (switch) |
| 21 | **Carrier cancels memory (lattice), build spec R-A.** Each whole pixel's worth of carrier (3 units) at a site cancels one conserved unit on each cell that holds one. Every cancelled memory unit uses up one carrier unit, so the two annihilate one for one and nothing is created. The only number is the cell count, as in rule 6. This is the base-lattice counterpart of rule 11. Switch: `feedback=cancel` (rule 6 is `feedback=reinforce`, the same as `gravity=on`). Logged 2026-11-12, before any run. Result 2026-11-12: flashing goes to 0 in all 4 settings, see results/rule21-2026-11-12. | grid3.zig, engine.js | active (switch) |
| 22 | **Exclusion on the pattern (lattice), build spec R-B.** A flash may not display a pattern that any of its 6 neighbours is showing. A blocked flash **waits**: the pixel doesn't flash that tick, keeps its pattern and keeps its memory, and tries again next tick. No new number. This applies to every flash, the tick-0 kick included. Sync checks neighbours as they were at the start of the tick; sweep checks them as they are when the pixel's turn comes. "Same state" = pattern (Jono, 2026-11-12). Switch: `exclusion=on`. Logged 2026-11-12, before any run. Result 2026-11-12: one_cell and flip_all jam (flashing 0 by about tick 20); hold drops from 98% to a steady 28–40%; no shells. See results/rule22-2026-11-12. | pixel.zig, grid3.zig, engine.js | active (switch) |

## Planned (build spec 2026-11-12, `ORIGIN engine — missing pieces`)

R-A is rule 21, R-B is rule 22. The rest get numbers only when they are logged and built, in this order: R-B exclusion, R-C three carriers, R-D colour and confinement, R-E antiparticles.

## Struck (proven false)

None yet.
