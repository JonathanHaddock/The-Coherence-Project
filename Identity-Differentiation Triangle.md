# The Identity-Differentiation Triangle

Jonathan Haddock, 2026-11-03. Predictions recorded before testing against
future data. Supersedes the equilibrium framing in `Lepton coherence`.

## Hypothesis

- **Neutrinos are identity.**
- **Quarks are differentiation.** They are confined, so they count as one
  bound entity (each generation's pair merged: u+d, c+s, t+b).
- **Charged leptons span the frame.** e, mu and tau are the three axes on
  which the other entities are projected.

## Measure

Each entity is a 3-vector over generations, v = (sqrt m1, sqrt m2, sqrt m3).
The identity projector P1 = J/3 and the differentiation projector
P2 = I - J/3 split it, giving

    D = (Q - 1/3) / (2/3),   Q = |v|^2 / (sum v)^2

D = 0 is pure identity (centre of the triangle), D = 1 pure differentiation
(a corner). Computed by `origin koide` and `origin project`.

"Identity" is fixed in advance as **D <= 0.1** (charged leptons are at 0.50,
bound quarks at 0.76).

## Current values

| Entity | D | Status |
|---|---|---|
| Neutrinos | 0 to 0.38 | depends on unmeasured lightest mass |
| Charged leptons | 0.500 | measured |
| Quarks, bound | 0.763 (0.746 adding roots) | measured |
| Lepton mixing (PMNS) | 0.07 | measured, no mass |
| Quark mixing (CKM) | 0.63 | measured, no mass |

## Predictions

1. **Normal neutrino mass ordering.** Identity with inverted ordering needs a
   total neutrino mass of at least 0.102 eV, above the DESI 2024 limit
   (0.072 eV).
2. **Total neutrino mass between 0.069 and 0.072 eV**, lightest neutrino at
   least 0.0071 eV. The lower end comes from D <= 0.1; the upper end is the
   current DESI limit.
3. Lepton mixing stays closer to identity than quark mixing (holds now: 0.07
   vs 0.63).

## How it fails

- Inverted ordering is established (JUNO, DUNE, Hyper-K).
- The total neutrino mass is shown to be below 0.069 eV (cosmology: DESI,
  Euclid, CMB-S4), or the lightest neutrino below 0.0071 eV.
- Neutrinoless double-beta decay or KATRIN/Project 8 place masses outside the
  window.

Prediction 2 sits right against the current cosmology limit, so it is close
to being tested now.

## Charts

- `experiments/koide-projector/lepton-frame.png`: entities in the e, mu, tau
  triangle; the neutrino path shows where each lightest mass would put them.
- `experiments/koide-projector/three-entities.png`: D by mass and by mixing.
