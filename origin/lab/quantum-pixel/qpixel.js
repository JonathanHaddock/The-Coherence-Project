// ORIGIN lab: a quantum version of origin's pixel. This one IS origin's idea (three cells per pixel, kind set by
// the filled count), made quantum and given gauge fields, so its results bear directly on origin's design.
//
// A 1D open chain of L pixels. Each pixel has three fermionic cells, one per colour (r, g, b): 3L fermion modes,
// so a pixel has 2^3 = 8 states, and its kind is set by the filled count n = 0..3.
// Charges:
//   colour   - the cells are a colour triplet, so n = 1 is a triplet, n = 2 an antitriplet, n = 0 and 3 singlets.
//   electric - a table q[n] (in units of e). Two designs are compared:
//              FUREY  q = n/3            : nu, anti-down (+1/3), up (+2/3), positron (+1)   (arXiv 1603.04078)
//              ORIGIN q = 0,-1/3,+2/3,-1 : nu, down, up, electron                            (origin's pixel table)
// Gauge fields: in 1D with open ends the Gauss law fixes the field on every link from the charges to its left,
// so the fields are not separate variables. The energy of the field on link l (between pixels l and l+1; the
// last link runs from pixel L-1 out to infinity) is
//   (g2/2) * C2(colour charge of pixels 0..l)  +  (e2/2) * (electric charge of pixels 0..l)^2
// where C2 is the SU(3) Casimir. A lone colour charge drags flux to infinity: that is confinement.
// Motion, two designs:
//   H1 "cells move":  -t sum_{x,a} (c+_{x+1,a} c_{x,a} + h.c.)        (cells are partons; the gauge links are
//                     gauge-fixed to 1, allowed in 1D with open ends)
//   H2 "pixels move": a whole pixel hops into a neighbouring empty pixel (cells are an internal label)
// Fermion signs by Jordan-Wigner order (mode index 3x + a).
(function (root) {
  const pc = s => { let c = 0; while (s) { s &= s - 1; c++; } return c; };
  const TABLES = { furey: [0, 1 / 3, 2 / 3, 1], origin: [0, -1 / 3, 2 / 3, -1] };
  const NAMES = { furey: ["nu", "anti-down", "up", "positron"], origin: ["nu", "down", "up", "electron"] };
  // c+_i c_j |s>: returns [s', sign] or null
  function hop(s, i, j) {
    if (!((s >> j) & 1)) return null; let t = s & ~(1 << j), sign = pc(s & ((1 << j) - 1)) & 1 ? -1 : 1;
    if ((t >> i) & 1) return null; sign *= pc(t & ((1 << i) - 1)) & 1 ? -1 : 1; return [t | (1 << i), sign];
  }
  function basis(L, N) { const out = []; for (let s = 0; s < 1 << (3 * L); s++) if (pc(s) === N) out.push(s); return out; }
  const nAt = (s, x) => pc((s >> (3 * x)) & 7);
  // C2 of the colour charge on the pixel set [0..l], acting on |s>, by the Fierz identity
  // sum_a T^a_bc T^a_de = 1/2 (d_be d_cd - 1/3 d_bc d_de):  C2 = 1/2 sum_{x,y} [ sum_{b,c} c+_{xb} c_{xc} c+_{yc} c_{yb} - n_x n_y / 3 ]
  function casimirApply(s, l, out, w) {
    let diag = 0; for (let x = 0; x <= l; x++) for (let y = 0; y <= l; y++) diag -= nAt(s, x) * nAt(s, y) / 6;
    if (diag) out.set(s, (out.get(s) || 0) + w * diag);
    for (let x = 0; x <= l; x++) for (let y = 0; y <= l; y++) for (let b = 0; b < 3; b++) for (let c = 0; c < 3; c++) {
      const r1 = hop(s, 3 * y + c, 3 * y + b); if (!r1) continue; const r2 = hop(r1[0], 3 * x + b, 3 * x + c); if (!r2) continue;
      out.set(r2[0], (out.get(r2[0]) || 0) + w * 0.5 * r1[1] * r2[1]);
    }
  }
  function hamiltonian({ L, N, t = 1, g2 = 1, e2 = 0.1, table = "furey", motion = "cells", mass = 0 }) {
    const B = basis(L, N), index = new Map(B.map((s, i) => [s, i])), q = TABLES[table];
    const rows = B.map(s => {
      const out = new Map();
      // field energy on links 0..L-1 (the last one runs to infinity)
      let em = 0, acc = 0; for (let l = 0; l < L; l++) { acc += q[nAt(s, l)]; em += acc * acc; }
      let m = 0; for (let x = 0; x < L; x++) m += mass * (nAt(s, x) > 0 ? 1 : 0);
      out.set(s, e2 / 2 * em + m);
      for (let l = 0; l < L; l++) casimirApply(s, l, out, g2 / 2);
      if (motion === "cells") { for (let x = 0; x + 1 < L; x++) for (let a = 0; a < 3; a++) for (const [i, j] of [[3 * (x + 1) + a, 3 * x + a], [3 * x + a, 3 * (x + 1) + a]]) { const r = hop(s, i, j); if (r) out.set(r[0], (out.get(r[0]) || 0) - t * r[1]); } }
      else { for (let x = 0; x + 1 < L; x++) { const bx = (s >> (3 * x)) & 7, by = (s >> (3 * (x + 1))) & 7; if ((bx === 0) === (by === 0)) continue; // exactly one empty
          const sw = (s & ~(63 << (3 * x))) | (by << (3 * x)) | (bx << (3 * (x + 1))), sign = (pc(bx) * pc(by)) & 1 ? -1 : 1; // swapping adjacent blocks: (-1)^(nx*ny) (= +1 here, one is empty)
          out.set(sw, (out.get(sw) || 0) - t * sign); } }
      return [...out.entries()].filter(([, v]) => Math.abs(v) > 1e-14).map(([k, v]) => [index.get(k), v]);
    });
    const apply = v => { const o = new Float64Array(v.length); rows.forEach((r, i) => { let acc2 = 0; for (const [j, h] of r) acc2 += h * v[j]; o[i] = acc2; }); return o; };
    return { B, index, rows, apply, q };
  }
  // Lanczos ground state (energy + vector), full reorthogonalisation
  function ground(apply, n, iters = 300, seed = 7) {
    iters = Math.min(iters, n); let r = seed; const rnd = () => (r = (r * 16807) % 2147483647) / 2147483647 - 0.5;
    let v = Float64Array.from({ length: n }, rnd); let nv = Math.hypot(...v); v = v.map(x => x / nv); const Q = [v], a = [], b = [];
    for (let j = 0; j < iters; j++) { let w = apply(Q[j]); const al = w.reduce((s, x, i) => s + x * Q[j][i], 0); a.push(al);
      for (let pass = 0; pass < 2; pass++) for (const qq of Q) { const d = w.reduce((s, x, i) => s + x * qq[i], 0); for (let i = 0; i < w.length; i++) w[i] -= d * qq[i]; }
      const be = Math.hypot(...w); if (be < 1e-10 || j === iters - 1) break; b.push(be); Q.push(w.map(x => x / be)); }
    const m = a.length, T = Array.from({ length: m }, (_, i) => Array.from({ length: m }, (_, j) => i === j ? a[i] : Math.abs(i - j) === 1 ? b[Math.min(i, j)] : 0));
    const V = Array.from({ length: m }, (_, i) => Array.from({ length: m }, (_, j) => i === j ? 1 : 0));
    for (let sw = 0; sw < 100; sw++) { let off = 0; for (let i = 0; i < m; i++) for (let j = i + 1; j < m; j++) off += T[i][j] ** 2; if (off < 1e-24) break;
      for (let p = 0; p < m; p++) for (let q2 = p + 1; q2 < m; q2++) { if (Math.abs(T[p][q2]) < 1e-16) continue; const th = 0.5 * Math.atan2(2 * T[p][q2], T[q2][q2] - T[p][p]), c = Math.cos(th), s = Math.sin(th);
        for (let k = 0; k < m; k++) { const x = T[k][p], y = T[k][q2]; T[k][p] = c * x - s * y; T[k][q2] = s * x + c * y; } for (let k = 0; k < m; k++) { const x = T[p][k], y = T[q2][k]; T[p][k] = c * x - s * y; T[q2][k] = s * x + c * y; }
        for (let k = 0; k < m; k++) { const x = V[k][p], y = V[k][q2]; V[k][p] = c * x - s * y; V[k][q2] = s * x + c * y; } } }
    let k0 = 0; for (let i = 1; i < m; i++) if (T[i][i] < T[k0][k0]) k0 = i;
    const vec = new Float64Array(n); for (let j = 0; j < m; j++) { const c = V[j][k0]; for (let i = 0; i < n; i++) vec[i] += c * Q[j][i]; }
    const nn = Math.hypot(...vec); return { E: T[k0][k0], vec: vec.map(x => x / nn), sorted: T.map((r2, i) => r2[i]).sort((x, y) => x - y) };
  }
  const api = { pc, hop, basis, nAt, casimirApply, hamiltonian, ground, TABLES, NAMES };
  if (typeof module !== "undefined") module.exports = api; else root.QPixel = api;
})(this);
