# Lepton coherence: checks with ORIGIN (2026-11-03)

Numerical checks of the claims in `Lepton coherence`, computed by
`origin koide` with PDG 2024 masses and NuFIT 6.0 neutrino splittings.
The original document is unchanged.

## Family values

| Family | Q | D | Omega | Note says |
|---|---|---|---|---|
| Charged leptons | 0.66666 | 0.500 | 1.000 | matches |
| Down quarks d,s,b | 0.731 | 0.597 | 0.962 | ~0.74 / 0.95, close |
| Up quarks u,c,t | 0.849 | 0.773 | 0.701 | ~0.89 / 0.55, differs |
| Neutrinos (m1 = 0, normal) | 0.585 | 0.378 | 0.940 | matches |

The ordering nu -> l -> d -> u holds with current data.

## Points to address

1. **Omega = 1 for charged leptons is not independent evidence.** D maps
   Q = 2/3 to exactly 1/2, and Omega = 4D(1-D) is 1 there by construction.
   Omega is a function of Q alone.
2. **Neutrino placement is a choice, not a measurement.** Q is 0.585 only if
   the lightest neutrino is massless with normal ordering. With m1 = 0.01 eV,
   D = 0.07 and Omega = 0.27; with inverted ordering, Q is at most 0.500.
3. **Charged leptons are not the only triplet near 2/3.** Of 336 triplets of
   the nine charged fermions (allowing one negative root), 6 fall within 0.01
   of 2/3, including (c, t, b) at 0.6692 and (c, -s, b) at 0.6748. Near-2/3
   values happen by chance; the leptons stand out only by their precision
   (6e-6 from 2/3).
4. **Mixing has two data points, and each belongs to a pair of families.**
   PMNS mixes neutrinos with charged leptons, CKM mixes up with down quarks.

## Suggested next tests

- Find a second observable that places families on D without using masses
  (prediction 4 in the note): for example mixing-angle entropy per sector.
- Treat neutrino D as a prediction: the note implies a specific lightest
  mass. `origin koide` shows which m1 gives each D, testable by KATRIN,
  Project 8 and cosmology bounds.
