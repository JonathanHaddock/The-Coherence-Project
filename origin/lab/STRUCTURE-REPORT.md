# Structural ideas for origin: six experiments (2026-11-18)

Each idea from the literature was built as a separate lab in `origin/lab/`, with its own checks against exact or published results. All of it is standard physics, not origin's pixel rules. The point is to see which structural moves actually produce physics, and which don't, before origin adopts any of them.

| Lab | Idea | Verdict |
|---|---|---|
| `u1-photon` | Light from phases on links (Levin & Wen) | **Works.** One coupling switches the vacuum between "light exists" (1/R potential, no string tension) and "charges confined" (linear potential) |
| `string-net` | Fermions from bosonic qubits (Levin & Wen) | **Works.** Bound pairs of string ends are exactly fermions; their parts are bosons |
| `dirac-qca` | Dirac equation from principles (D'Ariano et al.) | **Works, with a cost.** Relativity, mass, a speed limit and Zitterbewegung come out; 3D isotropy breaks at first order in momentum |
| `triangulations` | Causality makes space (Ambjørn & Loll) | **Works.** Same rule, same moves: with a time order, dimension ≈ 2.2; without, ≈ 3 and heading to 4 (crumpled) |
| `causal-set` | Random, not regular (Sorkin et al.) | **Works, with a cost.** Random points look the same to every observer; a lattice breaks apart when boosted. Price: nearest neighbours grow without limit (~ln N) |
| `graphity` | Geometry from cooling (Konopka, Markopoulou & Smolin) | **Fails as tested.** Loop rewards prefer clusters to space; even with a fix, cooling freezes into disorder |
| `quantum-link` | Gauge theory on qubits (Chandrasekharan & Wiese) | **Works.** One bit per link carries a real gauge theory: Gauss law, winding sectors, confined phases, exact RK point |

## What was checked

Every lab was checked against something it can't fake before any result was used:

- **Exact solutions:** 2D U(1) plaquette I₁/I₀ and Wilson loops; toric-code degeneracy 4 and gap; Dirac automaton dispersion cos ω = n cos k; 2D CDT entropy ln 2 per triangle (0.696 ± 0.003 and 0.692 ± 0.005); longest chain 2√N with its Tracy–Widom correction; the RK point E₀ = 0.
- **Brute force:** enumerations, link counts, chains, and Boltzmann distributions over all 1,024 graphs on 5 nodes.
- **Symmetries:** gauge invariance to 10⁻¹⁶–10⁻¹⁷; unitarity to 10⁻¹⁵; strict light cone.
- **Limits:** strong and weak coupling of SU(3) and U(1).

Errors caught by the checks and fixed before use:
- a sign error in the U(1) staple (caught by the 2D exact result);
- a wrong m-hop geometry in a string-net control (caught by leg validity);
- signed 32-bit XOR in JavaScript (caught by a flip leaving the sector);
- single-vector Lanczos hiding a degenerate pair (caught by comparing with dense diagonalization);
- an unbounded energy in the first graphity model;
- an infinite loop when the graph is complete;
- under-thermalized DT runs (caught by the mean distance drifting).

My own wrong expectations, corrected after looking:
- that the 3D Weyl anisotropy would be second order (it's first order, matching the analytic expansion);
- that the quantum link gap would close toward the RK point on a 4 × 4 box (it doesn't).

## What it says about origin

1. **Put fields on links, with a Gauss law at each site.** That's the common structure of the photon, string-net and quantum-link labs. Charge conservation, forces and confinement then come out of one action instead of a growing rule list. One bit per link is enough.
2. **Particles are string ends and their bound states, not cells.** Fermions appear from winding (e around m), not from any fermionic part.
3. **Impose causality.** In the triangulation test it was the single change that turned crumpled structure into extended space. Origin's sync/sweep choice is a time-ordering choice and deserves to be treated as structural.
4. **Choose principles first, rules second.** The Dirac automaton gets relativity, mass and Zitterbewegung from unitarity, locality, homogeneity and isotropy, with nothing patched in.
5. **A fixed grid has a preferred frame.** Random structure fixes that but makes "neighbour" non-local. That is the real trade-off behind open decision #5 (lattice vs. no lattice).
6. **Geometry from local cooling is the weakest idea tested.** It needs more than a local energy.
7. **Quantum is the dividing line.** The string-net fermions, the quantum link model and the Dirac automaton are quantum. The U(1), SU(3) and triangulation results are classical Monte Carlo of statics (Euclidean path integrals), not real-time classical dynamics. A classical, deterministic origin can reach structure (phases, confinement, dimension), but not entanglement or fermion statistics.

## Limits

Toy sizes throughout, mostly 1+1 or 2D; free fields only in the automaton; the graphity model is a classical simplification, not the paper's Hamiltonian; DT doesn't reach its asymptotic dimension 4 at these sizes. A few literature values are quoted as "commonly quoted" where the primary source wasn't rechecked; each lab README says which.
