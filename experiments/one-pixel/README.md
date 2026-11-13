# One pixel engine

This is a model of a single pixel's inside, built from **Pixel Engine — Rule Spec v0** (sections 2–4 and 12). It is build-order step 1: one pixel has to reproduce the beta-decay bookkeeping, meaning charges balance and each event has three flashes.

## What it models (from the spec)

- **Cells:** three cells bounded by nodes. They sit on the lepton points (e, μ, τ), which together form the display field.
- **Pixel kind:** the filled-cell count names the pixel. 0 is a neutrino, 1 a down quark, 2 an up quark, 3 an electron.
- **Scaffold:** the up/down quark scaffold sits at the south pole and changes the pattern.
- **Electron:** displays the pattern.
- **Neutrino:** conserves what isn't displayed. It is the pixel's memory and cycles through flavors.
- **One beta decay is one turn of the engine:**
  1. The quark flash flips one cell, down → up (−1/3 → +2/3).
  2. The electron flash carries −1.
  3. The neutrino flash carries 0.

  Five nodes fire per turn. The charge ledger (pixel plus everything emitted) stays constant.
- **Trigger:** comes from outside. Only a down pixel can turn.

## Choices made here (log them in the spec before using any result)

- **P1, node layout.** A switch, because node placement is open in the spec's section 9:
  - `row`: 4 cell-boundary nodes plus the south-pole scaffold node S.
  - `bipyramid`: 3 corner nodes plus N and S.
- **P2, which cell flips.** The scaffold flips the empty cell holding the most neutrino memory, lowest index on ties.
- **P3, flavor.** The neutrino flavor steps e → μ → τ with each neutrino flash.
- **P4, passing neutrinos.** A neutrino passing through adds memory to one cell but doesn't trigger a turn.
- **Nodes per flash:** the quark flash fires S, the electron flash fires the two nodes bounding the flipped cell, and the neutrino flash fires the remaining two.

## Open (not modelled)

- The reverse stroke: gravity winding up → down.
- How μ and τ "fall back to the electron".
- π at one ninth in the scaffold.

## Run

From `origin/`:

```sh
zig-out/bin/origin onepixel 100 row n2 t     # start down, neutrino passes cell 2, outside trigger
zig-out/bin/origin onepixel 100 bipyramid t
```

Viewer: `origin/viewer/pixel.html`. It animates the three flashes, and the "engine" view fires all five nodes as one event.
