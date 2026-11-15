# A sun and an open edge (2026-11-14)

Question (Jono): does the world go dark under EM (rule 25) because nothing feeds it? Would a sun keep it going?

These are outside conditions, not rules, so `RULES.md` is unchanged. They are written here before the runs:
- **Sun:** the centre site and its 6 neighbours (7 pixels) are forced to flash every tick.
- **Open edge:** everything lost at the box edge each tick (carrier, and φ when EM is on) is fed back in, spread evenly over every site on the box surface. Closed = lost, as in rule 5.

Fixed for every run: one_cell · sync, core 0, motion (rule 24) on, 3,000 ticks, seeds 1–3. Runs on the one-pixel model (`origin/viewer/pixel-model.js`, Field). With no conditions set, Field still matches engine.js exactly (`origin/scripts/pixel-parity.js`).

```sh
node run.js on open on 1 3000      # sun, edge, em, seed, ticks
cat commands.txt | sed 's/^node run.js //' | xargs -P 8 -L 1 node run.js   # all 24 runs
```

| File | What it holds |
|---|---|
| `over-time.tsv` | every 100 ticks, every run: flashing, swaps, carrier in the box |
| `table.tsv` | flashing at ticks 500, 1000, 2000 and 3000, mean of 3 seeds |

## Results (share of pixels flashing)

| sun | edge | EM | t500 | t1000 | t2000 | t3000 |
|---|---|---|---|---|---|---|
| off | closed | off | 0.056 | 0.043 | 0.040 | 0.033 |
| off | closed | **on** | 0.023 | 0.002 | **0** | **0** |
| off | open | off | 0.181 | 0.163 | 0.141 | 0.128 |
| off | open | **on** | 0.026 | 0.002 | **0** | **0** |
| on | closed | off | 0.054 | 0.029 | 0.043 | 0.036 |
| on | closed | **on** | 0.035 | 0.006 | 0.0002 | 0.0001 |
| on | open | off | 0.185 | 0.161 | 0.143 | 0.130 |
| on | open | **on** | 0.023 | 0.003 | 0.0004 | 0.0001 |

All three seeds agree. With EM on and the sun on, 0.0001 is about 7 pixels: the sun itself and nothing else.

## What happened

- **Neither the sun nor the open edge, nor both together, keeps the EM world going.** It goes dark in every case. Only the 7 forced sun pixels keep flashing.
- **Without EM, the open edge makes the world about 4× busier** (0.13 against 0.03 at tick 3,000). The sun alone changes little.
- **Carrier floods the box but does nothing.** With the edge open, about 30 million units of carrier build up in the box, and the EM world still goes dark. In rules 1–5 carrier is measurement only: pixels don't respond to it unless rule 6 (gravity) or rule 23 (three carriers) is on. A pixel only flashes from what it hears its neighbours flash.

## Reading

Of the two readings (the world needs a source, or rule 25 itself is wrong), this points to **rule 25**. Feeding the world doesn't wake it, because once EM has put every charge where it is most settled, nothing in the rules turns incoming carrier into a flash.

Not tested yet: a sun whose carrier can act on pixels (sun + rule 6 or rule 23 on), and a sun of neutrinos (photograph mode, rules 14–16).
