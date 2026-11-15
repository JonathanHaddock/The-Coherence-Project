# Plan: every known field in origin (written 2026-11-14)

Goal: every field in the Standard Model, plus gravity, has a working counterpart on the lattice, and the particle observer can see it.

## How it is built

- One step at a time, in the order below. Each step becomes one numbered rule (or a few) in `RULES.md`, **logged before any run**.
- Each rule has its own switch. Zig (`src/engine/`) is the reference, and the JS port (`viewer/engine.js`, plus the inline copy in `viewer/index.html`) must give identical totals for the same seed.
- No tuning knobs. The only numbers allowed are counts that already exist: 3 cells, 6 neighbours, 8 patterns.
- Where a choice had to be made without Jono, the rule says **"default, Jono to confirm"**. If Jono picks differently, the default is struck and the new choice gets a new number.
- A step that fails its pass test is struck and noted, never deleted.
- Results go to `results/<rule>-<date>/` as TSV, with a SUMMARY.md.
- The observer (`viewer/observe-core.js`; a Zig port is not built yet) gains a new count for whatever each step introduces.

## Steps

| Step | Field | What gets built | Decision (default if Jono hasn't chosen) | Pass test (observer) | Status |
|---|---|---|---|---|---|
| F-0 | *(foundation)* motion | A pattern can travel: the whole pixel (pattern, memory, reinforcement) swaps with a neighbouring site. | A pixel moves only on a tick it flashes, one hop toward the neighbour holding the most carrier, if that is more than its own site holds, swapping with a pixel that didn't flash. Each site moves at most once per tick. Carrier stays where it is. | Pixels move; it's measured whether core pixels gather or scatter. | **done, rule 24**: the core comes apart (results/rule24-2026-11-14) |
| F-1 | EM | Charge gets a sign: u +2, d −1, e −3 (in thirds). The EM channel carries signed charge; like charges move apart, opposite charges together. | Charge = filled-cell count, as in rule 23. | Opposite charges close distance; like charges separate. | **done, rule 25**: right direction in every setting, but like-next-to-like stays above chance (results/rule25-2026-11-14) |
| F-2 | strong + colour (= R-D) | A colour label per quark pixel, a strong channel carrying colour, groups neutral when colours cancel, and a separation cost that grows with distance. | Jono's four R-D answers (what a quark is, where colour lives, what a group is, what binding means). | Isolated uud / udd triplets form and last. | planned |
| F-3 | weak | The weak channel turns d into u and emits e + antineutrino (rules 17–20 keep the books). Short range: weak carrier lasts one hop. | 1 hop (a count, no knob). | Free udd triplets decay at a flat hazard. | planned |
| F-4 | antiparticles (= R-E) | Each pattern's mirror is its complement (111 XOR p), with opposite charge. A meeting pair releases everything as carrier. | complement = antiparticle. | Pairs annihilate; total charge conserved. | planned |
| F-5 | Higgs | A background field everywhere; a pixel's coupling to it sets how hard it is to move (mass = resistance to F-0 motion). | Its own channel, filled at rest everywhere. | Electrons move more slowly than neutrinos without a hand-set mass. | planned |
| F-6 | gravity | Every channel's total carrier draws motion toward it (F-0), so mass becomes a source, not a hole. | Added alongside rule 6, not replacing it. | Two clumps draw together (needs a two-core start, open decision 7). | planned |
| F-7 | generations | e, μ, τ from lepton mode move onto the main lattice as a per-pixel property. | Generation per pixel, quarks included. | Heavier generations decay into lighter ones. | planned |
| F-8 | spin | ±½ per pixel; rule 22 exclusion becomes "same pattern **and** same spin". | Spin flips on every flash. | Two electrons share a neighbourhood when their spins differ (first sign of shells). | planned |

## Risk

F-0 changes what a pixel is: a fixed site becomes something that travels. Every later step depends on it, so if F-0 is struck, the rest of the plan has to wait for a new motion rule.
