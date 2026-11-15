// ORIGIN lab: superconductor, layer 2 ("is the pair real?"). Quantum, exact.
// Holstein-Hubbard model on an Lx x Ly periodic 2D lattice:
//   H = -t sum_<ij>,s c+_is c_js  +  w0 sum_i b+_i b_i  +  g sum_i n_i (b+_i + b_i)  +  U sum_i n_i,up n_i,down
// One electron, and two electrons in a spin singlet (the Cooper-pair spin state). Phonons are truncated
// to at most Nmax quanta in total; check convergence by raising Nmax. Ground state by Lanczos.
// Binding energy Eb = E2 - 2 E1: below 0 means the two electrons are bound (a pair).
// Coupling convention: lambda = g^2 / (w0 * 4t) (2D, half-bandwidth 4t). Units: t = 1.
//
// node layer2.js g=1 w0=1 U=0 Lx=3 Ly=3 Nmax=8
(function (root) {
  function lattice(Lx, Ly) {
    const N = Lx * Ly, nb = [];
    for (let y = 0; y < Ly; y++) for (let x = 0; x < Lx; x++) {
      const i = y * Lx + x, s = new Set([y * Lx + (x + 1) % Lx, y * Lx + (x + Lx - 1) % Lx, ((y + 1) % Ly) * Lx + x, ((y + Ly - 1) % Ly) * Lx + x]);
      s.delete(i); nb.push([...s]);
    }
    return { N, nb, Lx, Ly };
  }
  // phonon basis: occupation vectors on N sites, total <= Nmax. up[p*N+s] = index after b+_s (or -1).
  function phonons(N, Nmax) {
    const states = [], idx = new Map(), v = new Array(N).fill(0);
    (function rec(s, left) {
      if (s === N) { idx.set(v.join(","), states.length); states.push(v.slice()); return; }
      for (let k = 0; k <= left; k++) { v[s] = k; rec(s + 1, left - k); } v[s] = 0;
    })(0, Nmax);
    const P = states.length, up = new Int32Array(P * N).fill(-1), tot = new Int32Array(P);
    states.forEach((st, p) => {
      tot[p] = st.reduce((a, b) => a + b, 0);
      if (tot[p] < Nmax) for (let s = 0; s < N; s++) { st[s]++; up[p * N + s] = idx.get(st.join(",")); st[s]--; }
    });
    return { P, states, up, tot };
  }
  // electron configurations: 1 electron = site i; singlet pair = {i <= j}
  function electrons(L, two) {
    const conf = [], id = new Map();
    if (!two) for (let i = 0; i < L.N; i++) { id.set(i + "", conf.length); conf.push([i]); }
    else for (let i = 0; i < L.N; i++) for (let j = i; j < L.N; j++) { id.set(i + "," + j, conf.length); conf.push([i, j]); }
    const key = c => c.length === 1 ? c[0] + "" : Math.min(...c) + "," + Math.max(...c);
    // hopping list: for each conf, [(conf', amplitude)] for -t sum hops (t = 1)
    const hop = conf.map(c => {
      const out = new Map();
      const add = (c2, a) => { const k = id.get(key(c2)); out.set(k, (out.get(k) || 0) + a); };
      if (c.length === 1) for (const n of L.nb[c[0]]) add([n], -1);
      else {
        const [i, j] = c;
        if (i !== j) {
          for (const n of L.nb[i]) add([n, j], n === j ? -Math.SQRT2 : -1);
          for (const n of L.nb[j]) add([i, n], n === i ? -Math.SQRT2 : -1);
        } else for (const n of L.nb[i]) add([i, n], -Math.SQRT2);
      }
      return [...out.entries()];
    });
    // electrons per site for the coupling
    const occ = conf.map(c => { const m = new Map(); for (const s of c) m.set(s, (m.get(s) || 0) + 1); return [...m.entries()]; });
    return { conf, hop, occ, n: conf.length };
  }
  function applyH(x, y, E, Ph, prm, N) {
    const P = Ph.P; y.fill(0);
    for (let e = 0; e < E.n; e++) {
      const c = E.conf[e], onsite = (c.length === 2 && c[0] === c[1]) ? prm.U : 0;
      for (let p = 0; p < P; p++) {
        const a = x[e * P + p]; if (a === 0) continue;
        const base = e * P + p;
        y[base] += (onsite + prm.w0 * Ph.tot[p]) * a;
        for (const [e2, h] of E.hop[e]) y[e2 * P + p] += h * a;
        for (const [s, ns] of E.occ[e]) {
          const q = Ph.up[p * N + s];
          if (q >= 0) { const amp = prm.g * ns * Math.sqrt(Ph.states[p][s] + 1) * a; y[e * P + q] += amp; }
        }
      }
    }
    // b_s terms: hermitian conjugate of the b+ terms above
    for (let e = 0; e < E.n; e++) for (let p = 0; p < P; p++) for (const [s, ns] of E.occ[e]) {
      const q = Ph.up[p * N + s]; if (q < 0) continue;
      y[e * P + p] += prm.g * ns * Math.sqrt(Ph.states[p][s] + 1) * x[e * P + q];
    }
  }
  function tridiagMin(a, b) { // smallest eigenvalue of symmetric tridiagonal (bisection, Sturm count)
    const n = a.length; let lo = Infinity, hi = -Infinity;
    for (let i = 0; i < n; i++) { const r = (i ? Math.abs(b[i - 1]) : 0) + (i < n - 1 ? Math.abs(b[i]) : 0); lo = Math.min(lo, a[i] - r); hi = Math.max(hi, a[i] + r); }
    const count = (x) => { let c = 0, d = 1; for (let i = 0; i < n; i++) { d = a[i] - x - (i ? b[i - 1] * b[i - 1] / d : 0); if (d === 0) d = 1e-300; if (d < 0) c++; } return c; };
    for (let it = 0; it < 200; it++) { const m = (lo + hi) / 2; if (count(m) >= 1) hi = m; else lo = m; }
    return (lo + hi) / 2;
  }
  function tridiagVec(a, b, ev) { // eigenvector of tridiagonal for eigenvalue ev (inverse iteration)
    const n = a.length; let v = new Float64Array(n).fill(1);
    for (let it = 0; it < 6; it++) {
      const c = new Float64Array(n), d = Float64Array.from(v), m = a.map(x => x - ev - 1e-10);
      for (let i = 1; i < n; i++) { const w = b[i - 1] / m[i - 1]; m[i] -= w * b[i - 1]; d[i] -= w * d[i - 1]; }
      c[n - 1] = d[n - 1] / m[n - 1]; for (let i = n - 2; i >= 0; i--) c[i] = (d[i] - b[i] * c[i + 1]) / m[i];
      const nr = Math.hypot(...c); v = c.map(x => x / nr);
    }
    return v;
  }
  function ground(E, Ph, prm, N, iters = 160) {
    const D = E.n * Ph.P; let r = 12345;
    const rnd = () => { r = (r * 1103515245 + 12345) >>> 0; return r / 4294967296 - 0.5; };
    const v0 = new Float64Array(D); for (let i = 0; i < D; i++) v0[i] = rnd(); let nr = Math.hypot(...v0.slice(0, 0)) || 0;
    nr = Math.sqrt(v0.reduce((s, x) => s + x * x, 0)); for (let i = 0; i < D; i++) v0[i] /= nr;
    const run = (keepCoef) => { // two-pass Lanczos: pass 1 gets a, b; pass 2 rebuilds the ground vector
      let v = Float64Array.from(v0), vp = new Float64Array(D), w = new Float64Array(D); const a = [], b = [];
      const gs = keepCoef ? new Float64Array(D) : null;
      for (let k = 0; k < (keepCoef ? keepCoef.length : iters); k++) {
        if (gs) for (let i = 0; i < D; i++) gs[i] += keepCoef[k] * v[i];
        applyH(v, w, E, Ph, prm, N);
        let al = 0; for (let i = 0; i < D; i++) al += w[i] * v[i]; a.push(al);
        for (let i = 0; i < D; i++) w[i] -= al * v[i] + (k ? b[k - 1] * vp[i] : 0);
        let be = 0; for (let i = 0; i < D; i++) be += w[i] * w[i]; be = Math.sqrt(be);
        if (be < 1e-12) break; b.push(be);
        vp = v; v = w.map(x => x / be); w = new Float64Array(D);
      }
      return { a, b, gs };
    };
    const { a, b } = run(null);
    const E0 = tridiagMin(a, b.slice(0, a.length - 1));
    const coef = tridiagVec(a, b.slice(0, a.length - 1), E0);
    const { gs } = run(coef);
    let n2 = 0; for (const x of gs) n2 += x * x; for (let i = 0; i < D; i++) gs[i] /= Math.sqrt(n2);
    return { E0, vec: gs };
  }
  function solve(prm) {
    const L = lattice(prm.Lx, prm.Ly), Ph = phonons(L.N, prm.Nmax);
    const E1 = electrons(L, false), E2 = electrons(L, true);
    const g1 = ground(E1, Ph, prm, L.N), g2 = ground(E2, Ph, prm, L.N);
    // pair observables from the 2-electron ground state
    const P = Ph.P; let same = 0, rsum = 0, nph = 0;
    for (let e = 0; e < E2.n; e++) {
      const [i, j] = E2.conf[e];
      const xi = i % L.Lx, yi = (i / L.Lx) | 0, xj = j % L.Lx, yj = (j / L.Lx) | 0;
      const dx = Math.min(Math.abs(xi - xj), L.Lx - Math.abs(xi - xj)), dy = Math.min(Math.abs(yi - yj), L.Ly - Math.abs(yi - yj));
      let w = 0; for (let p = 0; p < P; p++) { const a = g2.vec[e * P + p]; w += a * a; nph += a * a * Ph.tot[p]; }
      rsum += w * Math.hypot(dx, dy); if (i === j) same += w;
    }
    return { E1: g1.E0, E2: g2.E0, Eb: g2.E0 - 2 * g1.E0, onsite: same, meanR: rsum, phonons: nph, lambda: prm.g * prm.g / (prm.w0 * 4), states: E2.n * P };
  }
  const api = { solve };
  if (typeof module !== "undefined") module.exports = api; else root.SCLayer2 = api;
  if (typeof require !== "undefined" && typeof module !== "undefined" && require.main === module) {
    const a = Object.fromEntries(process.argv.slice(2).map(s => s.split("=")));
    const prm = { g: +(a.g ?? 1), w0: +(a.w0 ?? 1), U: +(a.U ?? 0), Lx: +(a.Lx ?? 3), Ly: +(a.Ly ?? 3), Nmax: +(a.Nmax ?? 8) };
    const r = solve(prm);
    if (a.header === "1") console.log("Lx\tLy\tNmax\tg\tw0\tU\tlambda\tE1\tE2\tEb\tonsite_share\tmean_pair_distance\tphonons\tstates");
    console.log([prm.Lx, prm.Ly, prm.Nmax, prm.g, prm.w0, prm.U, r.lambda.toFixed(3), r.E1.toFixed(5), r.E2.toFixed(5), r.Eb.toFixed(5), r.onsite.toFixed(4), r.meanR.toFixed(4), r.phonons.toFixed(3), r.states].join("\t"));
  }
})(this);
