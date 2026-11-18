# Origin lab: U(1) photon (emergent light)

**Standard physics, not origin's pixel rules.** Compact U(1) lattice gauge theory: each link holds one angle (a phase), and the action is β Σ (1 − cos θ_plaquette). This is the theory that Levin & Wen's rotor model ([hep-th/0507118](https://arxiv.org/abs/hep-th/0507118)) reduces to. Their "string-net condensed" vacuum is the **Coulomb phase** here, where a massless photon exists and charges feel a 1/R potential. Their uncondensed vacuum is the **confined phase**, where charges are bound by a linear potential. The question tested: does a grid of local phases on links really produce light?

Files: `u1.js` (model, any dimension), `check.js`, `run.js` (phase scan, potential), `freefield.js` (control: the free photon in the same box), `results/`.

## Checks (`node check.js`, 2026-11-18)

| Check | Result |
|---|---|
| 2D is solved exactly: ⟨cos θ_p⟩ = I₁(β)/I₀(β) | β 0.5, 1, 2, 4: 0.2430/0.2425, 0.4464/0.4464, 0.6987/0.6978, 0.8630/0.8635, all within 4 block errors |
| 2D Wilson loops = (I₁/I₀)^area exactly | W(1,1), W(2,1), W(2,2), W(3,2) all within 0.3% |
| Gauge invariance (random phase at every site) | plaquette, W(2,2), smoothed W(2,2) change by 4 × 10⁻¹⁷ |
| 4D strong coupling ⟨cos⟩ ≈ β/2 | β 0.1: 0.047; β 0.2: 0.098 |
| 4D weak coupling ⟨cos⟩ ≈ 1 − 1/(4β) | β 8: 0.9683 vs 0.9688; β 16: 0.9842 vs 0.9844 |

The first version had a sign error in the backward staple. The 2D exact test is what caught it, before any run was used.

## Results

**1. A phase transition** (`phase-scan.tsv`, 6⁴): the plaquette jumps from 0.579 at β 1.00 to 0.656 at β 1.01, and cold and hot starts disagree most there. The literature puts the 4D compact U(1) transition near β ≈ 1.01 (first order). The location here matches that commonly quoted value; the source wasn't rechecked in this session.

**2. Two kinds of vacuum** (`potential-b*.txt`, 10⁴, 10 APE steps, 60 measurements, V from T 2→3, jackknife errors):

| β | phase | aV(R), R = 1…5 | fit |
|---|---|---|---|
| 0.9 | confined | 0.742, 1.442, 1.83, (signal lost) | V rises ~0.7 per step: string tension σa² ≈ 0.7 |
| 1.1 | Coulomb | 0.229, 0.292, 0.315, 0.327, 0.334 | σa² = 0.002 ± 0.001, e = 0.122 ± 0.003 |
| 1.5 | Coulomb | 0.140, 0.177, 0.192, 0.199, 0.204 | σa² = 0.001 ± 0.000, e = 0.073 ± 0.002 |

**3. Control: the free photon in the same box** (`freefield-L10.txt`). A massless photon on a periodic 10³ box, fitted the same way, gives σa² = −0.002 and e = 0.083 (β 1.1) / 0.061 (β 1.5). So:
- In the Coulomb phase the string tension is zero to within about 0.004. The potential flattens like 1/R. That's what a massless photon does: **light emerges**.
- The measured Coulomb strength is larger than the free photon's by 1.48× at β 1.1 and 1.20× at β 1.5. That's the expected renormalization of the charge by the compact field's fluctuations. It shrinks as β grows, as it should.
- In the confined phase, the same grid gives a linear potential instead. One parameter (β) moves the vacuum between "light exists" and "charges are confined".

## Limits

- Euclidean Monte Carlo: this gives the vacuum's static properties (which phase, which potential), not real-time photon propagation.
- Small boxes. Near the transition, 6⁴ is too small to tell first from second order.
- No dynamical charges. Wen's emergent *electrons* (fermions from bosons) are tested in the string-net lab, not here.
