# Origin lab: string-net (where fermions come from)

**Standard physics, not origin's pixel rules.** Kitaev's toric code, the simplest string-net model. One qubit on each link of an L × L torus, and two local rules:

- A_v = product of X on the 4 links at a vertex (penalizes string ends: a Gauss law)
- B_p = product of Z on the 4 links of a plaquette (penalizes flux)
- H = −Σ A_v − Σ B_p

The ground state is a superposition of closed strings. Excitations are string ends: **e** (end of a Z string, at a vertex) and **m** (end of an X string, at a plaquette). The question tested is Levin & Wen's: can **fermions** come out of a model whose parts are all bosons (qubits) with local rules? Statistics are measured with their T-junction test ([cond-mat/0302460](https://arxiv.org/abs/cond-mat/0302460)): three hopping operators t₁, t₂, t₃ meeting at a point satisfy t₁t₂†t₃ = e^{iθ} t₃t₂†t₁, and θ is the exchange phase.

Everything here is exact algebra on Pauli strings, so there is no statistical error. `node run.js` runs all checks and results in under a second (`results/run.txt`).

## Checks

- Pauli algebra: XZ = −ZX, (XZ)² = −1, PP† = 1.
- Every A_v commutes with every B_p, for L = 2, 3, 4, 5.
- Ground-state degeneracy from the stabilizer rank is 4 for every L. That's the torus's topological order: the degeneracy is set by the surface's shape, not by its size.
- Independent check: brute-force diagonalization of the 256 × 256 Hamiltonian at L = 2 gives E₀ = −8, degeneracy 4, gap 4 (two excitations of cost 2).
- Every hopping leg used in the statistics test creates excitations only at its two ends: 2 e for e, 2 m for m, 2 e + 2 m for e × m.
- A first version of the "other corner" control had m hopping across the wrong links. The leg-validity check above now catches that; it was fixed before the result was used.

## Results

1. **Strings are free.** An open Z string of length 1 to 5 creates exactly two excitations, at its ends, whatever its length (energy 4). A closed string costs nothing. The vacuum is a string-net condensate, and string ends are deconfined particles.
2. **Statistics,** each the same in all 10 junctions tried (5 orientations × leg lengths 1 and 2):

| particle | exchange phase e^{iθ} |
|---|---|
| e (string end, vertex) | +1: boson |
| m (string end, plaquette) | +1: boson |
| e × m (bound pair) | **−1: fermion** |

3. **Mutual statistics:** carrying e once around m gives −1, an Aharonov–Bohm phase. That's where the fermion comes from: when two e × m pairs swap, each one's e goes half way round the other's m.
4. **Robust:** binding m on the opposite corner of the vertex still gives −1.

So a model built only of bosons, with two local rules, has a fermion among its excitations. The fermion isn't put in anywhere: it comes from how string ends wind around each other.

## Limits

- The toric code gives Z₂ gauge theory: its "photon" has a gap. A massless photon needs the U(1) version (see `../u1-photon`), and real electrons need a U(1) string-net with fermionic ends. Levin & Wen build that in [hep-th/0507118](https://arxiv.org/abs/hep-th/0507118); it isn't reproduced here.
- No dynamics: the results are exact algebraic properties of the excitations, not a time evolution.
