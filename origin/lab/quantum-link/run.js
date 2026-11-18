// ORIGIN lab: U(1) quantum link model with spin-1/2 links (Chandrasekharan & Wiese, hep-lat/9609042).
// Standard physics, separate from origin's pixel rules. Each link of an L x L periodic square lattice holds ONE
// qubit: an electric flux of +1/2 or -1/2 (the smallest possible link, like an origin pixel cell).
//   Gauss law at every site: flux in = flux out (no charges)   -> the "ice rule": 2 in, 2 out
//   H = -J sum_p (U_p + U_p^dag) + lambda sum_p (U_p + U_p^dag)^2
// U_p flips a plaquette whose four fluxes circulate (counterclockwise <-> clockwise); (U + U^dag)^2 = 1 on
// flippable plaquettes, 0 otherwise. At lambda = J (the Rokhsar-Kivelson point) H is a sum of positive terms and
// the equal superposition of all states in a connected sector has energy exactly 0.
//
// node run.js   -> checks and results (about a minute)
let fail = 0; const ok = (n, c, d) => { console.log(`${c ? "PASS" : "FAIL"}  ${n}  ${d}`); if (!c) fail++; };
function lattice(L) {
  const ex = (x, y) => 2 * (((y + L) % L) * L + ((x + L) % L)), ey = (x, y) => ex(x, y) + 1, nl = 2 * L * L;
  const plaq = []; for (let y = 0; y < L; y++) for (let x = 0; x < L; x++) plaq.push([ex(x, y), ey(x + 1, y), ex(x, y + 1), ey(x, y)]); // bottom, right, top, left
  const flux = (s, l) => (s >> l & 1) ? 1 : -1; // bit 1 = +1/2 along the link's direction (+x or +y)
  const gaussOK = s => { for (let y = 0; y < L; y++) for (let x = 0; x < L; x++) if (flux(s, ex(x, y)) + flux(s, ey(x, y)) - flux(s, ex(x - 1, y)) - flux(s, ey(x, y - 1)) !== 0) return false; return true; };
  // circulation of plaquette p: +1 counterclockwise (bottom +x, right +y, top -x, left -y), -1 clockwise, 0 otherwise
  const circ = (s, p) => { const [b, r, t, l] = plaq[p], f = [flux(s, b), flux(s, r), -flux(s, t), -flux(s, l)]; return f.every(v => v === 1) ? 1 : f.every(v => v === -1) ? -1 : 0; };
  const mask = plaq.map(q => q.reduce((m, l) => m + 2 ** l, 0));
  // winding: total flux through a horizontal and a vertical cut (conserved by plaquette flips)
  const winding = s => { let wx = 0, wy = 0; for (let y = 0; y < L; y++) wx += flux(s, ex(0, y)); for (let x = 0; x < L; x++) wy += flux(s, ey(x, 0)); return [wx / 2, wy / 2]; };
  return { L, nl, ex, ey, plaq, flux, gaussOK, circ, mask, winding };
}
// enumerate Gauss-law states by depth-first search site by site (fast), and by brute force (check)
function enumerate(G) {
  const { L, nl } = G, out = []; // assign link bits in order; prune at each site once all its 4 links are set
  const order = []; for (let y = 0; y < L; y++) for (let x = 0; x < L; x++) order.push(G.ex(x, y), G.ey(x, y));
  const siteDone = new Map(); // link index position -> sites that become fully determined after it
  const pos = new Map(order.map((l, i) => [l, i]));
  for (let y = 0; y < L; y++) for (let x = 0; x < L; x++) { const last = Math.max(...[G.ex(x, y), G.ey(x, y), G.ex(x - 1, y), G.ey(x, y - 1)].map(l => pos.get(l))); if (!siteDone.has(last)) siteDone.set(last, []); siteDone.get(last).push([x, y]); }
  const rec = (i, s) => { if (i === nl) { out.push(s); return; } for (const b of [0, 1]) { const t = s + b * 2 ** order[i]; let good = true;
      for (const [x, y] of siteDone.get(i) || []) if (G.flux(t, G.ex(x, y)) + G.flux(t, G.ey(x, y)) - G.flux(t, G.ex(x - 1, y)) - G.flux(t, G.ey(x, y - 1)) !== 0) { good = false; break; }
      if (good) rec(i + 1, t); } };
  rec(0, 0); return out;
}
// Hamiltonian on a list of states (one winding sector): sparse rows. (s ^ mask) >>> 0 because XOR is signed 32-bit in JavaScript.
function build(G, states, J, lam) {
  const index = new Map(states.map((s, i) => [s, i])), rows = states.map(s => { const r = new Map(); let diag = 0;
    for (let p = 0; p < G.plaq.length; p++) { if (!G.circ(s, p)) continue; diag += lam; const t = (s ^ G.mask[p]) >>> 0, j = index.get(t); if (j === undefined) throw new Error("flip left the sector"); r.set(j, (r.get(j) || 0) - J); }
    r.set(index.get(s), (r.get(index.get(s)) || 0) + diag); return [...r.entries()]; });
  return v => { const o = new Float64Array(v.length); rows.forEach((r, i) => { let s = 0; for (const [j, h] of r) s += h * v[j]; o[i] = s; }); return o; };
}
// all eigenvalues of a dense symmetric matrix: Householder tridiagonalisation, then implicit QL (Numerical Recipes tred2/tqli,
// eigenvalues only). Unlike single-vector Lanczos it keeps degenerate eigenvalues.
function eigDense(Mat) {
  const n = Mat.length, a = Mat.map(r => Float64Array.from(r)), d = new Float64Array(n), e = new Float64Array(n);
  for (let i = n - 1; i > 0; i--) { const l = i - 1; let h = 0, scale = 0;
    if (l > 0) { for (let k = 0; k <= l; k++) scale += Math.abs(a[i][k]);
      if (scale === 0) e[i] = a[i][l]; else { for (let k = 0; k <= l; k++) { a[i][k] /= scale; h += a[i][k] * a[i][k]; }
        let f = a[i][l], g = f >= 0 ? -Math.sqrt(h) : Math.sqrt(h); e[i] = scale * g; h -= f * g; a[i][l] = f - g; f = 0;
        for (let j = 0; j <= l; j++) { a[j][i] = a[i][j] / h; let g2 = 0; for (let k = 0; k <= j; k++) g2 += a[j][k] * a[i][k]; for (let k = j + 1; k <= l; k++) g2 += a[k][j] * a[i][k]; e[j] = g2 / h; f += e[j] * a[i][j]; }
        const hh = f / (h + h); for (let j = 0; j <= l; j++) { const f2 = a[i][j], g3 = e[j] - hh * f2; e[j] = g3; for (let k = 0; k <= j; k++) a[j][k] -= f2 * e[k] + g3 * a[i][k]; } } }
    else e[i] = a[i][l]; d[i] = h; }
  for (let i = 0; i < n; i++) d[i] = a[i][i];
  for (let i = 1; i < n; i++) e[i - 1] = e[i]; e[n - 1] = 0;
  for (let l = 0; l < n; l++) { let iter = 0, m;
    do { for (m = l; m < n - 1; m++) { const dd = Math.abs(d[m]) + Math.abs(d[m + 1]); if (Math.abs(e[m]) <= 1e-15 * dd) break; }
      if (m !== l) { if (iter++ > 60) throw new Error("tqli: no convergence"); let g = (d[l + 1] - d[l]) / (2 * e[l]), r = Math.hypot(g, 1); g = d[m] - d[l] + e[l] / (g + (g >= 0 ? Math.abs(r) : -Math.abs(r)));
        let s = 1, c = 1, p = 0, i;
        for (i = m - 1; i >= l; i--) { let f = s * e[i]; const b = c * e[i]; r = Math.hypot(f, g); e[i + 1] = r; if (r === 0) { d[i + 1] -= p; e[m] = 0; break; } s = f / r; c = g / r; g = d[i + 1] - p; r = (d[i] - g) * s + 2 * c * b; p = s * r; d[i + 1] = g + p; g = c * r - b; }
        if (r === 0 && i >= l) continue; d[l] -= p; e[l] = g; e[m] = 0; } } while (m !== l); }
  return Array.from(d).sort((x, y) => x - y);
}
const dense = (G, st, J, lam) => { const H = build(G, st, J, lam), n = st.length; return st.map((_, i) => H(Float64Array.from({ length: n }, (_, j) => i === j ? 1 : 0))); };
// lowest k eigenvalues by Lanczos with full reorthogonalisation; tridiagonal eigenvalues by Jacobi (misses degeneracies: used only as a cross-check)
function lowest(H, n, k = 3, iters = 200) {
  iters = Math.min(iters, n); let r = 7; const rnd = () => (r = (r * 16807) % 2147483647) / 2147483647 - 0.5;
  let v = Float64Array.from({ length: n }, rnd), nv = Math.hypot(...v); v = v.map(x => x / nv); const Q = [v], a = [], b = [];
  for (let j = 0; j < iters; j++) { let w = H(Q[j]); const al = w.reduce((s, x, i) => s + x * Q[j][i], 0); a.push(al);
    for (const q of Q) { const d = w.reduce((s, x, i) => s + x * q[i], 0); w = w.map((x, i) => x - d * q[i]); }
    const be = Math.hypot(...w); if (be < 1e-10 || j === iters - 1) break; b.push(be); Q.push(w.map(x => x / be)); }
  const m = a.length, T = Array.from({ length: m }, (_, i) => Array.from({ length: m }, (_, j) => i === j ? a[i] : Math.abs(i - j) === 1 ? b[Math.min(i, j)] : 0));
  for (let sw = 0; sw < 100; sw++) { let off = 0; for (let i = 0; i < m; i++) for (let j = i + 1; j < m; j++) off += T[i][j] ** 2; if (off < 1e-22) break;
    for (let p = 0; p < m; p++) for (let q = p + 1; q < m; q++) { if (Math.abs(T[p][q]) < 1e-15) continue; const th = 0.5 * Math.atan2(2 * T[p][q], T[q][q] - T[p][p]), c = Math.cos(th), s = Math.sin(th);
      for (let k2 = 0; k2 < m; k2++) { const x = T[k2][p], y = T[k2][q]; T[k2][p] = c * x - s * y; T[k2][q] = s * x + c * y; } for (let k2 = 0; k2 < m; k2++) { const x = T[p][k2], y = T[q][k2]; T[p][k2] = c * x - s * y; T[q][k2] = s * x + c * y; } } }
  return T.map((row, i) => row[i]).sort((x, y) => x - y).slice(0, k);
}
// ---------- checks ----------
for (const L of [2, 3]) { const G = lattice(L); let brute = 0; for (let s = 0; s < 2 ** G.nl; s++) if (G.gaussOK(s)) brute++;
  ok(`L ${L}: state enumeration = brute force over all 2^${G.nl}`, enumerate(G).length === brute, `${brute} Gauss-law states`); }
{ const G = lattice(4), st = enumerate(G); let keep = true, wind = true;
  for (const s of st) for (let p = 0; p < G.plaq.length; p++) if (G.circ(s, p)) { const t = (s ^ G.mask[p]) >>> 0; if (!G.gaussOK(t)) keep = false; if (G.winding(t).join() !== G.winding(s).join()) wind = false; }
  ok("plaquette flips keep the Gauss law and the winding numbers", keep && wind, `checked every flip of every one of ${st.length} states (L 4)`); }
{ // Lanczos against dense diagonalisation on a small sector
  const G = lattice(3), all3 = enumerate(G), cnt = new Map(); for (const s of all3) { const w = G.winding(s).join(); cnt.set(w, (cnt.get(w) || 0) + 1); }
  const big = [...cnt.entries()].sort((a, b) => b[1] - a[1])[0][0], st = all3.filter(s => G.winding(s).join() === big), H = build(G, st, 1, 0.3), n = st.length;
  const M = st.map((_, i) => H(Float64Array.from({ length: n }, (_, j) => i === j ? 1 : 0))); const ev = lowest(H, n, 3, n);
  // dense Jacobi on M
  const A = M.map(r => Float64Array.from(r)); for (let sw = 0; sw < 60; sw++) { let off = 0; for (let i = 0; i < n; i++) for (let j = i + 1; j < n; j++) off += A[i][j] ** 2; if (off < 1e-22) break;
    for (let p = 0; p < n; p++) for (let q = p + 1; q < n; q++) { if (Math.abs(A[p][q]) < 1e-15) continue; const th = 0.5 * Math.atan2(2 * A[p][q], A[q][q] - A[p][p]), c = Math.cos(th), s = Math.sin(th);
      for (let k = 0; k < n; k++) { const x = A[k][p], y = A[k][q]; A[k][p] = c * x - s * y; A[k][q] = s * x + c * y; } for (let k = 0; k < n; k++) { const x = A[p][k], y = A[q][k]; A[p][k] = c * x - s * y; A[q][k] = s * x + c * y; } } }
  const jac = A.map((r, i) => r[i]).sort((x, y) => x - y), hq = eigDense(M), d1 = Math.max(...jac.map((x, i) => Math.abs(x - hq[i])));
  ok("Householder-QL = Jacobi, all eigenvalues with multiplicity", d1 < 1e-9, `L 3, sector (${big}), ${n} states: largest difference ${d1.toExponential(1)}; lowest three ${hq.slice(0, 3).map(x => x.toFixed(6)).join(", ")}`);
  const distinct = [...new Set(hq.map(x => x.toFixed(8)))].map(Number).slice(0, 3), d2 = Math.max(...distinct.map((x, i) => Math.abs(x - ev[i])));
  ok("Lanczos finds the distinct eigenvalues (but not their multiplicity)", d2 < 1e-8, `lowest distinct ${distinct.map(x => x.toFixed(6)).join(", ")}; difference ${d2.toExponential(1)}`); }
// ---------- results on 4 x 4 ----------
const G = lattice(4), all = enumerate(G), sectors = new Map(); for (const s of all) { const w = G.winding(s).join(); if (!sectors.has(w)) sectors.set(w, []); sectors.get(w).push(s); }
console.log(`\n4 x 4 torus: ${all.length} Gauss-law states (32 qubits = ${2 ** 32} states without the Gauss law). Winding sectors:`);
console.log("  " + [...sectors.entries()].sort((a, b) => b[1].length - a[1].length).map(([w, s]) => `(${w}): ${s.length}`).join("  "));
{ // RK point: ground-state energy exactly 0 in every sector with at least one flippable state
  let worst = 0; for (const [w, st] of sectors) { if (st.length < 2) continue; const e = lowest(build(G, st, 1, 1), st.length, 1)[0]; worst = Math.max(worst, Math.abs(e)); }
  ok("Rokhsar-Kivelson point lambda = J: ground-state energy exactly 0", worst < 1e-9, `largest |E0| over all sectors: ${worst.toExponential(1)}`);
}
console.log("\nRESULT: sector (0,0), 990 states, exact dense diagonalisation, energies in units of J.");
console.log("  <F> = flippable plaquettes per plaquette in the ground state = dE0/dlambda / 16 (Hellmann-Feynman, central difference).");
console.log("  lambda/J    E0          multiplicity   E1 (next level)   gap      <F>");
const st0 = sectors.get("0,0"), res = [];
for (const lam of [-2, -1, -0.5, 0, 0.5, 0.8, 0.9, 0.95, 1.0]) {
  const ev = eigDense(dense(G, st0, 1, lam)), E0 = ev[0], mult = ev.filter(x => Math.abs(x - E0) < 1e-9).length, E1 = ev.find(x => x > E0 + 1e-9), h = 1e-4;
  const Fp = (eigDense(dense(G, st0, 1, lam + h))[0] - eigDense(dense(G, st0, 1, lam - h))[0]) / (2 * h) / 16;
  res.push({ lam, E0, mult, gap: E1 - E0, F: Fp });
  console.log(`  ${lam.toFixed(2).padStart(5)}    ${E0.toFixed(6).padStart(10)}  ${String(mult).padStart(6)}        ${E1.toFixed(6).padStart(10)}     ${(E1 - E0).toFixed(4)}   ${Fp.toFixed(4)}`);
}
{ const r1 = res.find(r => r.lam === 1); ok("dense diagonalisation agrees on the RK point", Math.abs(r1.E0) < 1e-9, `E0 at lambda = J: ${r1.E0.toExponential(1)}, multiplicity ${r1.mult}`); }
console.log(fail ? `\n${fail} check(s) failed` : "\nall checks passed"); process.exitCode = fail ? 1 : 0;
