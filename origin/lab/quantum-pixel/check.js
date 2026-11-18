// Checks for qpixel.js. node check.js  (a few seconds)
const { pc, hop, basis, casimirApply, hamiltonian } = require("./qpixel.js");
let fail = 0; const ok = (n, c, d) => { console.log(`${c ? "PASS" : "FAIL"}  ${n}  ${d}`); if (!c) fail++; };
// single fermion operators with Jordan-Wigner signs, for the anticommutator check
const cdag = (s, i) => ((s >> i) & 1) ? null : [s | (1 << i), pc(s & ((1 << i) - 1)) & 1 ? -1 : 1];
const cann = (s, i) => ((s >> i) & 1) ? [s & ~(1 << i), pc(s & ((1 << i) - 1)) & 1 ? -1 : 1] : null;
{ // {c_i, c+_j} = delta_ij and hop(i,j) = c+_i c_j, on all states of 6 modes
  let bad = 0;
  for (let s = 0; s < 64; s++) for (let i = 0; i < 6; i++) for (let j = 0; j < 6; j++) {
    const acc = new Map(), add = (r, w) => { if (r) acc.set(r[0], (acc.get(r[0]) || 0) + w * r[1]); };
    { const a = cdag(s, j); if (a) add(cann(a[0], i), a[1]); } { const a = cann(s, i); if (a) add(cdag(a[0], j), a[1]); }
    for (const [k, v] of acc) if (Math.abs(v - (i === j && k === s ? 1 : 0)) > 1e-12) bad++; if (i === j && !acc.has(s)) bad++;
    const h = hop(s, i, j), a = cann(s, j), b = a ? cdag(a[0], i) : null;
    if (!!h !== !!b || (h && (h[0] !== b[0] || h[1] !== a[1] * b[1]))) bad++;
  }
  ok("fermion algebra: {c_i, c+_j} = delta_ij, hop = c+_i c_j", bad === 0, "all 64 states of 6 modes");
}
// explicit Gell-Mann generators T^a = lambda^a / 2 (complex), for the Fierz and symmetry checks
const lam = [[[0, 1, 0], [1, 0, 0], [0, 0, 0]], null, [[1, 0, 0], [0, -1, 0], [0, 0, 0]], [[0, 0, 1], [0, 0, 0], [1, 0, 0]], null, [[0, 0, 0], [0, 0, 1], [0, 1, 0]], null, [[1, 0, 0], [0, 1, 0], [0, 0, -2]].map(r => r.map(v => v / Math.sqrt(3)))];
const im = { 1: [[0, -1, 0], [1, 0, 0], [0, 0, 0]], 4: [[0, 0, -1], [0, 0, 0], [1, 0, 0]], 6: [[0, 0, 0], [0, 0, -1], [0, 1, 0]] }; // lambda 2, 5, 7 = i * these
const T = Array.from({ length: 8 }, (_, a) => Array.from({ length: 3 }, (_, b) => Array.from({ length: 3 }, (_, c) => im[a] ? [0, im[a][b][c] / 2] : [lam[a][b][c] / 2, 0])));
function Qa(a, sites, vec) { // vec: Map state -> [re, im]; returns Q^a vec
  const out = new Map(); for (const [s, [vr, vi]] of vec) for (const x of sites) for (let b = 0; b < 3; b++) for (let c = 0; c < 3; c++) {
    const [tr, ti] = T[a][b][c]; if (!tr && !ti) continue; const r = hop(s, 3 * x + b, 3 * x + c); if (!r) continue;
    const o = out.get(r[0]) || [0, 0]; o[0] += r[1] * (tr * vr - ti * vi); o[1] += r[1] * (tr * vi + ti * vr); out.set(r[0], o); }
  return out; }
{ // the generators obey [T^a, T^b] = i f^abc T^c: check via the known f^123 = 1 on one pixel
  let worst = 0; for (let s = 0; s < 8; s++) { const v = new Map([[s, [1, 0]]]), ab = Qa(0, [0], Qa(1, [0], v)), ba = Qa(1, [0], Qa(0, [0], v)), c = Qa(2, [0], v);
    const keys = new Set([...ab.keys(), ...ba.keys(), ...c.keys()]); for (const k of keys) { const x = ab.get(k) || [0, 0], y = ba.get(k) || [0, 0], z = c.get(k) || [0, 0]; // [T1,T2] - i T3
      worst = Math.max(worst, Math.abs(x[0] - y[0] + z[1]), Math.abs(x[1] - y[1] - z[0])); } }
  ok("SU(3) algebra: [T1, T2] = i T3 on a pixel", worst < 1e-12, `largest deviation ${worst.toExponential(1)}`);
}
{ // Fierz form of C2 used in the model = sum_a Q^a Q^a with explicit generators, on all 64 states of 2 pixels, both prefixes
  let worst = 0;
  for (const l of [0, 1]) for (let s = 0; s < 64; s++) { const f = new Map(); casimirApply(s, l, f, 1); const sites = l ? [0, 1] : [0], e = new Map();
    for (let a = 0; a < 8; a++) for (const [k, v] of Qa(a, sites, Qa(a, sites, new Map([[s, [1, 0]]])))) { const o = e.get(k) || [0, 0]; o[0] += v[0]; o[1] += v[1]; e.set(k, o); }
    for (const k of new Set([...f.keys(), ...e.keys()])) { const x = f.get(k) || 0, y = e.get(k) || [0, 0]; worst = Math.max(worst, Math.abs(x - y[0]), Math.abs(y[1])); } }
  ok("colour Casimir (Fierz form) = sum_a Q^a Q^a", worst < 1e-12, `all 64 states of 2 pixels, largest deviation ${worst.toExponential(1)}`);
}
{ // Casimir of one pixel by filled count: 0, 4/3, 4/3, 0
  const vals = [0, 1, 2, 3].map(n => { const s = (1 << n) - 1, out = new Map(); casimirApply(s, 0, out, 1); return out.get(s) || 0; });
  ok("one pixel: C2 = 0, 4/3, 4/3, 0 for n = 0..3 (singlet, triplet, antitriplet, singlet)", vals.every((v, i) => Math.abs(v - [0, 4 / 3, 4 / 3, 0][i]) < 1e-12), vals.map(v => v.toFixed(4)).join(", "));
}
// Hamiltonian: Hermitian, and commutes with total colour (gauge symmetry) for both motions and tables
for (const motion of ["cells", "pixels"]) for (const table of ["furey", "origin"]) {
  const H = hamiltonian({ L: 3, N: 3, g2: 1.3, e2: 0.4, t: 0.7, table, motion }); let herm = 0;
  const dense = new Map(); H.rows.forEach((r, i) => r.forEach(([j, v]) => dense.set(i * H.B.length + j, v)));
  for (const [k, v] of dense) { const i = Math.floor(k / H.B.length), j = k % H.B.length; herm = Math.max(herm, Math.abs(v - (dense.get(j * H.B.length + i) || 0))); }
  let comm = 0; const rnd = (() => { let a = 3; return () => (a = (a * 16807) % 2147483647) / 2147483647 - .5; })(), v = Float64Array.from(H.B, rnd);
  const toMap = arr => new Map(H.B.map((s, i) => [s, [arr[i], 0]])), Happ = m => { const re = new Float64Array(H.B.length), imv = new Float64Array(H.B.length); for (const [s, [a, b]] of m) { re[H.index.get(s)] = a; imv[H.index.get(s)] = b; } const r = H.apply(re), i2 = H.apply(imv); return new Map(H.B.map((s, k) => [s, [r[k], i2[k]]])); };
  for (let a = 0; a < 8; a++) { const x = Happ(Qa(a, [0, 1, 2], toMap(v))), y = Qa(a, [0, 1, 2], toMap(H.apply(v))); for (const s of H.B) { const p = x.get(s) || [0, 0], q = y.get(s) || [0, 0]; comm = Math.max(comm, Math.abs(p[0] - q[0]), Math.abs(p[1] - q[1])); } }
  ok(`H (${motion} move, ${table} table) is Hermitian and colour-symmetric`, herm < 1e-12 && comm < 1e-10, `asymmetry ${herm.toExponential(1)}, [H, Q^a] ${comm.toExponential(1)}`);
}
console.log(fail ? `${fail} check(s) failed` : "all checks passed"); process.exitCode = fail ? 1 : 0;
