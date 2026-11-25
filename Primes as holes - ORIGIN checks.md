# Primes as holes: ORIGIN checks

November 2026. Everything here runs in `origin/` (branch `levels`). No random numbers anywhere: every list of levels is computed or counted.

## The question

The zeta zeros are a list of numbers that rebuild the primes. They behave like the energy levels of some physical system, but nobody has found that system. Can we tell what kind of system it would have to be, and can a pixel world with holes produce it?

## The tool: `origin levels`

Hand it any list of levels and it runs six checks:

1. **Line up**: stretch the list so the average gap is 1.
2. **Gaps**: do neighbouring levels avoid each other, and how hard?
3. **Stiffness**: over long stretches, does the count stay steady or wander?
4. **Loops**: hidden repeats in the list. Only ratios count (units are arbitrary), so the shortest strong loop is set to log 2 and the rest are checked against log 3, log 4, log 5, ...
5. **Paths** (hydrogen only): the actual closed paths, traced directly, to tell real loops from side lobes and new paths from repeats.
6. **Repeats**: run each loop 1, 2, 3 times. Dip or peak each time?

## Results

| System | Gaps | Stiffness | Loops on primes | Repeats |
|---|---|---|---|---|
| Zeta zeros (10,142 computed) | avoid strongly | held in place | 19 of 19 | dip, dip, dip on every loop |
| Particle in a box (control) | random | none | chance level | mixed |
| Hydrogen in a strong magnet (355 levels) | avoid | partial | no: paths traced, ratios unrelated | mixed |
| String, both ends fixed | (even) | (even) | n/a | peak, peak, peak |
| String, one end free | (even) | (even) | n/a | dip, peak, dip |
| Two hydrogens joined | random | none | no | n/a |
| Engine flashes (one-cell, 20,000 ticks) | n/a | n/a | prime gaps no different from composite | n/a |

## What came out of it

**The zeros' loops are the primes, and only the primes.** Every strong loop sits at log of a prime or prime power, and each one dips at the depth the primes alone predict.

**Hydrogen is chaotic but not prime-built.** Its levels avoid each other, and its loops are real electron paths (15 of 20 matched to traced paths). But its new paths come in no particular ratio. A near match to log 3 / log 2 turned out to be half of a neighbouring feature.

**The minus sign is global.** A wall that flips a wave makes dips that alternate trip to trip: both strings show this. The zeros dip on every run of every loop. No flip can do that. The loops subtract from the levels instead of adding to them: the zeros behave like what the system *cannot* hold. Holes, not states.

**Holes on a pixel ring are the prime powers.** `origin holes`: on a ring of n pixels, which patterns can be built from smaller repeating patterns? Overlapping by adding builds nothing. Overlapping by multiplying (a pixel lit only where every pattern is lit, a gate) builds everything except the primes and prime powers, checked to n = 150. That is exactly the set of loop lengths in the zeros.

**A gate world falls silent at the zeros, but only at the halfway weight.** One hole per prime, joined by multiplying, so state n costs log n. Ring every state at once, each weighted by 1/√n: the total goes completely silent at exactly the zeta zeros (13 of 13 below 60). Weighted by 1/n^0.4 or 1/n^0.6 it never goes fully silent (quietest spots 5 to 10% of average). This is the zeta function written as a gate world, so the match is built in. What it shows is where the ½ comes from: each state's strength must fall off as one over the square root of its size.

**Joining independent pieces kills avoidance.** Two hydrogens taken together have random gaps. So the gate world's own levels (log n) are not zeta-like. Its *silences* are. The zeros are not states of the prime world; they are the frequencies at which all its states cancel.

**The engine's flashes carry no prime structure (yet).** Gaps between a pixel's flashes are 88% even (an every-other-tick rhythm), and prime-length gaps sit on the same smooth curve as composite ones (difference 0.001 against a spread of 0.016).

## Open

- What physical rule makes every state's strength fall as 1/√(size)? That is the "½" on the critical line, seen from the gate side.
- What in the pixel engine combines by multiplying (a gate) rather than adding? A flash is a fill event that changes a pixel's identity and its difference from its neighbours. If flashes are the gate, the engine would need recurrences that only close at whole-number stretches. It doesn't show that now.
- The holes need a filled background to be holes in. For numbers it is everything multiplication can build. Physically: unknown.

## Rerun

```
cd origin
zig build -Doptimize=ReleaseFast
./zig-out/bin/origin levels            # zeros and box
./zig-out/bin/origin levels hydrogen   # about 2 minutes
./zig-out/bin/origin levels strings
./zig-out/bin/origin levels gates      # gate world + silences
./zig-out/bin/origin levels pair       # two hydrogens joined, about 2 minutes
./zig-out/bin/origin holes 150
./zig-out/bin/origin record mode=lattice display=one_cell ticks=20000   # flash gaps in results/runs/.../gaps.csv
```

## Does the engine flash at the halfway falloff? (`origin scaling`)

The ½ in the gate world means each state's strength falls as 1/√(size): members held together as one identity but each keeping its own timing. Measured on the 3D lattice: cubes of n pixels (1 to 13,824), wobble of the flash count per window, fit wobble ~ n^a. Controls land exactly: independent 0.500, in step 1.000.

| Display rule | Window (ticks) | a, all flashes | a, identity groups | Pixels per identity group |
|---|---|---|---|---|
| one_cell | 2 | 0.69 | 0.68 | 1.07 |
| one_cell | 8 | 0.75 | 0.74 | 1.07 |
| one_cell | 32 | 0.79 | 0.78 | 1.07 |
| one_cell | 128 | 0.82 | 0.81 | 1.07 |
| flip_all | 2 | 0.73 | 0.72 | 1.20 |

(hold and fill_empty flash every pixel every tick, so they say nothing here.)

Reading: the engine's regions are more in step than halfway at every scale, and more so over longer windows: flashes travel as waves, so neighbours share timing. Identity groups barely form (about one pixel each), so counting by identity changes almost nothing. Under the current rules, identity does not yet bind pixels into one thing. The halfway falloff does not appear.

### With the neutrino carrying what was not displayed (photograph mode)

Photograph mode (rules 12-16): the flash emits a neutrino made of the pixel's unrealized possibilities, and it is delivered by identity, not by space: `same` = to pixels showing the same pattern, `unreal` = to pixels showing one of the patterns left undisplayed. It arrives as conserved share. `none` = emitted but no effect (baseline; identical to the plain sweep update).

| Mode | a, all flashes (window 2 / 32) | a, identity groups (window 2 / 32) |
|---|---|---|
| none (baseline) | 0.69 / 0.76 | 0.66 / 0.75 |
| same | 0.73 / 0.86 | 0.62 / 0.76 |
| unreal | 0.74 / 0.85 | 0.59 / 0.69 |

With delivery to the undisplayed patterns, counting by identity pulls toward ½ while counting raw flashes pulls toward lockstep: identity now matters. Step by step in size (unreal, window 2, 12,000 ticks), the identity exponent is 0.52 (1 to 8 pixels), 0.53 (8 to 64), 0.58 (64 to 512), then 0.72 and 0.89 at the largest cubes, where a lattice-wide wave takes over. So: halfway at small scales when the neutrino carries the undisplayed, lockstep at large scales.
