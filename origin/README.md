# ORIGIN

A terminal particle observation engine written in Zig (0.17). It is the
computational side of The Coherence Project: it tests the Koide relation
behind `../Lepton coherence` and analyses real collider data from CERN.

![Dimuon mass spectrum](results/Dimuon_DoubleMu-mass.svg)

## Quick start

Run everything from this `origin/` folder.

```sh
zig build                 # binary at zig-out/bin/origin
zig build test            # unit tests
scripts/fetch.sh          # download CMS open data (~20 MB) into data/raw/
zig-out/bin/origin dataset
zig-out/bin/origin analyze
```

## Commands

| Command | What it does |
|---|---|
| `info` | System and module status |
| `catalogue` | The 12 registered particles: leptons, quarks, hadrons, photon |
| `constants` | CODATA physical constants |
| `observe <particle>` | Mass, charge, class (name or symbol, any case) |
| `koide` | Koide Q, organizational coordinate D and equilibrium Omega per family; normal and inverted neutrino scans; all 336 signed-root fermion triplets ranked by closeness to 2/3 |
| `dataset` | Verifies each downloaded dataset against its published size and adler32 checksum, and counts events |
| `analyze [dataset]` | Dimuon invariant-mass spectrum; finds phi, J/psi, psi(2S), Upsilon, Z and compares with PDG masses. Writes CSV and SVG to `results/` |
| `display [dataset] [event]` | Transverse event display with muon tracks bent by the CMS magnetic field. Writes SVG to `results/` |
| `project [a b c]` | Splits a 3-vector between the identity projector J/3 and the differentiation projector I - J/3. With no arguments: masses, plus PMNS and CKM mixing (no mass) |
| `chart [a b c]` | Draws the triangle and D-axis charts (mass-free) to `results/` and opens them; optional vector is highlighted. `--no-open` to skip opening |
| `weak` | Tests the weak mixing angle: solves for the angle where charged leptons carry exactly 1/3 projection, compares with measured definitions, draws and opens the chart |
| `charge` | Neutrino charge test: derives the B - L charge shift eps allowed with right-handed neutrinos, checks neutrality relations, and converts published limits to bounds on eps |
| `majorana` | Majorana test: effective Majorana mass band for both orderings over all phases, compared with KamLAND-Zen, LEGEND-1000 and nEXO |
| `export` | Writes derived datasets to `datasets/` with a checksummed manifest: per-event dilepton table (160,000 rows, regenerated, not committed), Z -> ee vs Z -> mumu spectra and summary, selection table |
| `universality` | Lepton universality: ORIGIN's Z peak comparison, the CMS efficiency-corrected ee/mumu ratio, and LEP partial widths |
| `generations` | Mass within an entity: Brannen parameters (mu, A, delta) per entity, Koide tau prediction vs measurements, delta vs 2/9 |
| `app` | Opens ORIGIN Explorer in the browser: sliders and presets for your own vector, live triangle and D axis, hover details, data table |
| `science` | Unit system demo |

Datasets: `Zmumu`, `Jpsimumu`, `Ymumu`, `Dimuon_DoubleMu` (default for `analyze`), and `Zee` (Z -> ee).

## Reactor design module

A teaching-grade reactor physics workbench under `src/reactor/`.

| Command | What it does |
|---|---|
| `reactor materials` | Two-group cross-section sets (lwr fuel, water, graphite), with k_inf and migration area |
| `reactor core [geom=slab\|cyl\|sphere] [fuel=cm] [refl=water\|graphite\|none] [rt=cm]` | Two-group finite-volume diffusion, power iteration for k_eff; reactivity, leakage, power peaking. Writes `results/reactor-core.svg` (fast/thermal flux and power) |
| `reactor critical [geom=..] [refl=..] [rt=cm]` | Bisection for the critical fuel size, reflected and bare; reflector savings |
| `reactor lattice [rods=out\|all\|center\|ring\|checker] [fuel=cm] [refl=..] [rt=cm] [cell=cm]` | 2D quarter-core two-group diffusion (SOR inner solve) with 20 cm assemblies and control-rod channels. Reports k_eff with rods in and out, rod worth in pcm and dollars, power peaking. Writes `results/reactor-lattice-<rods>.svg` heat maps of thermal flux and power |
| `reactor lattice ... h=cm ins=0..1 boron=ppm` | `h` > 0 makes the core 3D with 20 cm axial reflectors; rods enter from the top to fraction `ins` of the height. Prints axial power and axial offset; SVG shows horizontal and vertical slices. `boron` adds soluble boron (about 7 pcm/ppm) |
| `reactor boron [rods=..] [h=cm] [ins=..]` | Bisection for the critical boron concentration, plus boron worth |
| `reactor kinetics [rho=$] [t=s] [feedback=on\|off]` | Point kinetics, six delayed groups (Keepin U-235), lumped fuel-temperature feedback. Inhour period and feedback equilibrium for comparison. Writes `results/reactor-kinetics.svg` |

Cross sections are illustrative textbook values, not from any real design. Tests check the 1D and 2D solvers
against the analytic bare-slab and bare-square buckling results, the kinetics against the inhour equation, and the
feedback run against its analytic equilibrium.

### Design files

`reactor design <file.json>` evaluates a core described as data; `reactor optimize <file.json>` searches for a
better loading pattern and writes `results/<name>-optimized.json`. Examples are in `designs/`.

A design is a quarter-core map, one character per assembly. The last row is the centre row and the first column
the centre column, so the bottom-left symbol is the central assembly. Each symbol is defined in `legend`:

```json
"legend": {
  "H": { "mat": "lwr", "fission_scale": 1.08 },          // enrichment stand-in
  "B": { "mat": "lwr", "extra_sa2": 0.006 },             // burnable absorber stand-in
  "C": { "mat": "lwr", "rod": true },                    // control rod channel
  "W": { "mat": "water" }                                // reflector
}
```

`mat` is a built-in (`lwr`, `water`, `graphite`) or a name defined under `"materials"` with your own two-group
cross sections. Other keys: `assembly_cm`, `rod_width_cm`, `cell_cm`, `height_cm` (> 0 for 3D), `axial_reflector_cm`,
`rod_insertion` (the operating state), `boron_ppm`.

`constraints` (all optional): `k_min`, `k_max` (rods out), `peaking_max` (operating state), `shutdown_k_max`
(all rods in), `rod_worth_min_dollars`, `axial_offset_abs_max` (3D). Each is reported PASS or FAIL.

`optimize`: `objective` (`peaking`, `fuel` = least excess reactivity above `k_min`, or `neg_k`), `swappable`
symbols, `max_passes`. The search is deterministic steepest descent: each pass tries every swap of two different
swappable assemblies, applies the best improvement, and stops at a local optimum. Constraint violations are
penalised, so the search first drives a failing design toward feasibility.

## Data

CMS Run2011A dimuon events from [CERN Open Data record 545](https://opendata.cern.ch/record/545),
released under CC0. The list of files, sizes and checksums is in
`data/manifests/`. Downloaded files in `data/raw/` are not committed.

## Layout

```
src/science/        constants, units, particle catalogue
src/analysis/       koide, kinematics (four-vectors), spectrum (histograms, peak finding)
src/dataset/        manifest parsing, CSV event import, download verification
src/visualization/  SVG event display and mass spectrum
```
