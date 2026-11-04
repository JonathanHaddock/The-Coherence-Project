# The Identity-Differentiation Triangle

Jonathan Haddock, 2026-11-03. Supersedes the equilibrium framing in
`Lepton coherence`. Stated and tested without mass.

## Framework

The fermion entities are **nodes in a larger framework**:

- **Neutrinos** and **quarks** are the poles. A pole is unprojected: it sits
  on a single axis with nothing projected onto the others.
- **Charged leptons** sit between the poles. **All projection happens in
  them**: they are the only entity spread across more than one axis.
- Quarks are confined, so they count as one bound entity.

## Measure

Each entity is a vector of its interaction strengths per particle,

    v = (EM, weak, strong)
      = (Q^2 alpha,  alpha_Z (gL^2 + gR^2),  alpha_s C_F)

with Z couplings gL = T3 - Q sin^2(theta_W), gR = -Q sin^2(theta_W),
C_F = 4/3 for quarks and 0 for leptons. Bound quarks average up and down
types. Couplings are PDG 2024 values at a common energy.

**Projection** is the off-axis share,

    off = 1 - (largest component)^2 / |v|^2

0 means the vector lies on a single force axis (an unprojected pole).

## Results

| Entity | Dominant axis | Off-axis share | Effective forces |
|---|---|---|---|
| Neutrinos | weak | **0** (exact) | 1.00 |
| Quarks, bound | strong | **0.0003 to 0.023** | 1.05 to 1.33 |
| Charged leptons | EM or weak | **0.11 to 0.33** | 1.62 to 1.94 |

Ranges span four variants: energy scale m_Z or about 2 GeV, and weak strength
from the Z alone or Z plus W. In every variant the poles are unprojected (or
nearly) and the charged leptons carry 5 to 1000 times more projection than
either pole. Effective forces = (sum v)^2 / sum v^2.

Script and charts: `experiments/lepton-separation/` (`strengths.py`,
`poles.py`; charts 4 to 6).

## Choices that could change the numbers

- Strengths are per particle, not summed over the three quark colours.
  Summing over colours pushes quarks further onto the strong axis.
- The strong strength uses the colour factor C_F = 4/3.
- All forces are compared at one energy. Couplings run with energy: the
  strong coupling weakens and the others strengthen, so the quark pole
  becomes less pure at higher energies and the structure dissolves as the
  couplings approach unification.
- The near-1/3 lepton share in the main variant follows from the measured
  weak mixing angle; it moves to 0.11 when the W is included, so it is not
  treated as meaningful.

## How it fails

- A measured fermion property that puts projection in a pole (neutrinos
  spread across forces, or quarks with comparable non-strong interactions at
  accessible energies).
- A new fermion entity that fits neither a pole nor the projecting middle.

The result rests on measured couplings, but which axes count and how they are
weighted are modelling choices, so it is a structural description more than a
risky prediction.

## Earlier framings

**Generation-based D (no mass).** Each entity as a vector over its three
generations from the mixing matrices: neutrinos D = 0.07, bound quarks 0.63.
This cannot separate charged leptons from neutrinos: they share one mixing
matrix, and every per-generation mass-free quantity (Z branching, weak
couplings, charges) is universal, giving D ~ 0 (`lepton-separation/run.py`).
The structure appears only in force space.

**Mass: noted and abandoned.** With Koide's vector v = (sqrt m1, sqrt m2,
sqrt m3): neutrinos D 0 to 0.38 (lightest mass unmeasured), charged leptons
0.500, bound quarks 0.763. Taken at face value it would require normal
neutrino ordering and a total neutrino mass of 0.069 to 0.072 eV
(`prediction-window.png`). Abandoned because:

1. The hypothesis is about organization, not mass; mass is treated as one
   manifestation of it.
2. Neutrino masses are not measured, only their differences, so their
   position was a free parameter.
3. Quark masses depend on the renormalization scheme and scale.
4. Mass moved the claims (charged leptons became an "equilibrium"), and the
   prediction window came from cosmology limits rather than the hypothesis.

## Charts

- `experiments/lepton-separation/results/6-pole-projection.png`: off-axis
  share per entity, all variants (the main result).
- `experiments/lepton-separation/results/4-interaction-triangle.png`:
  entities in the EM / weak / strong triangle.
- `experiments/lepton-separation/results/5-effective-forces.png`: effective
  number of forces.
- `experiments/koide-projector/`: earlier generation-based and mass charts.
