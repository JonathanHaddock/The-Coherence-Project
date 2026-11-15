# Origin lab: superconductor (2D)

A separate area of origin. **Standard physics, not origin's pixel rules.** A lattice of ions and moving electrons you can change, for experiments on what makes superconductors.

Three layers, all 2D, sharing one set of lattice and electron parameters:

| Layer | Question | Status | Files |
|---|---|---|---|
| 1. Watch it (classical) | Does an electron's lattice wake pull a second electron in? | **built** | `sim.js`, `index.html`, `run.js` |
| 2. Is the pair real? (quantum) | Do two electrons form a bound pair in the Holstein–Hubbard model, and how heavy is it? | not built yet | |
| 3. What would Tc be? | Allen–Dynes Tc from the lattice you built, scaled from a real metal | **built** | `tc.js` |

**Limit, stated up front:** a classical simulation shows the *mechanism* of Cooper pairing (the wake), not superconductivity, which is quantum. That's what layer 2 is for.

## Run it

- **Watch:** open `index.html` in a browser.
- **Experiment:** `node run.js g=2 M=800 seed=1` prints one TSV row. Any parameter below can be set; add `steps=`, `burn=` (steps skipped at the start) and `every=`.
- **Check layer 3:** `node tc.js` prints Allen–Dynes against four real metals.

## Layer 1: the model

Units: bond length 1, electron mass 1, Boltzmann constant 1.

| Parameter | Default | Meaning |
|---|---|---|
| `lattice` | square | square, triangular or honeycomb; every bond has length 1 |
| `cells` | 16 | unit cells per side (periodic box) |
| `M` | 400 | ion mass. Real ion/electron ratios: 1,800 (H) to 380,000 (Pb) |
| `k1` | 1.0 | bond spring stiffness (stands in for pressure) |
| `k0` | 0.2 | spring tying each ion to its site |
| `g` | 1.0 | electron–ion coupling: depth of each ion's Gaussian pull |
| `sigma` | 0.6 | width of that pull. Broad, so a perfect lattice feels almost flat and electrons feel *deformations*, not single ions (deformation-potential picture) |
| `U`, `screen` | 1.0, 1.5 | electron–electron repulsion, screened Coulomb `U e^(−r/screen) / √(r² + 0.25)` |
| `ne` | 2 | number of electrons |
| `vF`, `fermi` | 1.0, true | degenerate electrons stay at the Fermi speed (Pauli: they can't slow into filled states). Their direction is free |
| `T`, `gamma` | 0.002, 0.02 | ion temperature, Langevin thermostat |
| `vacancy` | 0 | fraction of ions removed (disorder) |
| `dt` | 0.02 | time step |

Velocity Verlet integration, periodic box. The Gaussian is cut at 5σ and shifted to 0 there.

**Checks passed (2026-11-14):**
- Energy (no thermostat, no Fermi hold) is conserved to 1.2 × 10⁻⁵ over 5,000 steps at dt 0.02, and 2.2 × 10⁻⁶ at dt 0.01. The error shrinks with dt², as a correct integrator's should.
- Top phonon frequency (k0 0, k1 1, M 1): square 2, triangular √6, honeycomb √3, the textbook values.
- Largest force a perfect still lattice puts on an electron (g 1): 0.029, the residual ripple of a σ 0.6 Gaussian.
- A first version cut the Gaussian off at 3σ. That gave 2.8% energy drift and a 0.11 ripple, and was fixed before any experiment.

## Layer 3: Tc

Allen & Dynes, PRB 12, 905 (1975): `Tc = f1 f2 (ω_log/1.2) exp(−1.04(1+λ) / (λ − μ*(1+0.62λ)))`.

| Metal | λ | ω_log | Tc measured | Allen–Dynes μ* 0.10 | μ* 0.13 |
|---|---|---|---|---|---|
| Al | 0.43 | 300 K | 1.18 K | 1.88 | 0.93 |
| Sn | 0.72 | 110 K | 3.72 K | 4.22 | 3.27 |
| Pb | 1.55 | 52 K | 7.20 K | 6.68 | 6.06 |
| Nb | 1.26 | 115 K | 9.25 K | 11.68 | 10.36 |

Input values as listed in arXiv 2604.04719 from Allen & Dynes's Table I; they still need checking against the 1975 paper.

**Link to layer 1** (McMillan 1968, λ = η / (M⟨ω²⟩)): the page takes a reference metal and scales λ by (g / g_default)² × (default stiffness / your stiffness), where stiffness = M⟨ω²⟩ from the lattice's own phonons, so ion mass cancels. ω_log scales with the lattice's phonons, so it goes as M^(−½): the isotope effect. That makes it an estimate, not a prediction.

## Experiment 1: does the wake pair electrons? (`results/wake-pairing/`)

2 electrons, square lattice, default parameters, 200,000 steps (first 20,000 skipped), seeds 1–4. "Close vs chance" is the share of time the two are within 2 bonds, divided by the share random positions would give.

| g | close vs chance (mean) | range over 4 seeds | what happens |
|---|---|---|---|
| 0 (control) | 1.18× | 0.78–1.33 | about chance |
| 1 | 0.63× | 0.56–0.69 | free electrons; their repulsion keeps them slightly apart |
| 2 | 1.09× | 0.55–2.17 | crossover; seed 1 pairs (2.2×, 60 short pairings), others don't |
| 3 | 15.3× | 0–20.4 | **collapse:** 3 of 4 seeds end with both electrons on one spot (0.01–0.08 apart) in a crushed dent (bonds squeezed up to 76%), barely moving; seed 3 has two separate self-trapped electrons that never meet |

Reading: the classical lattice gives the two textbook failure modes on either side of a narrow window. Weak coupling: no binding. Strong coupling: a heavy, immobile, self-trapped pair (a bipolaron), matching the quantum Monte Carlo warning that on-site bipolarons are too heavy to superconduct. A mobile pair, if it exists here, lives around g ≈ 2. The squeeze at g 3 is unphysically large (the bonds are harmonic springs with no hard core), so that regime isn't realistic.

Next: sweep g across 1.5–2.8 against stiffness, ion mass and lattice type, to map where mobile pairs exist; then layer 2.

## Sources

- Allen & Dynes, PRB 12, 905 (1975); McMillan, Phys. Rev. 167, 331 (1968)
- [Two-channel Allen–Dynes framework (values used)](https://arxiv.org/html/2604.04719)
- [QMC bipolarons on FCC/BCC (2025)](https://arxiv.org/pdf/2507.17398); [Hubbard–Holstein bipolaron (2004)](https://arxiv.org/pdf/cond-mat/0401305)
- [Cooper pair](https://en.wikipedia.org/wiki/Cooper_pair); [Velarde & Neißner 2008](https://www.ucm.es/data/cont/media/www/pag-40479/2008-VN-IJBC.pdf)

## Experiment 2: where is the self-trapping cliff? (`results/coupling-cliff/`)

10 electrons, square lattice, T 0.0005, 60,000 steps (first 10,000 skipped), seeds 1–3. λ is the average coupling (see the page); mobility is net distance travelled per unit time over the Fermi speed.

| g | λ | trapped share | mobility |
|---|---|---|---|
| 1.0 | 0.03 | 0.1% | 0.16 |
| 1.2 | 0.08 | 2% | 0.13 |
| 1.4 | 0.14 | 8% | 0.12 |
| 1.5 | 19.5 | 31% | 0.08 |
| 1.7 | 107 | 93% | 0.02 |
| 2.0 | 104 | 100% | 0.001 |

The cliff is at g ≈ 1.45–1.5. λ jumps about 140× in one step of 0.1, the abrupt self-trapping transition known for 2D and 3D (Emin & Holstein). Strongest coupling with mobile electrons: g ≈ 1.3–1.4, λ ≈ 0.1.

## Experiment 3: pairing signatures vs the g = 0 control (`results/pairing-signatures/`)

30 electrons, square lattice, 150,000 steps, seeds 1–3, g 0 / 1.0 / 1.3 / 1.4 × T 0.0002 / 0.002 / 0.01. Measures from `measures.js`: wake-following at delays (vs chance) and opposite momenta (mean cosine among electrons within 3 bonds).

**Weak delayed glue at g 1.0, low temperature.** Wake-following above the control, in all 3 seeds:

| delay | 0 | 0.5 | 1 | 2 | 4 | 8 | 16 |
|---|---|---|---|---|---|---|---|
| control (g 0) | 0.53 | 0.55 | 0.73 | 0.96 | 1.01 | 1.09 | 1.03 |
| g 1.0, T 0.0002 | 0.54 | 0.56 | **0.76** | **1.01** | 1.04 | 1.11 | 1.04 |

At delays 1–2 every seed with coupling (0.758–0.760, 1.004–1.019) sits above every control seed (0.732–0.735, 0.958–0.965): an excess of about 4–5%. At delay 0 both sit well below chance (repulsion keeps electrons apart). That's the retarded-attraction shape the literature describes, but weak. Opposite momenta: no preference (cos ≈ 0).

**With 30 electrons, the cliff moves down.** At g 1.3 and 1.4 the electrons don't pair; they clump into droplets (g 1.3, T 0.002, seed 1: three clumps of 11, 10 and 9 electrons), λ ≈ 60. Wake-following is then about 20–30× at every delay, which is just electrons sitting together. Heat makes it worse: at g 1.0 and T 0.01, a 15-electron droplet forms (λ 42). This is the competing state the literature warns about for classical-lattice models (charge ordering instead of pairing). The negative momentum cosine in the droplets (−0.04 to −0.14) is electrons circling inside a pit, not Cooper pairing.

**Reading:** the classical lab shows the glue (a small, delayed attraction), shows self-trapping and droplets on either side of it, and doesn't show bound mobile pairs. As expected for a classical model, whether the glue makes a real pair is the quantum question for layer 2.
