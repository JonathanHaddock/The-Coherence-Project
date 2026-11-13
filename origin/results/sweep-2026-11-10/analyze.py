import csv, json, math, os, sys, statistics as st
from collections import defaultdict
root = sys.argv[1]
rows = []
for name in sorted(os.listdir(root)):
    d = os.path.join(root, name)
    m = json.load(open(os.path.join(d, "meta.json")))
    ser = list(csv.DictReader(open(os.path.join(d, "series.csv"))))
    T = m["ticks"]; lo = T * 2 // 3
    tail = [r for r in ser if int(r["tick"]) >= lo]
    fl = [float(r["flashing"]) for r in tail]
    mf = st.mean(fl); cv = st.pstdev(fl) / mf if mf > 0 else 0
    agr = st.mean(float(r["agreement"]) for r in tail)
    fill = [st.mean(float(r[f"filled{k}"]) for r in tail) for k in range(3)]
    # hazard: gaps 1..40 with enough counts
    gaps = [(int(r["gap"].rstrip("+")), int(r["count"]), float(r["hazard"])) for r in csv.DictReader(open(os.path.join(d, "gaps.csv")))]
    hz = [h for g, c, h in gaps if 1 <= g <= 40 and c >= 200]
    hcv = st.pstdev(hz) / st.mean(hz) if len(hz) >= 5 and st.mean(hz) > 0 else float("nan")
    odd = sum(c for g, c, h in gaps if g % 2 == 1); even = sum(c for g, c, h in gaps if g % 2 == 0)
    evenfrac = even / (odd + even) if odd + even else float("nan")
    # shells: last window
    sh = list(csv.DictReader(open(os.path.join(d, "shells.csv"))))
    last = max(int(r["tick_from"]) for r in sh)
    win = [r for r in sh if int(r["tick_to"]) >= lo]
    byd = defaultdict(lambda: [0.0, 0.0, 0])
    for r in win:
        b = byd[int(r["dist"])]; b[0] += float(r["flash_rate"]); b[1] += float(r["carrier"]); b[2] += 1
    core = m["core"]
    inside = [byd[k][0] / byd[k][2] for k in byd if k <= core and byd[k][2]]
    outside = [byd[k][0] / byd[k][2] for k in byd if core + 3 <= k <= 20 and byd[k][2]]
    ratio = (st.mean(inside) / st.mean(outside)) if core and inside and outside and st.mean(outside) > 0 else float("nan")
    pts = [(math.log(k), math.log(byd[k][1] / byd[k][2])) for k in byd if (core + 3 if core else 3) <= k <= 19 and byd[k][2] and byd[k][1] > 0]
    slope = float("nan")
    if len(pts) > 3:
        mx = st.mean(p[0] for p in pts); my = st.mean(p[1] for p in pts)
        den = sum((p[0] - mx) ** 2 for p in pts)
        slope = sum((p[0] - mx) * (p[1] - my) for p in pts) / den if den else float("nan")
    key = (m["mode"], m.get("display"), m.get("update"), core, m.get("gravity"), m["name"].split("_p")[1].split("_")[0] if m["mode"] == "control" else "")
    rows.append(dict(key=key, seed=m["seed"], name=name, flash=mf, cv=cv, agree=agr, fill=fill, hcv=hcv, even=evenfrac, core_ratio=ratio, slope=slope))
groups = defaultdict(list)
for r in rows: groups[r["key"]].append(r)
def ms(v):
    v = [x for x in v if not math.isnan(x)]
    if not v: return "n/a"
    return f"{st.mean(v):.3f}±{(st.pstdev(v) if len(v)>1 else 0):.3f}"
out = []
for k, g in groups.items():
    out.append(dict(setting=" ".join(str(x) for x in k if x not in ("", None)), n=len(g),
        flash=ms([r["flash"] for r in g]), cv=ms([r["cv"] for r in g]), agree=ms([r["agree"] for r in g]),
        meanfill=ms([sum(r["fill"]) / 3 for r in g]), hcv=ms([r["hcv"] for r in g]), even=ms([r["even"] for r in g]),
        core_ratio=ms([r["core_ratio"] for r in g]), slope=ms([r["slope"] for r in g]),
        _flash=st.mean(r["flash"] for r in g), _hcv=st.mean([r["hcv"] for r in g if not math.isnan(r["hcv"])] or [float("nan")]),
        _cr=st.mean([r["core_ratio"] for r in g if not math.isnan(r["core_ratio"])] or [float("nan")]),
        _slope=st.mean([r["slope"] for r in g if not math.isnan(r["slope"])] or [float("nan")]),
        _fill=st.mean(sum(r["fill"]) / 3 for r in g), _even=st.mean([r["even"] for r in g if not math.isnan(r["even"])] or [float("nan")])))
json.dump(out, open(sys.argv[2], "w"), indent=1)
hdr = ["setting","n","flash","cv","agree","meanfill","hcv","even","core_ratio","slope"]
print("\t".join(hdr))
for o in out: print("\t".join(str(o[h]) for h in hdr))
