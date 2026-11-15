# Origin lab: superconductor (2D)

A separate area of origin. **Standard physics, not origin's pixel rules.** A lattice of ions and moving electrons you can change, for experiments on what makes superconductors.

Three layers, all 2D, sharing one set of lattice and electron parameters:

| Layer | Question | Status | Files |
|---|---|---|---|
| 1. Watch it (classical) | Does an electron's lattice wake pull a second electron in? | **built** | `sim.js`, `index.html`, `run.js` |
| 2. Is the pair real? (quantum) | Do two electrons form a bound pair in the Holstein–Hubbard model, and how big is it? | **built** (pair mass not yet) | `layer2.js` |
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

## Layer 2: the quantum pair (`layer2.js`, `results/layer2-binding/`)

Holstein–Hubbard model, exact (Lanczos), 3×3 periodic lattice, one electron and a singlet pair, phonons truncated at 8 quanta in total (about 1.1 million states). Units: hopping t = 1. λ = g² / (4 ω₀ t). Binding energy E_b = E₂ − 2E₁; below 0 means bound.

```sh
node layer2.js g=1.414 w0=1 U=4 Nmax=8
```

**Checks passed.** With no coupling, E₁ = −4 and E₂ = −8 exactly (E_b = 0), and the pair sits on one site 1/9 of the time (chance on 9 sites). With repulsion only (U 4), E_b = +0.30 (unbound). Phonon cutoff, λ 0.56: E₁ = −4.6821, −4.6841, −4.6842 at 4, 6, 8 quanta (converged). E₂ is still falling (−9.915, −10.029, −10.092), but a truncated basis can only overestimate E₂ (variational), so every E_b below is an upper bound: the true binding is at least as strong. At λ ≥ 0.75 the pair carries about 4–5 phonons against a cutoff of 8, so those rows are the least converged.

| λ | U 0: E_b | on-site | size | U 2: E_b | on-site | size | U 4: E_b | on-site | size |
|---|---|---|---|---|---|---|---|---|---|
| 0.10 | −0.09 | 0.12 | 1.06 | +0.10 | 0.08 | 1.12 | +0.23 | 0.05 | 1.16 |
| 0.25 | −0.24 | 0.14 | 1.03 | −0.02 | 0.09 | 1.11 | +0.12 | 0.06 | 1.15 |
| 0.50 | −0.58 | 0.24 | 0.89 | −0.25 | 0.11 | 1.06 | −0.08 | 0.07 | 1.13 |
| 0.75 | −1.55 | **0.70** | 0.33 | −0.60 | 0.24 | 0.88 | −0.30 | 0.10 | 1.08 |
| 1.00 | −2.84 | **0.83** | 0.18 | −1.36 | **0.61** | 0.43 | −0.59 | 0.20 | 0.93 |
| 1.50 | −4.46 | **0.90** | 0.10 | −2.73 | **0.83** | 0.18 | −1.24 | **0.62** | 0.41 |

"On-site" = share of time both electrons sit on the same site; "size" = mean distance between them (bonds; on a 3×3 box the largest possible is 1.41).

**Isotope test (λ 0.5):**

| ω₀ (lighter ions →) | 0.5 | 1 | 2 |
|---|---|---|---|
| E_b, U 0 | −0.50 | −0.58 | −0.67 |
| E_b, U 4 | −0.10 | −0.08 | −0.05 |

### What it shows

1. **A real quantum pair forms.** Without repulsion, any coupling binds two electrons (λ 0.1: E_b −0.09), as Cooper's argument says for an attraction in 2D. The classical lab couldn't do this.
2. **Two kinds of pair, with a sharp crossover.** At weak coupling the pair is large and spread out (on-site about 0.1–0.24, size close to the box limit): the light, mobile kind. Above a threshold it collapses onto one site (on-site 0.7–0.9, size 0.1–0.3): the heavy on-site bipolaron, the quantum version of layer 1's self-trapping cliff. Without repulsion the crossover is between λ 0.5 and 0.75.
3. **Repulsion keeps the pair large.** U pushes the crossover up (U 2: λ 0.75–1.0; U 4: about 1.0–1.5) and opens a window of bound but spread-out pairs (U 4, λ 0.5–1.0: bound, on-site 0.07–0.20). These are the intersite pairs the 2025 QMC paper links to high Tc.
4. **The isotope effect flips with repulsion.** Without repulsion, faster vibrations (lighter ions) bind more strongly. With strong repulsion (U 4), slower vibrations bind more strongly. That's retardation (Anderson–Morel): slow ions respond late enough that the second electron arrives after the first has left, dodging the Coulomb repulsion. It's the quantum version of the delayed wake seen in layer 1.

### Limits

- 3×3 is tiny: a pair larger than the box can't show its true size, so "large" here means "as large as the box allows". The next step is a 4×4 lattice (needs a lower phonon cutoff or a smarter basis).
- Pair mass isn't computed yet. That's what decides whether a bound pair can actually move (twisted boundary conditions would give it).
