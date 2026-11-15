# War history: running the sims yourself

Both scripts run your real engine (`origin/viewer/engine.js`, the JS port of grid3.zig) in Node. No rules are added. A "war" is an outside trigger: a region is forced to flash every tick.

You need Node; check with `node -v`. Run everything from this folder:

```sh
cd ~/workspace/The-Coherence-Project/experiments/war-history
```

## 1. One war (or a one-cell nudge) against an untouched twin

```sh
node one-war.js one_cell sync on war 1000
```

The arguments, in order (all optional; the defaults are shown above):

| # | What | Choices |
|---|---|---|
| 1 | display rule | `one_cell`, `flip_all`, `hold`, `fill_empty` |
| 2 | update | `sync`, `sweep` |
| 3 | gravity | `on`, `off` |
| 4 | what happens | `war` (radius-8 sphere forced for 30 ticks) or `nudge` (one cell of one pixel flipped) |
| 5 | ticks to run after | any number; about 1,000 ticks is roughly a minute |

It prints one number per 100 ticks: the % of pixels that differ from the twin.

## 2. Earth-like history: recurring wars

```sh
node history.js one_cell sync on 3000 1.5
```

Arguments 1–3 are the same as above. Then:

| # | What | Default |
|---|---|---|
| 4 | years to run (1 tick = 1 year) | 3000 |
| 5 | average new wars per year | 1.5 |

Each war gets a random location, a radius of 3–8, and a length of 1–10 years.

It prints one row every 100 years:

| Column | Meaning |
|---|---|
| `div%` | % of pixels different from the peaceful twin. Two unrelated worlds differ by 87.5%. |
| `agrWar`, `agrPeace` | neighbour agreement in each world (0.5 = random, 1 = identical) |
| `flashWar`, `flashPeace` | share of pixels flashing that year. The war number includes the pixels being forced. |
| `activeWars`, `%atWar` | how much war is going on right now |
| `%everTouched` | share of the world that has ever been inside a war |

## 3. Earth's real record, 1400–2000

```sh
node real.js one_cell sync on 200
```

This uses the 3,708 real conflicts in Brecke's Conflict Catalog (Georgia Tech), converted into `origin/viewer/earth-wars.js`. Each conflict starts in its real year and lasts its real length (1 tick = 1 year). Its size comes from its death toll: `radius = 1.5·log10(deaths) − 2`, kept between 2 and 11 cells, or 2.5 when no toll is listed. Each of the catalog's 12 regions gets a fixed spot in the lattice. That placement is not geography, just "same region = same neighbourhood".

Arguments 1–3 are the same as above. Argument 4 is how many years of peace to keep running after 2000.

The extra column `flashWar(outside wars)` counts flashing only among pixels that aren't being forced by a war that year. That is the honest restlessness number.

## Things to try

- **Change one thing at a time,** and compare against the run before.
- **Peace as a control:** set wars per year to `0`. `div%` should stay at 0.
- **Rarer or heavier history:** try `0.2` or `5` wars per year.
- **Another history:** the wars come from a fixed random sequence, set by the `rs=987654321` line in `history.js`. Change that number to get a different history. One run is not a result; try 3 or more.
- **Several runs at once** (append `&` to each command, then `wait`):

  ```sh
  node history.js one_cell sync on 3000 1.5 > a.txt & node history.js one_cell sync off 3000 1.5 > b.txt & wait
  ```

## Watching it

Open `origin/viewer/war.html` in the browser:

1. Pick "Earth's history" from the war menu.
2. Wait for the warm-up to finish.
3. Press **start war + nudge**.

The left view is the war world and the right view is a one-cell nudge, both compared against the same peaceful twin.
