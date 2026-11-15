# Handoff: pixel engine (updated November 12, 2026)

## Where things are

- **Code:** `main` of The-Coherence-Project, inside `origin/`. The old `engine-pixel` branch is fully merged into main.
- **Branch `front-porch`:** local and not pushed. It holds the 2026-11-11/12 session work, three commits on top of `main` (90e2b33).
- **Rules:** `RULES.md` is the running list. It is numbered in order, nothing is ever deleted, and a rule proven false is struck through with a note. The master log is still `engine-rules.txt`, outside the repo. **Rule:** nothing may change after seeing output without logging the change and the reason first.
- **Build plan:** the claude.ai doc "ORIGIN engine — missing pieces build spec" (R-A to R-E, in build order).
- **Results:** they go into the repo as data files (TSV), not only into chats.
- **Toolchain:** Zig 0.17.1. If it isn't installed, run `pip install --break-system-packages ziglang==0.17.1`, then use `python3 -m ziglang build`.
  - `zig build -Doptimize=ReleaseFast` builds the fast binary.
  - `zig build -Doptimize=ReleaseFast -Dside=96 --prefix zig-out-96` builds a 96³ lattice into its own folder.
- **Viewers:** `viewer/index.html` (3D lattice, all modes) and `viewer/engine.js` (the same engine for Node scripts). Both are JS ports that match Zig exactly for the same seed.

## Files

| File | What it is |
|---|---|
| `src/engine/pixel.zig` | Pixel, flash rule, beta-decay bookkeeping, 2D grid |
| `src/engine/clocks.zig` | Per-region clocks on the 2D grid |
| `src/engine/grid3.zig` | 3D lattice (48³ by default, 6 neighbours), carrier, rule 6 gravity, rule 21 cancel |
| `src/engine/lepton.zig` | Lepton mode, rules 7–11 |
| `src/engine/photo.zig` | Photograph mode, rules 12–16 |
| `src/engine/record.zig` | Run recorder: meta.json, series.csv, shells.csv, gaps.csv, slice.csv |
| `src/engine/onepixel.zig` | One pixel engine model from Rule Spec v0. Choices P1–P4 are in `experiments/one-pixel` and aren't numbered rules. |
| `viewer/observe.html`, `viewer/observe-core.js` | Particle observer: kinds, charge, quark groups and triplets, carriers. `scripts/observe-run.js` writes the same counts as a TSV. |
| `viewer/war.html`, `viewer/pixel.html` | War vs twin vs nudge (with Earth's real war record), and the one-pixel turn |
| `src/app/porch.html` | Front porch: the experiment menu (`origin porch`) |

## Engine commands

```
origin engine [ticks] [seed]                          # 2D, build steps 1-3
origin clocks [seed]                                  # 2D region clocks, all rule combos
origin lattice3 [display] [update] [core] [ticks] [gravity|cancel]
origin lepton [core] [ticks] [v1|signed|turing]
origin photo ...                                      # photograph mode, rules 12-16
origin record mode=lattice|v1|signed|turing|control display=.. update=.. core=.. ticks=..
              [gravity=on | feedback=reinforce|cancel] seed=.. every=..
origin pixel                                          # pixel page (quark entity, lepton points, neutrino node)
origin onepixel [start] [row|bipyramid] [nC|t ...]    # one pixel engine turn, charge ledger
origin porch                                          # experiment menu
```

The `display` options are fill_empty, hold, one_cell and flip_all; `update` is sync or sweep.

## Rules

There are 24. See `RULES.md`. 21 = R-A, 22 = R-B, 23 = R-C, 24 = PLAN-fields F-0 (motion).

**Next build plan:** `PLAN-fields.md` (every known field, steps F-0 to F-8).

## Findings

**Up to November 10** (earlier handoff):
- Steps 1–2 pass.
- 2D flip rules cohere, then freeze.
- Trigger values 3, 4 and 5 give no constant chance per tick.
- Mass shows up as a hole in the flashing, not a source.
- A point source of carrier gives 1/distance by geometry.

**Parameter sweep** (`results/sweep-2026-11-10`, 150 runs):
- No setting shows a decay-like flat hazard.
- The core is brighter than its surroundings in only 1 run (flip_all · sync · gravity · core 8, seed 2).
- v1 freezes with every pixel an electron.

**Box size** (`box-size.tsv`): the falloff trend with core size came from the box edge. On a 96³ box it nearly disappears.

**Rule 21** (`results/rule21-2026-11-12`):
- Flashing goes to 0 in every setting.
- Mass stays a hole under feedback off, reinforce and cancel.

**War experiments** (`experiments/war-history`):
- The engine is chaotic: a one-cell nudge spreads almost as far as a war.
- Earth's real war record (1400–2000) leaves the world more restless and more uniform than its twin, and that doesn't heal. In flip_all · sweep, which isn't chaotic, the wars' mark is permanent.

**Precompression analogue** (`experiments/precompression`):
- Holding 1 site in 8 fixed raises the jostling level that order survives, by +0.03 to +0.15.
- A regular cage beats random holds slightly in every setting.
- Gravity makes order more fragile.

## Build plan status (spec R-A to R-E)

| Step | Status |
|---|---|
| R-A carrier feedback | **Done** as rule 21 (cancel). Reinforcement already existed as rule 6. Not tested: whether separate regions attract or merge, because there is only a single-core start. |
| R-B exclusion | **Done** as rule 22 (same state = pattern, a blocked flash waits). It jams one_cell and flip_all within about 20 ticks, and turns hold's runaway into a steady 28–40%. |
| R-C three carriers | **Done** as rule 23 (each channel conserved separately). Neutrino pixels end up rarest and flash most; quarks don't come out dominantly strong. |
| R-D colour and confinement (protons, neutrons) | Not started. Needs R-C's strong channel. |
| R-E antiparticles | Not started. |
| Nucleus | Only after R-D, and only if it emerges. |

## Open decisions (Jono's)

1. **Source of mass:** the engine always shows it as a hole.
2. ~~Carrier feedback~~: built as rules 6 and 21. Choosing between them is still open.
3. **Carrier speed:** currently one hop per tick.
4. **Reverse stroke:** what refills memory.
5. **Lattice vs no lattice.**
6. **Five nodes:** where they sit relative to the three cells.
7. **Two-core start:** needed to test attraction under rule 21 or rule 6.
8. **The organized colour-regions result:** it lives only in a claude.ai chat. It isn't in the repo yet, so it isn't a baseline.

## Working style

- Jono is terse and direct. He wants room to think out loud, not a verdict plus next action every turn.
- Every rule change goes into `RULES.md` (and the log) **before** a run is used.
- Jono reviews locally before anything is pushed.
