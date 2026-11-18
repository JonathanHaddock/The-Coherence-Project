# Origin lab: triangulations with and without causality (2D)

**Standard physics, not origin's pixel rules.** Glue equilateral triangles into a surface and let every gluing count equally: that's 2D quantum gravity as dynamical triangulations. Two versions:

- **DT** (Euclidean): any gluing into a sphere. Monte Carlo by edge flips (fixed size, uniform measure, no degenerate edges).
- **CDT** (causal, Ambjørn & Loll [hep-th/9805108](https://arxiv.org/abs/hep-th/9805108)): triangles are glued only between consecutive time slices, so every geometry has a time order. Periodic in time and space (a torus). Monte Carlo by (2,2) swaps and (2,4)/(4,2) vertex moves, with a soft volume constraint.

Exact theory says DT gives a fractal geometry with Hausdorff dimension 4, and CDT an ordinary 2D one, dimension 2. The question tested is CDT's claim: does the causal constraint alone turn a crumpled geometry into a smooth one?

`node run.js check` (1 s), `node run.js dims 2000 40 50` (about 10 minutes); outputs in `results/`.

## Checks

- **DT stays a valid sphere triangulation** after 100 sweeps: Euler characteristic 2, every edge in exactly two triangles, neighbour tables symmetric, minimum degree 3.
- **CDT stays a valid torus triangulation** after 300 sweeps: every strip has l_t up and l_{t+1} down triangles, Euler characteristic 0, symmetric adjacency, every slice ≥ 3 vertices.
- **CDT sampler reproduces the exact entropy.** 2D CDT has 2^N configurations per triangle, to leading order (critical coupling g_c = ½ in Ambjørn & Loll). With weight e^{−ε(N−N₀)²}, the volume should settle at N₀ + ln 2/(2ε). Measured: λ_c = 0.696 ± 0.003 (ε 0.002) and 0.692 ± 0.005 (ε 0.004), against ln 2 = 0.693. Wrong acceptance factors or bookkeeping errors in the moves would land elsewhere.
- **A bug found on review:** the first draft of the CDT vertex-removal move tested "first triangle in the strip" by array index 0 when it should have used the first triangle of that kind. It was fixed on reading the code, before the first run; the consistency and entropy checks were run on the fixed version.
- **Thermalization:** at N = 16,000 the DT mean distance was still drifting after 300 sweeps (13.4 → 15.8 → 16.6 with more sweeps and another seed), so the final runs use 2,000 sweeps before measuring and 40 configurations 50 sweeps apart.

## Results (`results/dims.txt`)

Hausdorff dimension two ways: how the mean distance between points grows with size (⟨r⟩ ~ V^{1/d_H}), and how the number of points at distance r grows (n(r) ~ r^{d_H−1}, r = 3–8, largest size).

| N triangles | DT mean distance | CDT mean distance |
|---|---|---|
| 1,000 | 6.19 | 7.23 |
| 2,000 | 7.66 | 10.09 |
| 4,000 | 10.06 | 13.71 |
| 8,000 | 11.87 | 18.76 |
| 16,000 | 15.22 | 26.01 |
| **d_H from size scaling** | **3.1** | **2.2** |
| **d_H from ball growth** | **3.0** | **2.4** |

Same rule (every gluing counts equally), same moves, same sizes. Only the causal constraint differs, and the geometry changes from crumpled (d_H ≈ 3 here, heading for 4) to near-ordinary 2D (≈ 2.2). That's CDT's central claim, reproduced.

Caveats:
- DT doesn't reach 4 at these sizes. Its finite-size corrections are known to be large, and the samples are strongly autocorrelated; no error bars were estimated.
- For CDT, the time extent was scaled as T ≈ √(N/2) to keep the shape fixed. That choice nudges the size scaling toward 2; the ball-growth number (2.4) doesn't depend on it.

## What it means for origin

Origin's sync vs. sweep update order is a choice about time ordering. In this experiment, imposing a time order is the single change that turns crumpled geometry into extended space. Causality may be a structural ingredient, not just a bookkeeping choice.
