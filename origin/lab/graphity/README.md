# Origin lab: geometry from cooling (classical graphity)

**Standard physics, not origin's pixel rules,** though this is the lab closest to origin's own question. Konopka, Markopoulou & Smolin ([hep-th/0611197](https://arxiv.org/abs/hep-th/0611197)) propose that space begins as a hot, fully connected graph and freezes into a regular lattice as it cools. The authors argue this but say they can't prove the lattice is the ground state. This lab tests a **classical simplification** (their model is quantum, with spin labels on edges; that isn't reproduced). It's the experiment nearest origin's idea of linking pixels by who flashed together.

Energy, with target valence 4 and loop length 4 (the square lattice):

- **Model A**, "valence + loops": degree capped at 4; E = 2Σ(4 − deg)² − (number of 4-cycles) + 2·(number of triangles).
- **Model B**, "+ manifold": E_A + Σ_edges (s_e − 2)², where s_e = squares through edge e. On any surface tiled by squares every edge borders exactly 2 squares.

Monte Carlo toggles one link at a time (Metropolis–Hastings), cooling from T = 4 to 0.02.

`node run.js` (about 2.5 minutes) → `results/run.txt`.

## Checks

- Incremental energy change = full recomputation, 300 random toggles per model.
- **The sampler reproduces the Boltzmann distribution exactly** on 5 nodes (all 1,024 graphs) at T = 4: total-variation distance 0.004 / 0.005. A separate convergence test gave 0.0094, 0.0050, 0.0024 at 2, 8 and 32 million steps: halving with each 4× steps, which is pure statistical noise, not bias. At T = 1.5 the same test gave 0.017. That turned out to be slow mixing, not a bug.

## Earlier versions that failed (kept because they're informative)

1. **No degree cap:** the energy was unbounded below. A near-complete graph has ~N⁴ four-cycles, more than any (degree − 4)² penalty can offset. Every run collapsed into a dense blob (E = −25,650 on 25 nodes). A loop reward needs a hard limit on connections, or "space" becomes one clump.
2. **4 × 4 torus as the reference:** rows that wrap round in 4 steps are extra 4-cycles, so it isn't a clean lattice. It's left out.

## Results

**1. Rewarding loops does not select space.** For 64 nodes, model A gives the square torus E = −64 but eight disconnected K₄,₄ blocks E = −288. The blocks win, because each node sits in more squares. Valence plus a loop reward prefers tight, disconnected clusters over an extended lattice. Model B reverses this: torus −64, K₄,₄ blocks +5,984.

**2. Even when the lattice is the lower state, cooling doesn't find it.**

| model | runs (N = 36, 64) | final energy vs torus | lattice-like nodes |
|---|---|---|---|
| A | 6 | −21 to −26 vs −36/−64 | 1% |
| B | 6 | −3 to +22 vs −36/−64 | 10% |
| B, 5× slower cooling | 6 | 0 to +14 vs −36/−64 | 15% |

All runs stay connected and triangle-free, but freeze into disordered graphs well above the lattice's energy, with only small patches of square lattice. Slower cooling helps a little (10% → 15%). This is glassy freezing: local link toggles can't reorganize a whole graph into one coherent lattice.

## What it means for origin

- A preference for loops of a given size isn't enough to make space; something like a manifold condition (each link borders exactly two faces) is needed even to make the lattice the lowest-energy state.
- Even then, local cooling gets stuck. If geometry is to emerge from linking pixels by who flashed together, it needs a stronger organizing principle than a local energy plus cooling. Causality (see `../triangulations`) is the one ingredient in these labs that did turn crumpled structures into extended space.

## Limits

Classical; small graphs (36–64 nodes); one family of energies, which isn't the paper's exact Hamiltonian. The torus energy is a bound, not a proven ground state of model B.
