# Prime Oscillator Experiment: results (2026-11-03)

**Verdict: hypothesis not supported.** In a model where frequency ratios
matter, prime ratios hold coherence *worse* than typical sets. What predicts
coherence is ratio simplicity (small p+q), and the primes 2,3,5,7,11 produce
many high-order ratios (11:7, 11:5, 7:5).

Run: `python run.py` (about 1 min), then `python population.py` (about 6 min).
Chart conventions: `CHART_RULES.md`.

## Model

Five phase oscillators coupled through every p:q harmonic resonance up to
order 12, with weaker coupling for higher orders (`model.py`). 1% frequency
mistuning and phase noise, so locking must be maintained by the coupling.
Coherence is measured at each pair's own natural ratio, and only while the
oscillators stay within 5% of their natural frequencies.

## Results

| Chart | Finding |
|---|---|
| 1-coupling-sweep | In the valid regime, primes stay at or below the no-coupling baseline (0.14 vs 0.18). Only the harmonic set 1..5 locks before breakdown. |
| 2-prime-pairs | Only the simplest prime ratio locks at all (3:2, 0.27). High-order ratios (11:7, 11:5) stay near zero. |
| 3-all-integer-sets | Among all 792 sets of five integers 2..13, primes beat 18%. Coherence correlates with ratio simplicity at r = -0.79. Best set: 2,3,6,9,12. |
| 4-random-reals | Primes beat 16% of 200 random real-valued sets. |

## The artifact this design avoids

A first version scored coherence as "locks at any ratio" and found primes
fully coherent at K >= 0.5. Checking the running frequencies showed the
oscillators had been dragged to about half speed at K = 0.5 and stopped
entirely at K = 0.8 (oscillator death). That is pinning, not harmony. Rules 7
and 10 in `CHART_RULES.md` exist to prevent it.

## Limits

- One model family (phase oscillators, harmonic weights p^-1.5). Different
  weightings change tongue widths but favour low-order ratios generally.
- Five oscillators; N = 5 matches the original experiment.
