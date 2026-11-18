# Origin lab: lattice QCD (pure gauge SU(3))

A separate area of origin. **Standard physics, not origin's pixel rules.** The gluon field of QCD on a small 4D grid of space and time, updated the way real lattice QCD is done, at toy size. It's here as the reference case: a known, working example of "the world built from local units on a grid" to hold origin's pixel engine up against.

## What it is

- A periodic grid of Ns³ × Nt sites. The fourth direction is time, and a short time direction means a hot box: temperature T = 1/(Nt a).
- The gluon field lives on the **links** between neighbouring sites, not on the sites. Each link holds a 3×3 special unitary matrix U (an SU(3) colour rotation): the instruction for how colour changes when you step from one site to the next.
- Wilson action: S = β Σ (1 − Re Tr P / 3), where P is the product of the four links around one unit square (a plaquette). β = 6/g², with g the bare strong coupling. Large β = weak coupling = fine lattice.
- Configurations are sampled with weight e^−S by Metropolis updates (10 hits per link, steps drawn from a fixed set of SU(3) matrices near the identity, links re-projected onto SU(3) after every update).
- No quarks move (the "quenched" or pure-gauge theory). Quarks enter only as static test charges in the Wilson and Polyakov loops.

Units: lattice spacing a = 1.

## Run it

- **Watch:** open `index.html` in a browser. Presets: *confined* (6⁴, β 5.7) and *hot plasma* (6³ × 2, β 6.0).
- **Check:** `node check.js` (about 5 s).
- **Experiment:** `node run.js Ns=8 Nt=8 beta=5.7 therm=500 meas=200 every=5 loops=3 header=1` prints one TSV row: plaquette, Polyakov loop, Wilson loops W(R,T), Creutz ratios, each with a standard error. `results/commands.txt` has the commands behind every file in `results/`.

| File | What it is |
|---|---|
| `su3.js` | SU(3) matrices, the lattice, Metropolis update, all measurements (browser and node) |
| `check.js` | Unitarity, gauge invariance, strong- and weak-coupling limits, cold/hot start agreement |
| `run.js` | Command-line runner, one TSV row per run |
| `index.html` | Live page: action density slice, plaquette history, Polyakov loop cloud, Wilson loop area plot |

## What it measures

| Quantity | Meaning |
|---|---|
| Plaquette ⟨Re Tr P/3⟩ | The basic number every lattice code reports. Goes from 0 (β → 0) to 1 (β → ∞) |
| Wilson loop W(R,T) | A static quark and antiquark held R apart for time T. **Area law** W ~ e^(−σRT) = the energy between them grows linearly with distance = confinement |
| Creutz ratio χ(R) = −ln[W(R,R) W(R−1,R−1) / W(R,R−1)²] | Cancels the perimeter and constant parts of −ln W. Approaches the string tension σa² from above as R grows |
| Polyakov loop ⟨L⟩ | Tr of the time links all the way round the box, /3. It measures the free energy of one isolated quark. ⟨L⟩ = 0: confined. ⟨L⟩ ≠ 0, pointing along one of three Z₃ directions: deconfined (gluon plasma) |

## Checks passed (2026-11-18)

`node check.js`:

- **Unitarity:** after 20 sweeps from a random start, the largest |UU† − 1| over all links is 8.9 × 10⁻¹⁶.
- **Gauge invariance:** a random SU(3) rotation at every site changes the plaquette, W(2,2), a spatial W(1,2) and |⟨L⟩| by at most 5.6 × 10⁻¹⁷. This is the central symmetry of QCD; a wrong link direction or a wrong order of multiplication breaks it.
- **Strong coupling** (β small, where ⟨P⟩ ≈ β/18 + β²/216): β 0.5 gives 0.0277 vs 0.0289; β 1.0 gives 0.0592 vs 0.0602.
- **Weak coupling** (β large, where ⟨P⟩ ≈ 1 − 2/β): β 30 gives 0.9322 vs 0.9333; β 60 gives 0.9663 vs 0.9667.
- **Cold and hot starts agree** at β 5.5 after 400 sweeps: 0.5084 and 0.5021. (After only 80 sweeps they didn't: 0.5109 vs 0.5003. Metropolis is slow near β 5.5, so runs use 400+ thermalization sweeps.)

## Results (2026-11-18)

### Plaquette, 8⁴ (`results/plaquette-scan.tsv`)

| β | 5.0 | 5.4 | 5.6 | 5.7 | 5.8 | 6.0 | 6.2 | 6.4 |
|---|---|---|---|---|---|---|---|---|
| ⟨P⟩ | 0.3999 | 0.4709 | 0.5238 | 0.5486 | 0.5672 | 0.5944 | 0.6131 | 0.6307 |

Errors are about 0.0003. The values commonly quoted for large lattices are about 0.549 at β 5.7 and 0.594 at β 6.0; these still need checking against a primary table. On an 8⁴ box the plaquette at these β is close to its large-volume value.

### Confinement: Wilson loops, 8⁴ (`results/wilson-loops.tsv`)

| β | W(1,1) | W(2,1) | W(2,2) | W(3,2) | W(3,3) | χ(2) | χ(3) |
|---|---|---|---|---|---|---|---|
| 5.7 | 0.54968 | 0.32557 | 0.13312 | 0.05811 | 0.02014 | 0.371 | 0.231 |
| 6.0 | 0.59437 | 0.38504 | 0.19222 | 0.10363 | 0.04898 | 0.261 | 0.132 |

−ln W rises with the area of the loop. The Creutz ratios fall as R grows, as they should, towards the string tension, but at R = 3 they still include short-distance (Coulomb) parts. The literature value of σa² is roughly 0.16 at β 5.7 and 0.05 at β 6.0 (from the Sommer scale r₀; not yet checked against the source here). Getting there takes larger loops, a bigger box and smoothing of the links, none of which is built.

### Deconfinement: Polyakov loop, 8³ × 4 (`results/deconfinement.tsv`)

| β | 5.40 | 5.50 | 5.60 | 5.65 | 5.70 | 5.75 | 5.80 | 5.90 | 6.00 |
|---|---|---|---|---|---|---|---|---|---|
| \|⟨L⟩\| | 0.017 | 0.020 | 0.029 | 0.046 | **0.139** | 0.171 | 0.182 | 0.230 | 0.248 |

The Polyakov loop jumps between β 5.65 and 5.70. The published critical coupling for the Wilson action at Nt = 4 is **β_c = 5.6925(2)** (table 1 of [hep-lat/9405018](https://arxiv.org/abs/hep-lat/9405018), from earlier Wilson-action studies). The 8⁴ scan, with Nt = 8, stays confined over the whole range (|⟨L⟩| ≤ 0.03), since that box is twice as cold.

Below β_c, |⟨L⟩| is not exactly zero on a finite box: it's noise of size about 1/√(number of spatial sites).

## Limits

- Pure gauge: no dynamical quarks, so no pions, no chiral symmetry breaking, no real hadron masses.
- Toy volumes (up to 8⁴) and a simple Metropolis update. Real studies use heat-bath plus over-relaxation, volumes of 32⁴–96⁴ and more, and many independent configurations.
- Errors treat measurements `every` sweeps apart as independent; autocorrelations aren't measured.

## Why it's in origin

Lattice QCD is the working example of matter's strongest force computed from local units on a grid. Three things in it bear directly on the pixel engine:

1. **The field lives on links, not sites.** Rule 28 (fields on links) is the same move.
2. **Gauge invariance.** Only closed loops are physical; a single link's value means nothing, because a rotation at each site changes it freely. The check above tests this to 10⁻¹⁷.
3. **The lattice is a tool, not a claim.** Results are taken to the continuum limit a → 0 (β → ∞) and must stop depending on the grid. A pixel world that claims the grid is real has to explain why that limit looks like the one QCD reaches.
