# Origin lab: quantum link model (gauge theory from qubits)

**Standard physics, not origin's pixel rules.** Lattice gauge theory normally puts a continuous matrix on every link. Chandrasekharan & Wiese ([hep-lat/9609042](https://arxiv.org/abs/hep-lat/9609042)) showed the links can be **qubits**: here, each link of a 4 × 4 periodic square lattice holds one bit of electric flux (±½). That's as small as an origin pixel cell. The question tested: does a gauge theory survive when the link is that small?

- **Gauss law at every site:** flux in = flux out (the "ice rule": 2 in, 2 out).
- **H = −J Σ (U_p + U_p†) + λ Σ (U_p + U_p†)²**, where U_p flips a plaquette whose four fluxes circulate, and (U + U†)² counts flippable plaquettes.

`node run.js` runs checks and results in about 25 seconds (`results/run.txt`).

## Checks

- The state enumerator matches brute force over all 2⁸ (L = 2: 18 states) and 2¹⁸ (L = 3: 148 states) configurations.
- Every plaquette flip of every one of the 2,970 states (L = 4) keeps the Gauss law and the winding numbers.
- Two eigensolvers agree: Householder + QL equals Jacobi on every eigenvalue, with multiplicity (5 × 10⁻¹⁵).
- **Bugs caught by the checks, fixed before results were used:** (1) JavaScript's XOR is signed 32-bit, so flipping the 32nd link made state numbers negative; the build step threw an error. (2) Single-vector Lanczos reports a degenerate pair (−1.8, −1.8) as one level, which would hide a zero gap. All spectra below come from dense diagonalization instead.

## Results

**The Gauss law collapses the space.** 32 qubits have 4,294,967,296 states; only **2,970** obey the Gauss law, split into winding sectors (0,0): 990, (±1,0) and (0,±1): 340 each, (±1,±1): 140 each, and smaller ones. Most of what the bits could do is forbidden by a local constraint. That's how gauge theories work.

**Rokhsar–Kivelson point.** At λ = J the ground-state energy is exactly 0 in every sector (largest |E₀| = 1 × 10⁻¹⁴), as theory requires.

**Spectrum in sector (0,0)** (990 states, exact):

| λ/J | E₀ | gap to next level | flippable share ⟨F⟩ |
|---|---|---|---|
| −2.0 | −33.914 | **0.003** | 0.945 |
| −1.0 | −19.471 | 0.083 | 0.831 |
| −0.5 | −13.416 | 0.442 | 0.676 |
| 0 | −8.468 | 0.381 | 0.578 |
| 0.5 | −4.031 | 0.294 | 0.534 |
| 0.9 | −0.756 | 0.385 | 0.483 |
| 1.0 | 0 | 0.437 | 0.461 |

(⟨F⟩ from dE₀/dλ, Hellmann–Feynman.) At large negative λ almost every plaquette is flippable, and the two lowest levels become nearly degenerate (gap 0.003 at λ = −2). On a finite box that's the signature of a spontaneously broken symmetry. It matches Banerjee et al. ([1311.2459](https://arxiv.org/abs/1311.2459)): for λ below a critical value both charge conjugation and translation are broken, with a gap that closes exponentially with volume; above it only translation is broken; both are confined "crystalline" phases. At the RK point flux condenses and the theory deconfines. A 4 × 4 box is too small to locate their transition.

## What it means for origin

A real gauge theory, with its Gauss law, winding sectors and confining phases, runs on one bit per link. Origin's 3-bit pixels are large enough in principle. What makes it a gauge theory isn't the size of the variable but the constraint (flux in = flux out at every site) and the loop-flip dynamics.

## Limits

- 4 × 4 only (exact diagonalization), no dynamical charges, 2D.
- Quantum: these are eigenstates of a Hamiltonian, not a classical update rule.
