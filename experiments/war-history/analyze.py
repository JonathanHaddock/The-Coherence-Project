"""Summarise runs/ from real.js: war record vs no-war nudge control, per setting.
Usage: python3 analyze.py            (reads runs/*.txt, writes summary.tsv)
Numbers are averaged over years 1800-2000 (war era) and 2100-2200 (after the wars),
then mean and spread (min-max) across seeds."""
import glob, os, collections, statistics as st

runs = collections.defaultdict(dict)
for f in glob.glob(os.path.join(os.path.dirname(__file__) or ".", "runs", "*.txt")):
    name = os.path.basename(f)[:-4]
    if name.startswith("_"): continue
    d, u, g, mode, seed = name.split("-")
    rows = []
    for line in open(f):
        p = line.split()
        if p and p[0].isdigit():
            rows.append(dict(yr=int(p[0]), div=float(p[1]), aw=float(p[2]), ap=float(p[3]),
                             fw=float(p[4]), fp=float(p[5]), fo=float(p[6])))
    if not rows or rows[-1]["yr"] < 2200:
        print("incomplete:", name); continue
    def avg(k, a, b):
        v = [r[k] for r in rows if a <= r["yr"] <= b]; return sum(v) / len(v)
    runs[(d, u, g)][(mode, seed)] = dict(
        div2000=[r["div"] for r in rows if r["yr"] == 2000][0],
        div2200=rows[-1]["div"],
        gap_war=avg("fo", 1800, 2000) - avg("fp", 1800, 2000),     # restlessness outside war zones
        gap_after=avg("fo", 2100, 2200) - avg("fp", 2100, 2200),   # after the wars stop
        agr_war=avg("aw", 1800, 2000) - avg("ap", 1800, 2000),
        agr_after=avg("aw", 2100, 2200) - avg("ap", 2100, 2200),
        peace_flash=avg("fp", 2100, 2200))

def ms(vals, fmt):
    return f"{fmt(st.mean(vals))} [{fmt(min(vals))},{fmt(max(vals))}]"

keys = ["div2000", "div2200", "gap_war", "gap_after", "agr_war", "agr_after", "peace_flash"]
out = ["setting\tmode\tn\t" + "\t".join(keys)]
for s in sorted(runs):
    for mode in ("real", "nudge"):
        rs = [v for (m, _), v in runs[s].items() if m == mode]
        if not rs: continue
        cells = []
        for k in keys:
            vals = [r[k] for r in rs]
            cells.append(ms(vals, (lambda x: f"{x:.1f}") if k.startswith("div") else (lambda x: f"{x:+.3f}") if k != "peace_flash" else (lambda x: f"{x:.3f}")))
        out.append("-".join(s) + f"\t{mode}\t{len(rs)}\t" + "\t".join(cells))
open(os.path.join(os.path.dirname(__file__) or ".", "summary.tsv"), "w").write("\n".join(out) + "\n")
print("\n".join(out))
