# Rules 28 (fields on links) and 29 (Higgs-like mass)

There are 12 runs, each 600 ticks on the one-pixel field (`viewer/pixel-model.js`), with core 8 and seeds 1–3. They cover display/update (one_cell · sync, flip_all · sweep) × rule 29 (off, on); rule 28 is on in all of them.
- **Matching:** the pixel field matches engine.js on 28 and on 28 + 29 (`scripts/pixel-parity.js`, 16 combinations). Zig and JS give identical totals: 15,592 (28, one_cell · sync, seed 1, 150 ticks), 1,707 (28 + 29, flip_all · sweep, seed 2) and 1,687 (28 + 29, one_cell · sync, seed 1).
- **Bug fixed before these runs:** the code dealt a flash's memory over all of weak's links before EM's, but rule 28(f) says field by field. With about 3 units per flash, EM and strong never received anything. The code now follows the rule, and parity was rechecked.

| File | What it holds |
|---|---|
| `over-time.tsv` | ticks 1–10, then every 50: flashing, memory per pixel, units of weak / EM / strong on links, share of field held, energy per pixel |
| `by-kind-generation.txt` | flashes over the whole run by kind (before flashing) × generation |
| `run.js`, `commands.txt` | how to rerun (from this folder) |

## What happened

**The world flashes once, on tick 1, and never again, in all 12 runs.**

- **Without rule 29:** 14% of pixels flash on tick 1 (those that start with memory 3). Their memory goes into the links (one_cell · sync, seed 1: weak 20,381, EM 13,894, strong 10,120 units), and after that only a handful of pixels ever flash. Energy (memory + field) is conserved exactly, at 1.53 per pixel.
- **With rule 29:** only **neutrinos** flash on tick 1 (1.5%), the one kind with no mass. Every massive pixel's trigger is 4 or more, so none of them reach it. Generations are flashed equally (561, 563, 562), as expected, since neutrinos have no Higgs coupling.
- **81–83% of the field ends up held** (both end pixels select it), and so can't move.

## Why it freezes

1. **Fields start at rest (0), so the only energy is the matter's starting memory**, about 1.5 per pixel, half of one trigger.
2. **A flash spreads its 3 or so units thinly,** about one per link. A neighbour's links then differ by at most 1, and expression (rule 28e) needs a difference of at least 2. So nothing is ever expressed again.
3. **Most of the field is held,** so it can't flow into piles either.

This is the same lesson as rule 27, and as the sandpile literature: a conserved world below its threshold density stops. Rule 29's mass makes it worse, because massive matter needs even more before it changes.

Not struck: the rules do what was logged. The open question for Jono is where the energy comes from. In physics, the fields at rest don't supply it; the early universe started hot and dense (with a lot of energy in fields and matter), and the Higgs background doesn't power anything either.
