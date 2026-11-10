# Handoff: pixel engine (November 10, 2026)

## Where things are

- Code is on branch `engine-pixel` in The-Coherence-Project, inside `origin/`. Four commits (this file is the fourth). Not pushed yet: the last session had no GitHub write access.
- If the branch isn't on GitHub, apply the patches in order: `git am 0001-*.patch 0002-*.patch 0003-*.patch 0004-*.patch`.
- Rules doc: `engine-rules.txt`, kept outside the repo. Its change log records every rule choice and result from November 10. **Rule:** nothing may be changed after seeing output without logging the change and the reason first.
- Toolchain: Zig 0.17.1. If it isn't installed: `pip install --break-system-packages ziglang==0.17.1`, then use `python3 -m ziglang build`.
- Build for speed: `zig build -Doptimize=ReleaseFast`. A 3D run takes about 17 seconds.
- Viewer: "Pixel Engine Viewer" artifact on claude.ai. It's a JS port of the **2D** engine and matches the Zig numbers exactly. It still has only the original fill/empty display rule; hold, one-cell and flip-all haven't been added yet.

## Files

| File | What it is |
|---|---|
| `src/engine/pixel.zig` | Pixel, flash rule, beta-decay bookkeeping, 2D grid (64×64, 4 neighbors, wrapping edges). Config: display rule, update order, start state, seed. |
| `src/engine/clocks.zig` | Per-region clocks on the 2D grid: 64 regions of 8×8. Raw count, merged count (coherent pixels flashing together count as one tick), coherence, and the correlation between coherence and clock rate. |
| `src/engine/grid3.zig` | 3D lattice (48³, 6 neighbors) plus the carrier field. |
| `src/main.zig` | Commands `engine`, `clocks`, `lattice3`. |
| `results/engine_*`, `clocks_*`, `lattice3_*` | Saved runs. |

## Commands

```
origin engine [ticks] [seed]                       # build steps 1-3, 2D, first-run rules
origin clocks [seed]                               # all rule combos, region clocks
origin lattice3 [display] [update] [core] [ticks]  # display: fill_empty|hold|one_cell|flip_all
                                                   # update: sync|sweep; core = sphere radius (0 = none)
```

## Rule choices (all logged in the doc)

1. **Display** (what a pixel shows when it flashes):
   - `fill_empty`: the first-run version, a mistranslation. Kept only to reproduce that run.
   - `hold`: B keeps its pattern and the difference goes to memory.
   - `one_cell`: B flips the one cell with the largest mismatch surplus (section 12).
   - `flip_all`: B flips every cell where mismatches outweigh matches.
2. **Trigger:** a pixel flashes when its conserved share totals 3.
3. **No memory:** a flash releases the whole conserved share and clears reinforcement.
4. **Update:** synchronous ticks or a sequential sweep.
5. **Carrier** (provisional, measurement only): released neutrino units spread one hop per tick to the 6 neighbors and are lost at the box edge. They have **no effect** on pixels yet.

There are no tuning knobs. The only number is the trigger of 3.

## Findings so far

- **Steps 1–2 pass:** charge balances in thirds, and the flash rule behaves as written.
- **2D, first-run rule:** the grid runs away (99% flashing) and neighbor agreement stays near 0.57. That's barely above 0.5, the value for two random patterns.
- **2D, correct reading (flip rules):** the grid coheres (agreement 0.83–0.92), then freezes within about 100 ticks.
- **2D, hold:** it keeps flashing but never organizes; agreement stays at exactly 0.500.
- **Trigger:** 3 runs away, 4 gives a strict two-tick rhythm, and 5 and up dies. None of these looks like a constant chance per tick.
- **Region clocks:** coherence and clock rate move opposite to each other almost everywhere (down to −1.00 with a core and hold). That follows directly from the flash rule, since matching cells add nothing to memory. It isn't independent support for section 11.
- **Falloff, 2D and 3D:** flash rate vs distance from a dense core is a step, not 1/distance.
- **3D, one-cell:** it does **not** freeze. About 5% of pixels keep flashing through 1500 ticks.
- **3D carrier:** a point source gives 1/distance, as geometry predicts. But in the engine the dense core is quiet and emits almost nothing, and the carrier comes from everywhere outside it. Mass shows up as a hole in the flashing, not a source.

## Open decisions (the user's to make)

1. **Source of mass.** Section 11 says massive regions give off *more* flashes, and every version of the engine does the opposite. Either mass isn't the coherent region, or coherent regions should flash more, for example in a single synchronized burst.
2. **Carrier feedback.** How carrier acts on pixels: adding reinforcement, cancelling memory, or something else. It has to come from geometry, with no strength knob.
3. **Carrier speed:** one hop per tick (current), the same as a flash.
4. **Reverse stroke** (section 6): what refills memory once a region has cohered.
5. **Lattice vs no lattice.** Any fixed lattice puts distance in by hand. The thesis-faithful version links pixels by which ones flashed together and measures distance by hops afterward.
6. **Five nodes:** where they sit relative to the three cells. Not in the code.

## Next checks

- Hazard table for the 3D one-cell run. Is the ongoing ~5% flashing a constant chance per tick, which decay needs?
- Neighbor agreement and region clocks on the 3D lattice. They're only measured in 2D now.
- Add hold, one-cell, flip-all and a start control to the viewer, or build a 3D slice viewer.

## Working style

- Jono is terse and direct. He wants room to think out loud, not a verdict plus next action every turn.
- Every rule change goes into the doc log **before** a run is used.
