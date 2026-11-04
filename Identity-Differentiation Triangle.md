# The Identity-Differentiation Triangle

Jonathan Haddock, 2026-11-03. Supersedes the equilibrium framing in
`Lepton coherence`.

## Hypothesis

- **Neutrinos are identity.**
- **Quarks are differentiation.** They are confined, so they count as one
  bound entity.
- **Charged leptons span the frame.** e, mu and tau are the three axes on
  which the other entities are projected.

The hypothesis is stated and tested **without mass**.

## Measure

Each entity is a 3-vector over generations, taken from the mixing matrices:
neutrinos are the columns of the lepton mixing matrix |U| (PMNS), and quarks
are the rows and columns of the quark mixing matrix |V| (CKM). The identity
projector P1 = J/3 and the differentiation projector P2 = I - J/3 split each
vector, giving

    D = (Q - 1/3) / (2/3),   Q = |v|^2 / (sum v)^2

D = 0 is pure identity (centre of the triangle), D = 1 pure differentiation
(a corner). Computed by `origin project`.

"Identity" is fixed in advance as **D <= 0.1**.

## Results (mass-free, PDG 2024)

| Entity | Vectors | D |
|---|---|---|
| Neutrinos | PMNS columns nu1, nu2, nu3 | 0.08, 0.00, 0.13, **mean 0.07** |
| Quarks, bound | CKM rows and columns | **mean 0.63** |
| Charged leptons | PMNS rows e, mu, tau | 0.15, 0.06, 0.01, mean 0.07 |

Neutrinos sit inside the identity band and quarks on the differentiation
side. **The hypothesis holds on current data.**

Limit: charged leptons and neutrinos share one mixing matrix, so mixing data
gives them the same D. That fits their roles (the frame is not a pole), but
the frame role itself is not measured by this method.

## Predictions

1. As lepton mixing is measured more precisely (JUNO, DUNE, Hyper-K: the
   theta23 octant and the CP phase), the neutrino mean D stays at or below 0.1.
2. Quark mixing stays on the differentiation side (D above 0.5).

These follow from data already in hand, so they are weak tests. A strong test
needs a mass-free observable that separates charged leptons from neutrinos.

## Mass: noted and abandoned

Mass was used first, through Koide's vector v = (sqrt m1, sqrt m2, sqrt m3).
Those results are recorded here for completeness:

| Entity | D from mass |
|---|---|
| Neutrinos | 0 to 0.38, depending on the unmeasured lightest mass |
| Charged leptons | 0.500 |
| Quarks, bound (u+d, c+s, t+b) | 0.763 |

Taken at face value, mass would require neutrinos to have normal mass ordering
and a total mass of 0.069 to 0.072 eV (`prediction-window.png`).

**Reasons for abandoning mass:**

1. **The hypothesis is about organization, not mass.** The working premise
   from `Lepton coherence` is that Q measures organizational structure and
   mass is one manifestation of it. Using mass as the measure makes the test
   depend on the thing the hypothesis says is secondary.
2. **Neutrino masses are not measured.** Only their differences are. Placing
   neutrinos by mass meant choosing the lightest mass, which made their
   position a free parameter rather than a result.
3. **Quark masses are not uniquely defined.** They depend on the
   renormalization scheme and scale, so quark D from mass shifts with that
   choice.
4. **Mass moved the claims.** With mass, charged leptons sit at D = 1/2
   (equilibrium); without it, the picture is two poles and a frame. The
   mass-based prediction window also came from cosmology limits rather than
   from the hypothesis itself.

## Charts

- `experiments/koide-projector/triangle.png`: mixing vectors in the triangle
  (mass-free, the basis of the results above).
- `experiments/koide-projector/three-entities.png`: D by mass and by mixing.
- `experiments/koide-projector/lepton-frame.png` and `prediction-window.png`:
  the abandoned mass-based picture, kept for the record.
