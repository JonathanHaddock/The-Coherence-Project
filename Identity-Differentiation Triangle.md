# The Identity-Differentiation Triangle

Jonathan Haddock, 2026-11-03. Supersedes the equilibrium framing in
`Lepton coherence`. Stated and tested without mass.

## Framework: selection

The fermion entities are **nodes in a larger framework**, distinguished by
**selection**: which forces each one engages. Selection is a **fixed
property** of each entity, not a process.

- **Neutrinos** and **quarks** are the selective poles. Each commits to a
  single force: neutrinos to the weak force, quarks (dominantly) to the
  strong force.
- **Charged leptons** are the third point, the non-selective node. They are
  the only entity that engages two forces (electromagnetism and the weak
  force) at comparable strength, and they are the constraint that closes the
  triangle.
- Quarks are confined, so they count as one bound entity.

The triangle's vertices are the three entities: neutrinos at the weak corner,
quarks at the strong corner, charged leptons toward the electromagnetic
corner.

Earlier versions of this note described the same structure as
"projection" (poles unprojected, charged leptons carrying the projection).
That was an analogy; selection is the intended concept.

## Two levels: selection and weighting

**Selection (which forces): exact.** In physics, which forces a particle can
engage is fixed by its charges: electric charge selects electromagnetism,
weak isospin selects the weak force, colour selects the strong force. A zero
charge makes the force unavailable. These are selection rules: exact, with no
dependence on energy, convention or measurement precision.

| Entity | Electric charge | Weak isospin | Colour | Forces selected |
|---|---|---|---|---|
| Neutrinos | 0 | yes | no | weak (1) |
| Charged leptons | -1 | yes | no | EM + weak (2) |
| Quarks, bound | 2/3, -1/3 | yes | yes | EM + weak + strong (3) |

**Weighting (how strongly): measured, convention-dependent.** Each entity's
interaction strengths per particle,

    v = (EM, weak, strong)
      = (Q^2 alpha,  alpha_Z (gL^2 + gR^2),  alpha_s C_F)

with Z couplings gL = T3 - Q sin^2(theta_W), gR = -Q sin^2(theta_W),
C_F = 4/3 for quarks and 0 for leptons; bound quarks average up and down
types; PDG 2024 couplings at a common energy. Two measures of how selective
the weighting is:

- **Selectivity** S = 1 - H(p) / ln 3, with p = v / sum(v) and H the
  Shannon entropy. S = 1: one force only. S = 0: all three equally.
- **Off-dominant share** = 1 - (largest component)^2 / |v|^2: how much of
  the entity's strength lies outside its main force.

## Results

| Entity | Main force | Selectivity S | Off-dominant share | Effective forces |
|---|---|---|---|---|
| Neutrinos | weak | **1.00** (exact) | **0** (exact) | 1.00 |
| Quarks, bound | strong | **0.59 to 0.89** | 0.0003 to 0.023 | 1.05 to 1.33 |
| Charged leptons | EM or weak | **0.38 to 0.48** | 0.11 to 0.33 | 1.62 to 1.94 |

Ranges span four variants: energy scale m_Z or about 2 GeV, and weak strength
from the Z alone or Z plus W. In every variant neutrinos are perfectly
selective, quarks highly selective, and charged leptons the least selective.
Effective forces = (sum v)^2 / sum v^2.

Scripts and charts: `experiments/lepton-separation/` (`strengths.py`,
`poles.py`, `selectivity.py`; charts 4 to 7).

## Choices that could change the numbers

These affect the weighting only; the selection pattern is exact.

- Strengths are per particle, not summed over the three quark colours.
  Summing over colours makes quarks even more selective.
- The strong strength uses the colour factor C_F = 4/3.
- All forces are compared at one energy. Couplings run with energy: the
  strong coupling weakens and the others strengthen, so quarks become less
  selective at higher energies and the weighting structure dissolves as the
  couplings approach unification.

## Charged leptons as the third point and the constraint

**Third point.** In the main variant two-thirds of the charged-lepton
interaction strength is electromagnetic, so they occupy the EM side of the
triangle and no corner is empty. Two caveats:

- They are not selective like the poles: they divide themselves between two
  forces.
- Their main force depends on the weak definition: EM with the Z alone, weak
  with Z plus W.

**Constraint.** Within each generation the electric charges must sum to zero
for the Standard Model to be consistent (gauge anomaly cancellation):

| | Charge | Copies (colours) | Total |
|---|---|---|---|
| Neutrino | 0 | 1 | 0 |
| Up quark | +2/3 | 3 | +2 |
| Down quark | -1/3 | 3 | -1 |
| **Charged lepton** | **-1** | 1 | **-1** |
| **Sum** | | | **0** |

The quarks alone leave +1; the charged lepton is exactly what cancels it.
The other anomaly conditions (hypercharge cubed, mixed gravitational) also
close only with leptons and quarks together. So the charged lepton's charge
is fixed by the quarks, and the neutrino (charge 0) takes no part in the
balance. This is measured: atoms are neutral because the electron's charge
cancels the proton's, confirmed to better than about 1 part in 1e21. This is
standard Standard-Model structure, so it supports the framework without
being a new prediction. It replaced an earlier open question (an empty EM
corner, which would have required an EM-only fermion).

**One division, held identically by three particles.** Each charged lepton
divides itself between EM and weak in the same proportion; the 1/3
off-dominant share is not split among them. From each lepton's own Z
couplings measured at LEP/SLD (PDG 2024):

| Charged lepton | g_V | g_A | Off-dominant share |
|---|---|---|---|
| Electron | -0.03817 | -0.50111 | 0.3353 +- 0.0006 |
| Muon | -0.0367 | -0.50120 | 0.3353 +- 0.0010 |
| Tau | -0.0366 | -0.50204 | 0.3368 +- 0.0011 |

The three agree within errors (lepton universality). They sit slightly above
1/3 because measured couplings include radiative corrections, corresponding
to the effective weak angle rather than the MS-bar one.

- **By force** the three are identical; selection treats them as one.
- **By mass** they are maximally distinct (Koide Q = 2/3, D = 1/2). Mass is
  the only thing that separates them.

This also explains why the generation-based D cannot separate charged
leptons from neutrinos without mass: within a family, generations differ only
by mass.

## Predictions

1. **Neutrinos stay perfectly selective.** No electromagnetic coupling
   beyond the Standard Model's minimal amount: no neutrino magnetic moment
   above about 1e-19 Bohr magnetons, and no electric charge. Current limits
   are about 6e-12 Bohr magnetons (XENONnT, LZ). A detected moment above the
   Standard Model level would make a pole engage a second force and falsify
   the framework. Limitation: the Standard Model predicts the same null
   result, so continued nulls support the framework without distinguishing
   it.

2. **Charged-lepton off-dominant share of exactly 1/3 (tested: consistent
   with coincidence).** In the main variant the share is 0.3333. Exactly 1/3
   requires sin^2(theta_W) = 0.231246 in the MS-bar scheme at m_Z; measured
   0.23129 +- 0.00004 (PDG 2024, 1.1 sigma). It fails other definitions of
   the angle (effective leptonic 0.23161: 9.1 sigma; on-shell 0.22348:
   78 sigma), and holds only at one energy because the angle runs: measured
   values are 0.2349 (2.4 MeV), 0.2382 (157 MeV) and 0.2403 (161 MeV), see
   `experiments/weak-angle/running.png`. It was found after looking at four
   variants and several "nice" fractions. If staked as a claim, FCC-ee would
   test it at about ten times current precision. Computed by `origin weak`.
   Under the selection framing this is a secondary property: how evenly the
   one non-selective node divides itself between the two forces it selects.
   A look-elsewhere test (see "Is the 1/3 a signal?" below) finds a match
   like this arises by chance in about 7% of cases and holds only in the
   MS-bar convention, so it is recorded as a likely coincidence.

Not predictions: quarks become less selective at higher energies and the
weighting structure dissolves near coupling unification (standard running,
which sets the framework's range rather than testing it); sterile neutrinos
select no force and would sit outside the framework.

## Why 1/3, and why at the Z mass

**Why the Z mass (supported by data).** Running sin^2(theta_W) away from
m_Z, the charged-lepton share equals 1/3 at **mu = 90.4 +- 0.7 GeV**
(one-loop running, approximate). Of the meaningful scales nearby, only the
Z mass is consistent:

| Scale | GeV | Share | Pull from rule |
|---|---|---|---|
| W mass | 80.4 | 0.3343 | 14.7 sigma |
| **Z mass** | **91.2** | **0.3333** | **1.1 sigma** |
| Higgs mass | 125.2 | 0.3307 | 41 sigma |
| top mass | 172.6 | 0.3283 | 81 sigma |
| Higgs field v | 246.2 | 0.3256 | 126 sigma |

So if the rule is real, the data picks out the Z mass on its own.
(`experiments/weak-angle/which_scale.py`, `which-scale.png`.) Physical
reasons the Z mass is the natural scale:

1. **The Z is the one interaction all three entities select.**

   | Force carrier | Neutrinos | Charged leptons | Quarks |
   |---|---|---|---|
   | Photon (EM) | no | yes | yes |
   | Gluon (strong) | no | no | yes |
   | W (charged weak) | yes | yes | yes, changing particle type |
   | **Z (neutral weak)** | **yes** | **yes** | **yes** |

   The Z is the only interaction every entity engages without changing what
   it is: the shared link between the two selective poles and the
   non-selective node. Its mass is where it exists as a real particle.

2. **EM and the weak force stop interfering at the Z mass.** In
   electron-positron collisions the photon and Z routes interfere, with an
   interference term proportional to (s - m_Z^2), which vanishes exactly at
   the Z mass. Below it EM dominates; at it the Z process is about 200 times
   the photon process with no mixing between them. So m_Z is the one energy
   where EM and the weak force act on charged leptons without interfering:
   the clean place to define how the charged lepton divides itself between
   them.

Also relevant: the weak mixing angle is the rotation that builds the photon
and the Z from the two underlying fields (m_W^2 / m_Z^2 = 1 - sin^2(theta_W)
in the on-shell definition), and at the Z mass LEP counted the light
neutrino generations from the Z's decay width (N = 2.996 +- 0.007).

These make the Z mass non-arbitrary for the framework, but none of them
produces the 1/3. Reason 2 is the closest to a mechanism: it explains where
the division should be defined, not why it is 1/3 there.

**Why 1/3 (open).** No derivation. Candidates:

1. Koide's complement: 2/3 on the main force, mirroring Koide's 2/3.
2. The cube-diagonal angle: a 1/3 share corresponds to a 35.26 deg tilt from
   the EM axis, the complement of the angle (54.74 deg) between (1,1,1) and
   any axis, where cos^2 = 1/3.
3. One over the number of forces or of generations (both 3).

Ruled out: grand unification (sin^2 = 3/8 gives a share of 0.3077), and a
simple closed form (the rule needs
s = ((sqrt2 + 1) - sqrt(sqrt2 - 1)) / (2 (2 sqrt2 + 1)) = 0.231246).

**Refraction (considered for candidate 2).** Not a literal cause:
refraction needs light crossing a boundary between media, and the 1/3 is a
ratio of a particle's couplings, with no light, boundary or medium. The
geometry matches exactly, though: for a medium of index sqrt2 the Brewster
angle is arctan(sqrt2) = 54.74 deg and the refracted ray travels at
35.26 deg. The match exists because 54.74 deg is the "magic angle", which
appears wherever three equal directions are averaged (the 3D average of cos^2
is 1/3; NMR magic-angle spinning; Brewster refraction at index sqrt2).
Refraction shares the source of the 1/3 rather than explaining it. The
related real physics is that the weak mixing angle is a rotation, like a
polarization rotation.

**Generations (explored).** The 1/3 equals 1/N_gen, and the charged-lepton
weak^2/EM^2 = 0.4998 +- 0.0001 sits on 1/(N_gen - 1) = 1/2 (up quarks 3.29,
down quarks 87.5). Every existing generation does act on the weak angle: in
the running from m_Z to zero energy (one loop, reproduces s^2(0) = 0.2384 vs
SM 0.23873) generations contribute 48%, 40% and 13% of the fermion shift,
unequal only because of their masses; without mass each would contribute
exactly 1/3. Each complete generation pulls the angle toward 3/8, the
grand-unification value (charged lepton alone 1/4, up quark 3/8, down quark
3/4). But the generation count cancels from the one-loop grand-unification
prediction of the angle's value, and random averaging over three directions
scatters by 0.17, far too broad for a 1/3 measured to 0.0001. So averaging
reproduces the number but not the mechanism.
(`experiments/generation-averaging/`.)

**Is the 1/3 a signal? (tested: likely coincidence).** Sixteen reasonable
measures of the charged lepton's EM/weak division at m_Z were compared with
simple numbers (fractions with denominator up to 6, and common roots):

- Only three land within 2 sigma, and they are one fact written three ways:
  weak/EM strength = 0.70699 (1/sqrt2), its square 0.49984 (1/2), and the
  squared share 0.33326 (1/3). The underlying statement is that at the Z
  mass a charged lepton couples to the Z with 1/sqrt2 of the strength it
  couples to the photon.
- The other 13 measures (linear shares, including the W, vector/axial
  ratio, left-right asymmetry, lepton/neutrino ratio) miss by 19 to 2000
  sigma.
- For random weak angles in [0.20, 0.26] at the same precision, at least
  one of the 16 measures hits a simple number in **about 7%** of cases. That
  is not rare enough to count as evidence, and it understates the chance
  because more measures and targets could have been tried.
- The match holds only in the MS-bar convention. In the effective couplings
  closest to what LEP measured, the electron gives 0.3353, about 9 sigma
  from 1/3. A law of nature should hold for physical quantities.
- No algebraic structure: the required angle 0.231246 has no clean closed
  form, unlike symmetry-based values (3/8, 1/4). The nearest structural
  relation, a charged-lepton Z coupling of exactly half the neutrino's (true
  at sin^2 = 1/4), misses by 234 sigma (measured 0.5028).

Conclusion: the 1/3 is most likely a coincidence of the MS-bar convention at
the Z mass. (`experiments/weak-angle/why_one_third.py`, `why-one-third.png`.)

**Open question, if it were real:** a symmetry tying the 1 + 2 split of
generation space to how the non-selective node divides itself between EM and
the weak force, at the Z mass. The Standard Model contains no such link. The
test above makes this unlikely to be needed.

## How it fails

- A measured property that makes a pole engage a second force at accessible
  energies (neutrinos with EM coupling, or quarks with comparable non-strong
  interactions).
- A new fermion entity that fits neither a selective pole nor the
  non-selective middle.
- A neutrino magnetic moment or charge detected above the Standard Model
  level (prediction 1).
- A measured imbalance between electron and proton charge (matter not
  exactly neutral), which would break the charged lepton's role as the
  constraint.

The selection pattern is exact Standard-Model structure; the weighting rests
on measured couplings with modelling choices. The framework is a structural
description more than a risky prediction. Its one sharp numerical claim
(prediction 2, the 1/3) tested as a likely coincidence, so the framework's
solid ground is the exact part: the selection pattern and the
charge-balancing constraint.

## Earlier framings

**Projection (analogy).** The same results were first described as
projection: poles "unprojected", charged leptons "carrying all the
projection", measured by the off-dominant share. Replaced by selection,
which names the property directly.

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

- `experiments/lepton-separation/results/7-selectivity.png`: selectivity per
  entity, all variants (the main result).
- `experiments/lepton-separation/results/6-pole-projection.png`:
  off-dominant share per entity.
- `experiments/lepton-separation/results/4-interaction-triangle.png`:
  entities in the EM / weak / strong triangle.
- `experiments/lepton-separation/results/5-effective-forces.png`: effective
  number of forces.
- `experiments/weak-angle/`: measured running of the angle and the Z-mass
  scale scan.
- `experiments/generation-averaging/`: generation tests and per-generation
  running.
- `experiments/koide-projector/`: earlier generation-based and mass charts.
