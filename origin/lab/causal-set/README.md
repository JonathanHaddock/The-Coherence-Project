# Origin lab: causal sets (random vs regular)

**Standard physics, not origin's pixel rules.** In causal set theory, spacetime is a set of points with only a before/after order, and geometry is read off by counting ([Dowker, Henson & Sorkin, gr-qc/0311055](https://arxiv.org/abs/gr-qc/0311055)). Points are sprinkled **at random** (Poisson) because, they argue, that keeps relativity and a regular lattice can't. This bears directly on origin's open decision #5, lattice vs. no lattice. Everything here is 1+1 dimensional, in light-cone coordinates u = t + x, v = t − x. A boost is u → e^η u, v → e^−η v.

`node run.js` runs checks and results in about 3 seconds (`results/run.txt`).

## Checks

- Link counting (relations with nothing in between) matches brute force exactly on 5 random sets of 120 points.
- Longest chain matches brute-force dynamic programming on 20 random sets of 200 points.
- A boost preserves the order exactly: chain length and link count unchanged at rapidity 2.3.

## Results

**1. Seen from a moving observer.** Points at density 1 are counted in 2 × 2 boxes (4 expected per box) in a frame moving at rapidity η. A Poisson process has variance/mean = 1 and about 1.8% empty boxes in every frame.

| η | random: var/mean | random: empty | lattice: var/mean | lattice: empty |
|---|---|---|---|---|
| 0 | 1.04 | 3.0% | 0.17 | 0% |
| 1 | 1.01 | 1.5% | 1.26 | 4.5% |
| 2 | 0.99 | 2.0% | 9.93 | 62% |
| 3 | 1.07 | 2.2% | 43.2 | 88% |

The random sprinkling looks statistically identical from every frame. The lattice is perfectly even at rest, but to a fast-moving observer it falls apart into dense lines and empty gaps: it has a preferred frame.

**2. Geometry from order and counting alone.** The longest chain between two points (the proper time) in an interval holding N points:

| N | longest chain | L/√N | theory 2√N − 1.771 N^{1/6} |
|---|---|---|---|
| 1,000 | 57.5 ± 0.4 | 1.818 | 57.6 |
| 10,000 | 193.4 ± 0.7 | 1.934 | 191.8 |
| 100,000 | 621.8 ± 1.2 | 1.966 | 620.4 |

L/√N approaches 2, the known constant; the finite-size correction is the Tracy–Widom term from the longest-increasing-subsequence problem. At 10⁴ the measured value sits 2σ above the two-term formula; higher-order terms aren't included.

**3. The cost: nonlocality.** Nearest causal neighbours (links) to the future, per point:

| N | 500 | 1,000 | 2,000 | 4,000 | 8,000 | 16,000 |
|---|---|---|---|---|---|---|
| links | 4.75 | 5.53 | 6.13 | 6.89 | 7.57 | 8.23 |

On the lattice it's exactly 2. In the random set it grows as 1.00 × ln N, without limit: each point has "nearest" neighbours spread along its whole light cone, arbitrarily far away. Lorentz invariance is bought with an unbounded neighbourhood.

## What it means for origin

Any fixed grid, including origin's 48³ lattice, picks out a rest frame. A random set doesn't, but then "neighbour" stops meaning "nearby", and a local update rule has nothing natural to act on. Origin's non-spatial neutrino delivery (rules 15–16) and the idea of linking pixels by who flashed together are both moves in this direction.

## Limits

1+1 dimensions only; kinematics only. No dynamics for the causal set itself.
