// ORIGIN lab: superconductor, layer 2 ("is the pair real, and can it move?"). Quantum, exact.
// Holstein-Hubbard model on a small periodic 2D lattice (square, triangular or honeycomb):
//   H = -t sum_<ij>,s e^{i phi_ij} c+_is c_js + w0 sum_i b+_i b_i + g sum_i n_i (b+_i + b_i) + U sum_i n_iup n_idown
// One electron, and two electrons in a spin singlet. Phonons truncated to at most Nmax quanta in total.
// Ground states by Lanczos (complex, so a twist can be threaded through the box).
//
// Binding energy  Eb = E2 - 2 E1 (below 0 = bound pair).
// Pair mass       twist theta along x: every hop picks up phase theta * dx / Wx (Wx = box width).
//                 A pair carries momentum K = 2 theta / Wx and E2(theta) - E2(0) = K^2 / (2 M).
//                 Reported as M_pair / (2 m_band), m_band = the same measure for one free electron.
// Coupling        lambda = g^2 / (w0 * W/2), W/2 = half-bandwidth: square 4t, triangular 4.5t, honeycomb 3t.
// Units: t = 1.
//
// node layer2.js lattice=square Lx=3 Ly=3 g=1.414 w0=1 U=4 Nmax=8 [mass=1]
(function (root) {
  const HALF_BW = { square: 4, triangular: 4.5, honeycomb: 3 };
  // sites with real-space positions; neighbour list with real-space displacement (for the twist)
  function lattice(type, Lx, Ly) {
    const sites = [], nb = [];
    let a1, a2, basis;
    if (type === "square") { a1 = [1, 0]; a2 = [0, 1]; basis = [[0, 0]]; }
    else if (type === "triangular") { a1 = [1, 0]; a2 = [0.5, Math.sqrt(3) / 2]; basis = [[0, 0]]; }
    else { a1 = [Math.sqrt(3), 0]; a2 = [Math.sqrt(3) / 2, 1.5]; basis = [[0, 0], [0, 1]]; }
    const nb_ = basis.length, id = (x, y, b) => ((((y % Ly) + Ly) % Ly) * Lx + (((x % Lx) + Lx) % Lx)) * nb_ + b;
    for (let y = 0; y < Ly; y++) for (let x = 0; x < Lx; x++) for (let b = 0; b < nb_; b++)
      sites.push([x * a1[0] + y * a2[0] + basis[b][0], x * a1[1] + y * a2[1] + basis[b][1]]);
    const N = sites.length, A1 = [Lx * a1[0], Lx * a1[1]], A2 = [Ly * a2[0], Ly * a2[1]];
    // minimal-image displacement j - i
    const disp = (i, j) => {
      let best = null;
      for (let m = -1; m <= 1; m++) for (let n = -1; n <= 1; n++) {
        const dx = sites[j][0] - sites[i][0] + m * A1[0] + n * A2[0], dy = sites[j][1] - sites[i][1] + m * A1[1] + n * A2[1];
        if (!best || dx * dx + dy * dy < best[0] * best[0] + best[1] * best[1] - 1e-9) best = [dx, dy];
      }
      return best;
    };
    // nearest neighbours: every site at distance 1 (counting each periodic image separately)
    for (let i = 0; i < N; i++) {
      const out = [];
      for (let j = 0; j < N; j++) for (let m = -1; m <= 1; m++) for (let n = -1; n <= 1; n++) {
        const dx = sites[j][0] - sites[i][0] + m * A1[0] + n * A2[0], dy = sites[j][1] - sites[i][1] + m * A1[1] + n * A2[1];
        if (Math.abs(Math.hypot(dx, dy) - 1) < 1e-6) out.push([j, dx]);
      }
      nb.push(out);
    }
    return { N, nb, disp, Wx: A1[0], type };
  }
  function phonons(N, Nmax) {
    const states = [], idx = new Map(), v = new Array(N).fill(0);
    (function rec(s, left) {
      if (s === N) { idx.set(v.join(","), states.length); states.push(Uint8Array.from(v)); return; }
      for (let k = 0; k <= left; k++) { v[s] = k; rec(s + 1, left - k); } v[s] = 0;
    })(0, Nmax);
    const P = states.length, up = new Int32Array(P * N).fill(-1), tot = new Int32Array(P);
    states.forEach((st, p) => {
      let t = 0; for (const x of st) t += x; tot[p] = t;
      if (t < Nmax) for (let s = 0; s < N; s++) { const w = Array.from(st); w[s]++; up[p * N + s] = idx.get(w.join(",")); }
    });
    return { P, states, up, tot };
  }
  // electron configurations and complex hopping amplitudes for twist theta
  function electrons(L, two, theta) {
    const conf = [], id = new Map(), key = c => c.length === 1 ? c[0] + "" : Math.min(...c) + "," + Math.max(...c);
    if (!two) for (let i = 0; i < L.N; i++) { id.set(i + "", conf.length); conf.push([i]); }
    else for (let i = 0; i < L.N; i++) for (let j = i; j < L.N; j++) { id.set(i + "," + j, conf.length); conf.push([i, j]); }
    const ph = dx => [Math.cos(theta * dx / L.Wx), Math.sin(theta * dx / L.Wx)];
    const hop = conf.map(c => {
      const out = new Map();
      // amplitude for moving an electron from a to b (dx = displacement): -t e^{i phi}, scaled by f
      const add = (c2, dx, f) => { const k = id.get(key(c2)), [cr, ci] = ph(dx), o = out.get(k) || [0, 0]; o[0] -= f * cr; o[1] -= f * ci; out.set(k, o); };
      if (c.length === 1) for (const [n, dx] of L.nb[c[0]]) add([n], dx, 1);
      else {
        const [i, j] = c;
        if (i !== j) {
          for (const [n, dx] of L.nb[i]) add([n, j], dx, n === j ? Math.SQRT2 : 1);
          for (const [n, dx] of L.nb[j]) add([i, n], dx, n === i ? Math.SQRT2 : 1);
        } else for (const [n, dx] of L.nb[i]) add([i, n], dx, Math.SQRT2);
      }
      return [...out.entries()].map(([k, [r, im]]) => [k, r, im]);
    });
    const occ = conf.map(c => { const m = new Map(); for (const s of c) m.set(s, (m.get(s) || 0) + 1); return [...m.entries()]; });
    return { conf, hop, occ, n: conf.length };
  }
  // y = H x (complex: re/im arrays)
  function applyH(xr, xi, yr, yi, E, Ph, prm, N) {
    const P = Ph.P; yr.fill(0); yi.fill(0);
    for (let e = 0; e < E.n; e++) {
      const c = E.conf[e], onsite = (c.length === 2 && c[0] === c[1]) ? prm.U : 0, hops = E.hop[e], occ = E.occ[e];
      for (let p = 0; p < P; p++) {
        const b = e * P + p, ar = xr[b], ai = xi[b]; if (ar === 0 && ai === 0) continue;
        const d = onsite + prm.w0 * Ph.tot[p]; yr[b] += d * ar; yi[b] += d * ai;
        for (const [e2, hr, hi] of hops) { const t = e2 * P + p; yr[t] += hr * ar - hi * ai; yi[t] += hr * ai + hi * ar; }
        for (const [s, ns] of occ) {
          const q = Ph.up[p * N + s]; if (q < 0) continue;
          const amp = prm.g * ns * Math.sqrt(Ph.states[p][s] + 1), t = e * P + q;
          yr[t] += amp * ar; yi[t] += amp * ai;          // b+ term
          yr[b] += amp * xr[t]; yi[b] += amp * xi[t];    // b term (its conjugate)
        }
      }
    }
  }
  function tridiagMin(a, b) {
    const n = a.length; let lo = Infinity, hi = -Infinity;
    for (let i = 0; i < n; i++) { const r = (i ? Math.abs(b[i - 1]) : 0) + (i < n - 1 ? Math.abs(b[i]) : 0); lo = Math.min(lo, a[i] - r); hi = Math.max(hi, a[i] + r); }
    const count = x => { let c = 0, d = 1; for (let i = 0; i < n; i++) { d = a[i] - x - (i ? b[i - 1] * b[i - 1] / d : 0); if (d === 0) d = 1e-300; if (d < 0) c++; } return c; };
    for (let it = 0; it < 200; it++) { const m = (lo + hi) / 2; if (count(m) >= 1) hi = m; else lo = m; }
    return (lo + hi) / 2;
  }
  function tridiagVec(a, b, ev) {
    const n = a.length; let v = new Float64Array(n).fill(1);
    for (let it = 0; it < 6; it++) {
      const c = new Float64Array(n), d = Float64Array.from(v), m = a.map(x => x - ev - 1e-10);
      for (let i = 1; i < n; i++) { const w = b[i - 1] / m[i - 1]; m[i] -= w * b[i - 1]; d[i] -= w * d[i - 1]; }
      c[n - 1] = d[n - 1] / m[n - 1]; for (let i = n - 2; i >= 0; i--) c[i] = (d[i] - b[i] * c[i + 1]) / m[i];
      let nr = 0; for (const x of c) nr += x * x; nr = Math.sqrt(nr); v = c.map(x => x / nr);
    }
    return v;
  }
  // Lanczos; wantVec -> second pass rebuilds the ground state (real part used for observables at theta 0)
  function ground(E, Ph, prm, N, wantVec, iters = 160) {
    const D = E.n * Ph.P; let r = 12345; const rnd = () => { r = (r * 1103515245 + 12345) >>> 0; return r / 4294967296 - 0.5; };
    const v0r = new Float64Array(D), v0i = new Float64Array(D); let nr = 0;
    for (let i = 0; i < D; i++) { v0r[i] = rnd(); nr += v0r[i] * v0r[i]; } nr = Math.sqrt(nr); for (let i = 0; i < D; i++) v0r[i] /= nr;
    const run = coef => {
      let vr = Float64Array.from(v0r), vi = Float64Array.from(v0i), pr = new Float64Array(D), pi = new Float64Array(D);
      const wr = new Float64Array(D), wi = new Float64Array(D), a = [], b = [];
      const gr = coef ? new Float64Array(D) : null, gi = coef ? new Float64Array(D) : null;
      const K = coef ? coef.length : iters;
      for (let k = 0; k < K; k++) {
        if (gr) for (let i = 0; i < D; i++) { gr[i] += coef[k] * vr[i]; gi[i] += coef[k] * vi[i]; }
        applyH(vr, vi, wr, wi, E, Ph, prm, N);
        let al = 0; for (let i = 0; i < D; i++) al += wr[i] * vr[i] + wi[i] * vi[i]; a.push(al);
        const bp = k ? b[k - 1] : 0;
        for (let i = 0; i < D; i++) { wr[i] -= al * vr[i] + bp * pr[i]; wi[i] -= al * vi[i] + bp * pi[i]; }
        let be = 0; for (let i = 0; i < D; i++) be += wr[i] * wr[i] + wi[i] * wi[i]; be = Math.sqrt(be);
        if (be < 1e-12) break; b.push(be);
        pr = vr; pi = vi; vr = new Float64Array(D); vi = new Float64Array(D);
        for (let i = 0; i < D; i++) { vr[i] = wr[i] / be; vi[i] = wi[i] / be; }
      }
      return { a, b, gr, gi };
    };
    const { a, b } = run(null);
    const E0 = tridiagMin(a, b.slice(0, a.length - 1));
    if (!wantVec) return { E0 };
    const { gr, gi } = run(tridiagVec(a, b.slice(0, a.length - 1), E0));
    let n2 = 0; for (let i = 0; i < D; i++) n2 += gr[i] * gr[i] + gi[i] * gi[i]; n2 = Math.sqrt(n2);
    return { E0, vr: gr.map(x => x / n2), vi: gi.map(x => x / n2) };
  }
  function solve(prm) {
    const L = lattice(prm.lattice, prm.Lx, prm.Ly), Ph = phonons(L.N, prm.Nmax);
    const E1 = electrons(L, false, 0), E2 = electrons(L, true, 0);
    const g1 = ground(E1, Ph, prm, L.N, false), g2 = ground(E2, Ph, prm, L.N, true);
    const P = Ph.P; let same = 0, rsum = 0, nph = 0;
    for (let e = 0; e < E2.n; e++) {
      const [i, j] = E2.conf[e], d = L.disp(i, j);
      let w = 0; for (let p = 0; p < P; p++) { const k = e * P + p, a = g2.vr[k] ** 2 + g2.vi[k] ** 2; w += a; nph += a * Ph.tot[p]; }
      rsum += w * Math.hypot(d[0], d[1]); if (i === j) same += w;
    }
    const out = { E1: g1.E0, E2: g2.E0, Eb: g2.E0 - 2 * g1.E0, onsite: same, meanR: rsum, phonons: nph,
      lambda: prm.g * prm.g / (prm.w0 * HALF_BW[prm.lattice]), states: E2.n * P, N: L.N };
    if (prm.mass) {
      // twist theta: pair momentum K = 2 theta / Wx; band mass of one free electron from the same twist
      const th = prm.theta || 0.4, K = 2 * th / L.Wx, k1 = th / L.Wx;
      const E2t = ground(electrons(L, true, th), Ph, prm, L.N, false).E0;
      const Pf = phonons(L.N, 0), f0 = ground(electrons(L, false, 0), Pf, { ...prm, g: 0 }, L.N, false).E0;
      const ft = ground(electrons(L, false, th), Pf, { ...prm, g: 0 }, L.N, false).E0;
      const mBand = k1 * k1 / (2 * (ft - f0)), Mpair = K * K / (2 * (E2t - g2.E0));
      Object.assign(out, { dE2: E2t - g2.E0, massRatio: Mpair / (2 * mBand), mBand });
    }
    return out;
  }
  const api = { solve, HALF_BW };
  if (typeof module !== "undefined") module.exports = api; else root.SCLayer2 = api;
  if (typeof require !== "undefined" && typeof module !== "undefined" && require.main === module) {
    const a = Object.fromEntries(process.argv.slice(2).map(s => s.split("=")));
    const prm = { lattice: a.lattice || "square", g: +(a.g ?? 1), w0: +(a.w0 ?? 1), U: +(a.U ?? 0), Lx: +(a.Lx ?? 3), Ly: +(a.Ly ?? 3), Nmax: +(a.Nmax ?? 8), mass: a.mass === "1", theta: +(a.theta ?? 0.4) };
    const r = solve(prm);
    if (a.header === "1") console.log("lattice\tLx\tLy\tsites\tNmax\tg\tw0\tU\tlambda\tE1\tE2\tEb\tonsite_share\tmean_pair_distance\tphonons\tpair_mass_ratio\tstates");
    console.log([prm.lattice, prm.Lx, prm.Ly, r.N, prm.Nmax, prm.g, prm.w0, prm.U, r.lambda.toFixed(3), r.E1.toFixed(5), r.E2.toFixed(5), r.Eb.toFixed(5), r.onsite.toFixed(4), r.meanR.toFixed(4), r.phonons.toFixed(3), r.massRatio !== undefined ? r.massRatio.toFixed(3) : "", r.states].join("\t"));
  }
})(this);
