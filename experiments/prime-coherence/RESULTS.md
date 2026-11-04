# Prime Quantum Coherence: results (2026-11-03)

**Verdict: hypothesis not supported.** Primality has no effect in this model.
The outcome is set by the gaps between neighbouring frequencies, chiefly the
first gap.

Run: `python controlled.py` (about 5 s). `original.py` is the unmodified
original script.

## Original run

| Set | Coherence | Entropy |
|---|---|---|
| Prime 2,3,5,7,11 | 1.4926 | 0.2240 |
| Random 2.7,4.9,8.2,10.8,13.3 | 1.2617 | 0.0865 |

Prime has higher coherence *and* higher entropy. The stated success rule
(higher coherence with lower entropy) is not met. Both metrics measure how far
the state spreads from node 0, so they rise together and the rule can rarely
be met by any set.

## Controls

- **Primes + 0.5 and primes + 100 give identical results.** Adding a constant
  to every frequency only adds a global phase, so in this model no property of
  the numbers themselves (including primality) can matter; only differences do.
- **2,3,5,7,12 matches the primes to 4 decimals**: the last node is barely
  reached.
- **The same gaps in reverse order collapse entropy to 0.029**: the first gap
  dominates.
- **Against 2000 random sets** from the same range, primes sit at the 63rd
  percentile for coherence and 66th for entropy: typical, not special.
- Entropy correlates with log(coupling / first gap)^2 at r = 0.78. The
  original random set's first gap (2.2) is larger than the primes' (1.0),
  which explains the whole original difference.
- The coupling sweep (0.05 to 2.0) shows no strength where primes stand out
  (54th to 73rd percentile).

## What a real test would need

For primes to matter, the model must depend on frequency *ratios*, not
differences. Examples: nonlinear coupled oscillators (Kuramoto with
frequency ratios), resonance conditions such as f_i / f_j being rational, or a
Hamiltonian with terms that mix modes when m f_i = n f_j. The planned
"entanglement proxy" also needs a many-body system; this single-excitation
5-level chain has no entanglement.
