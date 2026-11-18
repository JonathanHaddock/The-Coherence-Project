# Origin lab: Dirac equation from a local rule (quantum cellular automaton)

**Standard physics, not origin's pixel rules.** Bisio, D'Ariano, Perinotti and Tosini derive free particle physics from a short list of principles: a quantum update rule that is unitary, local, the same everywhere, and the same in every lattice direction. Relativity isn't assumed ([1306.1934](https://arxiv.org/abs/1306.1934), [1601.04832](https://arxiv.org/abs/1601.04832)). The test: does relativistic physics really come out, and where does it fail?

**The 1D rule.** Each pixel holds two complex numbers, R and L. One tick:

```
R'(x) = n R(x−1) + i m L(x)
L'(x) = i m R(x) + n L(x+1)        n² + m² = 1, m = mass
```

R moves right, L moves left, and mass mixes them. In momentum space this is the paper's D_k, with cos ω = n cos k.

`node run.js` runs checks and results (`results/run.txt`, under a second).

## Checks

- **Unitarity:** the norm stays 1 to 7 × 10⁻¹⁵ over 500 ticks.
- **Strict light cone:** after t ticks nothing is ever found more than t sites from where it started.
- **The code is the paper's automaton:** plane waves for m = 0, 0.1, 0.5 at four momenta evolve with exactly cos ω = n cos k (mismatch 3 × 10⁻¹³).
- **3D:** the BCC Weyl dispersion matches its own analytic expansion ω² = |k|²/3 ± 2a_x a_y a_z (a_i = k_i/√3) in 200 random directions for both chiralities, to 2 × 10⁻⁶.

## Results

1. **Relativity at low momentum.** ω(k) matches √(k² + m²) to within 0.06% for k ≤ 2 at small mass, and exactly as k, m → 0.
2. **Wave packets move at the automaton's group velocity** (measured vs formula at k = 0.1, 0.4, 1, 2; within 0.01). They lag behind relativity at high k: at m 0.2, k 2 the packet moves at 0.976 where relativity says 0.995.
3. **Never faster than light.** The largest group velocity at m 0.2 is 0.9798 < 1, at k = π/2.
4. **Zitterbewegung appears unprompted.** A packet started in R only (a mix of positive and negative energy) jitters at 0.6105 per tick. The automaton predicts 2 arccos n = 0.6094; the Dirac equation's 2m = 0.6000. This is a hallmark of the Dirac equation, and nothing in the rule was written to produce it.
5. **3D: relativity is only approximate, and the leading error is first order.** The BCC Weyl automaton's speed depends on direction:

| \|k\| | (1,0,0) | (1,1,0) | (1,1,1) | (1,−1,1) | spread |
|---|---|---|---|---|---|
| 0.01 | 1.000000 | 0.999999 | 1.001109 | 0.998886 | 2.2 × 10⁻³ |
| 0.1 | 1.000000 | 0.999861 | 1.010867 | 0.988639 | 2.2 × 10⁻² |
| 1.0 | 1.000000 | 0.985701 | 1.089022 | 0.861539 | 2.3 × 10⁻¹ |

(ω divided by the relativistic |k|/√3.) The spread shrinks linearly with k, coming from the term 2a_x a_y a_z in ω², which has opposite sign for the two chiralities.

## What it means

- Free relativistic particles, mass, a speed limit and Zitterbewegung all come from a two-line local rule chosen by principles, not patched.
- The cost is a prediction: if the lattice is real, high-energy particles travel at slightly direction- and chirality-dependent speeds, at first order in (energy × lattice spacing). Observation already limits first-order effects of this kind tightly. Gamma-ray burst polarization gives |ξ| ≤ 2.4 × 10⁻¹⁵ for a first-order, helicity-dependent photon term ([1102.2784](https://arxiv.org/abs/1102.2784)), which is far below Planck-scale size. Whether that rules out this automaton depends on how its photons are built (D'Ariano et al. make them from pairs of Weyl fields, [1601.04842](https://arxiv.org/abs/1601.04842)). That wasn't checked here.

## Limits

- Free particles only, no interactions.
- Single-particle evolution: it's checked as a wave equation, not as a many-particle quantum field.
