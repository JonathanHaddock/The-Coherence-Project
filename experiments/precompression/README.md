# Chemical precompression on origin's lattice

The engine is unchanged and no rules were added. Everything here is an outside condition, like the war experiment.

## Mapping

| Physics | In origin |
|---|---|
| Superconducting order | neighbour agreement between free pixels (free–free bonds only; 0.5 = random) |
| Temperature T | each tick, each free pixel has chance T of one random cell flipping before the engine ticks |
| "Tc" | the T at which free-pixel agreement falls below 0.65 |
| Chemical precompression (`cage`) | 1 site in 8 (x, y, z all even) held at pattern 111 every tick, a regular cage around the free "hydrogen" sites |
| Control (`random`) | the same number of held sites at random positions |
| No precompression (`none`) | nothing held |

## Run it

```sh
node run.js one_cell sync off cage 0.3 1 600
#           display  update gravity cage|random|none  T  seed ticks
```

The output is one row: the settings, then free-pixel agreement and flash rate, averaged over the last third of the run.

The full grid is 8 live settings × 3 holds × 15 T levels (0–1) × 3 seeds = 1,080 runs. To rebuild it:

```sh
cat jobs.txt | xargs -P 8 -L 1 node run.js
```

| File | What it holds |
|---|---|
| `data.tsv` | every run |
| `tc.tsv` | Tc per setting |

## Results

Tc is where agreement falls below 0.65:

| Setting | none | cage | random | cage − none | cage − random |
|---|---|---|---|---|---|
| flip_all · sweep · gravity | 0.45 | 0.61 | 0.58 | **+0.15** | +0.022 |
| one_cell · sweep · no grav | 0.83 | 0.97 | 0.96 | **+0.14** | +0.009 |
| one_cell · sweep · gravity | 0.43 | 0.55 | 0.52 | **+0.12** | +0.028 |
| one_cell · sync · gravity | 0.35 | 0.42 | 0.41 | +0.07 | +0.005 |
| flip_all · sync · gravity | 0.38 | 0.44 | 0.43 | +0.06 | +0.009 |
| one_cell · sync · no grav | 0.48 | 0.52 | 0.52 | +0.04 | +0.002 |
| flip_all · sync · no grav | 0.50 | 0.53 | 0.53 | +0.03 | +0.001 |
| flip_all · sweep · no grav | >1 | >1 | >1 | n/a | n/a |

Per-seed differences agree to ±0.004 in every row.

- **Precompression raises Tc in all 7 measurable settings**, by +0.03 to +0.15. The biggest gain is +36%, in flip_all · sweep · gravity.
- **Most of the gain comes from how many sites are held, not their arrangement.** Random holds get 74–97% of the cage's gain. The regular cage still beats random in all 7 settings and all 3 seeds, by +0.001 to +0.028, largest with sweep update.
- **Order is very robust in this engine.** Even with every free pixel jostled every tick (T = 1), agreement stays above 0.5. In flip_all · sweep · no gravity it never falls below 0.65 at all.
- **Gravity (rule 6) makes order more fragile:** Tc drops to 0.35–0.45 with gravity on, against 0.48 to above 1 with gravity off.
- **Sweep update orders more robustly than sync.**

## Limits

- This is an analogy. Origin has no electrons, Cooper pairs or real temperature, and "order" here means neighbour agreement, not zero resistance.
- The cage pattern (111) and the 1-in-8 spacing are my choices. A different fixed pattern or density could change the size of the effect.
- Core 0, 48³ lattice, 600 ticks per run.
