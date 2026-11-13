# Earth's war record on the engine: all parameters

This covers 96 runs:

- **Settings:** 4 display rules × sync/sweep × gravity on/off = 16 settings.
- **Seeds:** 3 per setting (20261110, 2, 3).
- **Two worlds per setting and seed:**
  - **real:** the 3,708 conflicts from 1400–2000 in Brecke's catalog, then 200 years of peace.
  - **nudge:** the control. No wars, only one cell of one pixel flipped in 1400.

Both are measured against an untouched twin. The full table is in `summary.tsv`, and running `python3 analyze.py` rebuilds it. All 96 runs completed.

## The columns

| Column | Meaning |
|---|---|
| `div` | % of pixels different from the twin. 87.5% means as different as two unrelated worlds. |
| `gap` | Flash rate among pixels **not** inside an active war, minus the twin's flash rate. This measures restlessness spreading outside the fighting. `gap_war` is averaged over 1800–2000; `gap_after` over 2100–2200. |
| `agr` | Neighbour agreement, war world minus twin. Positive means the world is more uniform. |

## 1. Half the settings can't register anything

| Setting | What happens | Effect on war |
|---|---|---|
| `hold`, all 4 variants | Every pixel flashes every tick (runaway). | 0.0% divergence, no change at all. |
| `fill_empty`, all 4 variants | Runaway flashing at 89–100%. | Either nothing changes (0–1%) or the world fully scrambles (87.5%), and the nudge control does the same. |

War can't change these worlds, or changes them only as noise. The results below use the 8 settings that stay alive (`one_cell`, `flip_all`).

## 2. In all 8 live settings, the war world ends up different in kind

Values are the mean across 3 seeds. The control rows are all close to 0 (within ±0.008).

| Setting | div 2000, real (nudge) | gap during wars | gap after 200 yrs peace | agreement after |
|---|---|---|---|---|
| one_cell · sync · gravity | 43% (36%) | **+0.036** | **+0.026** | +0.002 |
| one_cell · sync · no grav | 50% (28%) | +0.024 | **−0.012** | **+0.015** |
| one_cell · sweep · gravity | 36% (33%) | +0.008 | −0.008 | +0.003 |
| one_cell · sweep · no grav | 44% (31%) | +0.013 | −0.015 | **+0.010** |
| flip_all · sync · gravity | 39% (30%) | **+0.037** | **+0.023** | +0.003 |
| flip_all · sync · no grav | 47% (23%) | +0.009 | **−0.026** | **+0.016** |
| flip_all · sweep · gravity | 20% (**0%**) | +0.007 | −0.001 | +0.004 |
| flip_all · sweep · no grav | 23% (**0%**) | +0.005 | −0.002 | +0.005 |

These patterns hold across every seed, with two exceptions where the min–max range in `summary.tsv` touches or crosses zero: flip_all · sweep, no gravity, during the wars (+0.000 to +0.008), and both flip_all · sweep rows after the wars, which are effectively 0.

- **During the war era:** in all 8 live settings, the world outside the fighting flashes more than in peace.
- **After the wars stop:**
  - **With gravity (sync):** the restlessness stays. Two hundred years of peace bring it down by only about a third.
  - **Without gravity:** it flips the other way. The world becomes quieter than it would have been.
- **Agreement:** the war world becomes **more uniform** in all 8 live settings and stays that way after the wars, most strongly without gravity (+0.010 to +0.016). The controls stay at 0.
- **Divergence:** real exceeds the nudge in all 8. The cleanest case is **flip_all · sweep**, which is not chaotic: one flipped cell changes nothing (0% in every seed). There, the 20–23% difference is entirely the wars' own mark, and 200 years of peace don't reduce it at all.

## 3. Does it level off?

The world never heals: in all 8 live settings divergence doesn't fall during the 200 years of peace. It still creeps up slightly, by 0.3–1.7 points, except in flip_all · sweep (no gravity), where it holds flat at 23%.

## Limits

- The mapping is mine: 1 tick = 1 year, war size from the log of the death toll, and regions placed in fixed neighbourhoods rather than by geography.
- About two-thirds of the conflicts have no death toll listed and get a small default size.
- "War" is modelled only as forced flashing, the outside trigger the spec allows. Nothing else about war is in the engine.
- All runs use core 0 (no mass) on the 48³ lattice.
