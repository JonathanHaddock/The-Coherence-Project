// ORIGIN lab: causal sets. Standard physics, separate from origin's pixel rules.
// Bombelli, Lee, Meyer & Sorkin; Dowker, Henson & Sorkin (gr-qc/0311055): spacetime as a set of points with
// only a "before/after" order. Points are sprinkled at random (Poisson) at density rho, which keeps Lorentz
// invariance; a regular lattice does not. Everything here is 1+1 dimensional, in light-cone coordinates
// u = t + x, v = t - x (a boost is u -> e^eta u, v -> e^-eta v; p precedes q iff u_p < u_q and v_p < v_q).
//
// node run.js   -> checks and results (about a minute)
let fail = 0; const ok = (n, c, d) => { console.log(`${c ? "PASS" : "FAIL"}  ${n}  ${d}`); if (!c) fail++; };
function rng(seed) { let a = seed >>> 0 || 1; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
const R = rng(2026);
const poisson = lam => { if (lam > 50) return Math.max(0, Math.round(lam + Math.sqrt(lam) * Math.sqrt(-2 * Math.log(R() || 1e-12)) * Math.cos(2 * Math.PI * R()))); let L = Math.exp(-lam), k = 0, p = 1; do { k++; p *= R(); } while (p > L); return k - 1; };
const mean = v => v.reduce((a, b) => a + b, 0) / v.length;
const variance = v => { const m = mean(v); return v.reduce((s, x) => s + (x - m) ** 2, 0) / (v.length - 1); };

// longest chain = longest increasing subsequence of v after sorting by u (patience sorting, n log n)
function longestChain(pts) { const s = pts.slice().sort((a, b) => a[0] - b[0]), tails = [];
  for (const [, v] of s) { let lo = 0, hi = tails.length; while (lo < hi) { const m = (lo + hi) >> 1; if (tails[m] < v) lo = m + 1; else hi = m; } tails[lo] = v; } return tails.length; }
// number of links (relations with nothing in between) from each element to its future
function linksPerElement(pts) { const s = pts.slice().sort((a, b) => a[0] - b[0]), n = s.length; let total = 0;
  for (let i = 0; i < n; i++) { const vi = s[i][1]; let minV = Infinity; for (let j = i + 1; j < n; j++) { const vj = s[j][1]; if (vj <= vi) continue; if (vj < minV) { total++; minV = vj; } } }
  return total / n; }

// ---------- checks ----------
{ // the link finder against brute force on small sets
  let worst = 0; for (let rep = 0; rep < 5; rep++) { const pts = Array.from({ length: 120 }, () => [R(), R()]); let brute = 0;
    for (const p of pts) for (const q of pts) { if (!(p[0] < q[0] && p[1] < q[1])) continue; let between = false; for (const r of pts) if (p[0] < r[0] && r[0] < q[0] && p[1] < r[1] && r[1] < q[1]) { between = true; break; } if (!between) brute++; }
    worst = Math.max(worst, Math.abs(brute / pts.length - linksPerElement(pts))); }
  ok("link counting = brute force", worst < 1e-12, `5 random sets of 120 points: largest difference ${worst}`);
}
{ // longest chain against brute-force dynamic programming
  let bad = 0; for (let rep = 0; rep < 20; rep++) { const pts = Array.from({ length: 200 }, () => [R(), R()]), s = pts.slice().sort((a, b) => a[0] - b[0]), L = new Array(s.length).fill(1);
    for (let i = 0; i < s.length; i++) for (let j = 0; j < i; j++) if (s[j][1] < s[i][1]) L[i] = Math.max(L[i], L[j] + 1); if (Math.max(...L) !== longestChain(pts)) bad++; }
  ok("longest chain = brute force", bad === 0, "20 random sets of 200 points");
}
{ // a boost preserves the order exactly (so chains, links and interval counts are frame-independent)
  const pts = Array.from({ length: 2000 }, () => [R(), R()]), eta = 2.3, b = pts.map(([u, v]) => [u * Math.exp(eta), v * Math.exp(-eta)]);
  ok("boosts preserve the causal order", longestChain(pts) === longestChain(b) && Math.abs(linksPerElement(pts) - linksPerElement(b)) < 1e-12, "chain length and link count unchanged under a boost of rapidity 2.3");
}

// ---------- result 1: random vs regular, seen from a moving frame ----------
console.log("\nRESULT 1: count points in fixed boxes of area 4 (expect 4 per box) in a frame moving at rapidity eta.");
console.log("  A Poisson process has variance/mean = 1 and a share of empty boxes e^-4 = 0.018 in every frame.");
console.log("  eta    | random: var/mean  empty   | lattice: var/mean  empty");
const results1 = [];
for (const eta of [0, 0.5, 1, 2, 3]) {
  const W = 40, cells = 400, A = 4; // count in a W x W window of the moving frame (t', x'), boxes 2 x 2
  const count = (genPts) => { const c = new Array(cells).fill(0); for (const [u, v] of genPts) { const up = u * Math.exp(-eta), vp = v * Math.exp(eta), t = (up + vp) / 2, x = (up - vp) / 2;
      if (t < 0 || t >= W || x < 0 || x >= W) continue; c[Math.floor(t / 2) * 20 + Math.floor(x / 2)]++; } return c; };
  // generate points that cover the window's preimage: window corners in (u', v') -> back to (u, v)
  const corners = [[0, 0], [W, 0], [0, W], [W, W]].map(([t, x]) => [(t + x) * Math.exp(eta), (t - x) * Math.exp(-eta)]);
  const uMin = Math.min(...corners.map(c => c[0])), uMax = Math.max(...corners.map(c => c[0])), vMin = Math.min(...corners.map(c => c[1])), vMax = Math.max(...corners.map(c => c[1]));
  // density 1 per unit of (t,x) area = 1/2 per unit of (u,v) area (du dv = 2 dt dx)
  const n = poisson(0.5 * (uMax - uMin) * (vMax - vMin)), rand = Array.from({ length: n }, () => [uMin + R() * (uMax - uMin), vMin + R() * (vMax - vMin)]);
  const lat = []; for (let i = Math.floor(uMin / Math.SQRT2); i <= Math.ceil(uMax / Math.SQRT2); i++) for (let j = Math.floor(vMin / Math.SQRT2); j <= Math.ceil(vMax / Math.SQRT2); j++) lat.push([(i + 0.5) * Math.SQRT2, (j + 0.5) * Math.SQRT2]); // spacing sqrt2 in u,v = density 1 in t,x
  const cr = count(rand), cl = count(lat), er = cr.filter(x => !x).length / cells, el = cl.filter(x => !x).length / cells;
  results1.push({ eta, rv: variance(cr) / mean(cr), re: er, lv: variance(cl) / mean(cl), le: el, rm: mean(cr), lm: mean(cl) });
  console.log(`  ${eta.toFixed(1)}    |  ${(variance(cr) / mean(cr)).toFixed(2)}  (mean ${mean(cr).toFixed(2)})  ${er.toFixed(3)}   |  ${(variance(cl) / mean(cl)).toFixed(2)}  (mean ${mean(cl).toFixed(2)})  ${el.toFixed(3)}`);
}
ok("random sprinkling looks the same in every frame", results1.every(r => Math.abs(r.rv - 1) < 0.25 && r.re < 0.05), "var/mean stays near 1 and empty boxes near e^-4 for every rapidity");
ok("the regular lattice does not", results1.some(r => r.lv > 3 || r.le > 0.3), `at rapidity 3: var/mean ${results1[4].lv.toFixed(2)}, empty boxes ${(100 * results1[4].le).toFixed(0)}%`);

// ---------- result 2: the longest chain measures proper time: L -> 2 sqrt(N) ----------
console.log("\nRESULT 2: longest chain in an interval of N points (proper time). Theory: E[L] = 2 sqrt(N) - 1.771 N^(1/6) + ...");
const r2 = [];
for (const N of [1000, 10000, 100000]) { const Ls = []; for (let rep = 0; rep < (N > 50000 ? 10 : 40); rep++) Ls.push(longestChain(Array.from({ length: N }, () => [R(), R()])));
  const m = mean(Ls), e = Math.sqrt(variance(Ls) / Ls.length), th = 2 * Math.sqrt(N) - 1.7711 * Math.pow(N, 1 / 6); r2.push([N, m, e, th]);
  console.log(`  N ${N}: L = ${m.toFixed(1)} ± ${e.toFixed(1)}   L/sqrt(N) = ${(m / Math.sqrt(N)).toFixed(4)}   with Tracy-Widom correction ${th.toFixed(1)}`); }
ok("longest chain = 2 sqrt(N) with the known correction", r2.every(([N, m, e, th]) => Math.abs(m - th) < 4 * e + 0.5 + 0.02 * Math.pow(N, 1 / 6)), "geometry (proper time) is read off from order and counting alone");

// ---------- result 3: the cost: links per element grow without bound ----------
console.log("\nRESULT 3: links to the future per element (nearest causal neighbours). On the regular lattice it is exactly 2.");
const r3 = [];
for (const N of [500, 1000, 2000, 4000, 8000, 16000]) { const vals = []; for (let rep = 0; rep < (N >= 8000 ? 3 : 8); rep++) vals.push(linksPerElement(Array.from({ length: N }, () => [R(), R()])));
  r3.push([N, mean(vals)]); console.log(`  N ${N}: ${mean(vals).toFixed(3)}`); }
const slope = (() => { const xs = r3.map(r => Math.log(r[0])), ys = r3.map(r => r[1]), mx = mean(xs), my = mean(ys); let a = 0, b = 0; xs.forEach((x, i) => { a += (x - mx) * (ys[i] - my); b += (x - mx) ** 2; }); return a / b; })();
console.log(`  growth: ${slope.toFixed(3)} more links per element each time ln N grows by 1`);
ok("random sprinkling: the number of nearest neighbours grows with size (nonlocal)", slope > 0.5, `links per element ~ ${slope.toFixed(2)} ln N`);
console.log(fail ? `\n${fail} check(s) failed` : "\nall checks passed"); process.exitCode = fail ? 1 : 0;
