# Rules 34–35: strings cost energy and break (2026-11-19)

Jono chose "yes": strings stretch when paid for, and break into a quark–antiquark pair (Kogut–Susskind energy; string breaking in lattice QCD).

**Rule 34 alone** (`compare/`, `seeds/`): Zig = JS in 6 settings, Gauss law exact, but the world ran away (memory 0.29M → 45M, quarks 3.9k → 107k by tick 600). Rule 31's flash exchanges stretched strings for free (49M units of string energy by tick 600), and rule 34 turned that into carrier and memory as strings relaxed and broke. A perpetual-motion hole.

**Rule 35** closes it: exchanges pay for the string energy they add, out of the flasher's released memory (`compare35/`): Zig = JS in 6 settings; memory + carrier + string energy + edge loss balances to rounding.

Results (`runs35/summary.txt`):

| core 10, 300 ticks, 4 seeds | quark mean radius growth |
|---|---|
| colour off (rules 32–33) | +0.49 to +0.53 |
| free strings (rules 32–33) | +0.38 to +0.42 |
| strings cost energy (rules 34–35) | +0.010 to +0.018 |

- Quarks now stay where they are. String energy rises about 50%: strings stretch when something pays.
- Strings rarely break in the core runs (0–4 per run). There isn't enough energy where the strings are.
- The world still cools: flashing 10.5k at tick 50, 1.4k at 300, 145 at 600 (2.1k with EM).
- Random start: the start's long strings break, 12,539 times; quarks 88k → 108k; string energy 1.53M → 0.23M becomes memory and carrier.

Open: 1 unit of string energy = 1 unit of memory (default). With this exchange rate, the core is too cold to break strings. That is the knob Jono may want to look at, though changing it would be a number.
