# Origin lab: the quantum pixel

**This one is origin's own idea,** not a textbook model. Origin's pixel is three cells, and its kind is set by how many are filled. Here the pixel becomes quantum and is given real gauge forces, so the results bear directly on origin's design.

## The model

- **Pixels and cells:** a chain of L pixels, each with three fermionic cells, one per colour (r, g, b). A pixel has 2³ = 8 states, and its kind is the filled count n = 0..3.
- **Colour comes free.** Because the cells are a colour triplet, n = 1 is a colour triplet, n = 2 an antitriplet, and n = 0 and n = 3 are colour-neutral. So the pixel structure alone makes quarks coloured and leptons colourless, exactly as in nature.
- **Electric charge** is a table q[n]. Two designs are compared:
  - **FUREY**, q = n/3: ν, anti-down (+⅓), up (+⅔), positron (+1). This is Furey's one-generation construction, where charge is a number operator ([arXiv 1603.04078](https://arxiv.org/abs/1603.04078)). Its mirror image, q = −n/3, gives ν̄, down, anti-up, electron.
  - **ORIGIN**, q = 0, −⅓, +⅔, −1: ν, down, up, electron. That's origin's pixel table, which takes n = 1 and n = 3 from one mirror image and n = 2 from the other.
- **Gauge forces:** SU(3) colour and U(1) electric. In 1D with open ends the Gauss law fixes the field on each link from the charges to its left, so the fields cost energy (g²/2)·C₂(colour flux) + (e²/2)·(electric flux)² per link. The last link runs out to infinity.
- **Motion,** two designs:
  - **cells move:** each cell hops on its own, so cells are partons;
  - **pixels move:** a whole pixel hops into an empty neighbour, so the cells are an internal label.

`node check.js` (1 s), `node run.js` (40 s); outputs in `results/`.

## Checks

- Fermion algebra {c_i, c†_j} = δ_ij on all 64 states of 6 modes.
- SU(3) algebra [T₁, T₂] = iT₃ on a pixel.
- The colour Casimir used in the model (Fierz form) equals Σ_a Q^aQ^a built from explicit Gell-Mann matrices: all 64 two-pixel states, to 7 × 10⁻¹⁶.
- One pixel: C₂ = 0, 4/3, 4/3, 0 for n = 0..3 (singlet, triplet, antitriplet, singlet).
- All four Hamiltonians (2 motions × 2 tables) are Hermitian and commute with all eight colour generators (10⁻¹⁵): colour gauge symmetry is exact.
- Lanczos ground state = dense diagonalization to 10⁻¹⁰.

## Results

**1. The charge table decides whether fractional charges can roam free.** Every arrangement of kinds on up to 4 pixels was enumerated, and the electric charge of every colour-neutral state was recorded:

| table | charges of colour-neutral objects |
|---|---|
| FUREY | 1, 2, 3, 4 only: always whole numbers |
| ORIGIN | −4, −3, −2, **−5/3**, −1, **−2/3**, **+1/3**, **+2/3**, 1, 2 |

With origin's table, a down pixel next to an up pixel is colour-neutral, so nothing confines it, yet it has charge +⅓. Searches for free fractional charge have found none. With Furey's table this is impossible: colour neutrality forces n ≡ 0 (mod 3), and q = n/3 is then a whole number. The fix to origin's table is one sign: the n = 2 pixel should be **anti-up (−⅔)**, not up (+⅔). That is, origin's table should be the mirror of Furey's, q = −n/3: ν̄, d, ū, e⁻.

**2. Confinement comes out exactly** (static, colour field only, g² = 1):
- quark–antiquark r apart: energy = ⅔ r exactly (r = 1..6), a string with constant tension;
- a lone quark: energy grows with the size of the world (⅔ L), so it can't exist free;
- three quarks bind into a colour singlet with two string segments.

**3. How things move decides whether electrons are electrons.** Ground state of three filled cells on 6 pixels:

| motion | colour force g² | ground state (ORIGIN table) |
|---|---|---|
| cells move | 0.5 | 58% up+down, 33% down+down+down, 10% electron |
| cells move | 8 | 74% electron, 25% up+down |
| pixels move | 0.5 | 100% up+down (a free +⅓ object) |
| pixels move | 2, 8 | 100% electron |

When cells move independently, an electron is three quarks sitting on one pixel, and it keeps leaking into quark states. The leak shrinks as the colour force grows (4 × 10⁻⁴ at g² = 128, falling as g²^−2.5) but never vanishes. Real electrons show no internal structure, and lepton and baryon number are separately conserved. When whole pixels move, kinds are conserved, which is exactly those conservation laws. FUREY gives the same pattern with anti-down/up/positron.

## What it means for origin

1. **Keep the three-cell pixel.** Colour, the triplet/antitriplet split and confinement fall out of it with no extra rules.
2. **Change the n = 2 charge to −⅔ (anti-up).** That is, use q = −n/3. This one change removes every free fractional charge.
3. **Move whole pixels, not cells.** That keeps electrons pointlike and conserves lepton and baryon number separately.
4. **The neutrino is the empty pixel.** In this design n = 0 carries no colour and no charge, and it's literally the same state as empty space. Furey's construction says the same: the neutrino "plays the role of the vacuum state". That matches your triangle note, where the neutrino is the identity pole that engages only the weak force. But a neutrino that is empty space can't move, carry energy or mix. Making it a real particle needs one more ingredient that isn't built here, for example a fourth "lepton colour" (Pati–Salam) or a weak-isospin bit per pixel.

## Limits

- 1D, at most 6 pixels, exact diagonalization.
- One generation. Koide masses and three generations aren't in this model.
- No weak force, so no beta decay or neutrino mixing.
- Fermions are put in as fermionic cells. They aren't derived here; the string-net lab shows how they can be.
