# Rules 30–31: five-cell pixel and colour on links (2026-11-18)

Logged in RULES.md before any run. Zig is the reference (`src/engine/five.zig`, command `origin five`); the JS port is the five-cell part of `viewer/engine.js` (and its inline copy in `viewer/index.html`).

## Checks

- **Zig tests** (`zig build test`): five-cell charges (antineutrino 0, down −1, anti-up −2, electron −3, up +2, neutrino 0, right-handed neutrino 0, in thirds); beta decay is one weak flip with colour untouched, −1 = +2 − 3 + 0; the start obeys the Gauss law. All earlier tests still pass.
- **Zig = JS, tick for tick** (`compare/`): identical totals (flashes, exchanges, blocked, plaquette moves, swaps, charge, colour, quarks, Gauss violations, flux energy, links with flux, carrier to 6 decimals, memory) in 6 settings: default; motion; motion + EM + core 8; colour off + motion; gravity instead of conserve/excite + motion; exclusion + motion, seed 7.
- **Conservation every tick** (`check5.js`, 4 settings × 30 ticks): total charge, total colour and the census of (colour cells, weak cells) per pixel never change. **Gauss law: zero violations at every site, every tick.**

## Result (`runs/`, 48³, 600 ticks)

| setting | flashes tick 0 | tick 9 | tick 49 onward | flux energy (×3) start → end |
|---|---|---|---|---|
| default (conserve, excite, colour) | 2,180 | 106 | 1 per tick | 1,563,504 → 388,342 |
| + motion | 2,180 | 211 | 15 per tick | 1,551,190 → 380,016 |
| + motion + EM, core 8 | 2,137 | 457 | 17 per tick | 1,508,890 → 375,630 |
| colour off, motion | 2,180 | 130 | 0 from tick ~100 | — |

1. **Conservation and the Gauss law hold exactly**, in every run, every tick.
2. **Strings relax:** plaquette moves cut the colour-flux energy about 4× within 10 ticks, then it stays put.
3. **The world freezes within about 50 ticks.** Only a short cycle of 1–17 pixels keeps flashing.

## Why it freezes (`why_blocked.txt`, after 100 ticks)

About 3,200–3,800 pixels are ready (memory ≥ 5) but can't flash:

| reason | no motion | motion |
|---|---|---|
| rule 1 wants a colour change, but the pixel is a lepton (0 colour cells) | 1,031 | 1,083 |
| rule 1 wants a colour change, but the pixel is a lepton (3 colour cells) | 937 | 1,012 |
| colour change possible, but no neighbour can take the opposite | 552 | 813 |
| rule 1 wants u ↔ d, but u = d = 1 | 350 | 423 |
| rule 1 wants u ↔ d, but u = d = 0 | 307 | 375 |
| u ↔ d possible, no neighbour can take the opposite | 51 | 100 |

About 80% of stuck pixels have rule 1 choosing a change that rule 31 forbids for their kind. They keep their memory forever, and the rest of the world holds 2.5 units per pixel, half of what a flash needs.

## Open decisions (Jono's)

1. **Rule 1 under rule 31:** should rule 1 choose only among changes the pixel's kind can make (the cell with the largest surplus *among allowed changes*), or should a flash that can't change anything still release its memory (a flash with no change)? Either would unfreeze the stuck 80%; they mean different things.
2. **The random start is 75% quarks** (6 of 8 colour patterns are 1 or 2 cells). The real world's matter is colour-neutral at large scale. A start built from neutral groups (or from the core) may be the fairer test.
3. **Rule 31's conservation assumption** was made when the question went unanswered; it's marked "Jono to confirm" in RULES.md.

## Rules 32–33 (2026-11-18)

Rule 32: rule 1 tries cells by surplus and takes the first change the pixel's kind allows with a willing partner; if none, the pixel still flashes and releases memory without changing pattern. Rule 33: start with a colour-neutral vacuum outside the core and colour pairs (quark + matching antiquark) inside it, core memory full.

Checks: Zig = JS tick for tick in 6 settings (`compare32/`); charge, colour, census, Gauss law exact in all (`check5.txt`); rules 30–31 alone reproduce unchanged.

| run (600 ticks unless noted) | what happens |
|---|---|
| allowed + motion, random start | flux energy 1.55M → 217k; 31 flashes at tick 600 |
| allowed + neutral, core 10 | busy ~50 ticks (10–15k flashes/tick, mostly release-only), then drains to tens–hundreds; memory ≈276k → 190k |
| same, EM on | keeps ~2.3k flashes/tick; quarks spread most (r 7.31 → 8.47) |

Confinement test, core 10, 4 seeds, 300 ticks (`seeds/summary.txt`): quark mean radius grows +0.38…+0.42 with colour strings vs +0.49…+0.53 with colour off. Consistent across seeds; strings slow spreading by about a fifth but don't confine.

Open for Jono: (1) the world drains like rule 27, so does something drive it (sun/core that keeps feeding, or no edge loss)? (2) Most flashes are release-only; is that okay as "heat"? (3) Confinement is weak; real QCD strings cost energy linearly with length, here only relax locally.
