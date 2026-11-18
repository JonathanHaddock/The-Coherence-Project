// ORIGIN lab: lattice QCD, pure gauge SU(3). Standard physics, separate from origin's pixel rules.
//
// The gluon field lives on the links of a 4D periodic grid (Ns^3 x Nt). Each link U_mu(x) is a 3x3
// special unitary matrix: the "transport" of colour from site x to its neighbour x + mu.
// Wilson action: S = beta * sum over plaquettes of (1 - Re Tr P / 3), where P is the product of the
// four links around one unit square. beta = 6 / g^2 (g = the bare strong coupling).
// Links are updated by Metropolis with the exact Boltzmann weight exp(-S).
//
// Measurements:
//   plaquette     <Re Tr P / 3>, the basic check against published values
//   Wilson loops  W(R,T) = <Re Tr (R x T rectangle) / 3>. Confinement = area law, W ~ exp(-sigma R T)
//   Creutz ratio  chi(R) = -ln( W(R,R) W(R-1,R-1) / W(R,R-1)^2 ), estimates the string tension sigma a^2
//   Polyakov loop <Tr (product of time links around the box) / 3>. ~0 when confined; jumps to one of
//                 three directions (Z3) when the box is hot enough to deconfine (small Nt, large beta)
//
// Units: lattice spacing a = 1. Runs in the browser (window.SU3Lab) and in node (require).
(function (root) {
  const DEFAULTS = { Ns: 6, Nt: 6, beta: 5.7, start: "cold", hits: 10, eps: 0.24, seed: 1 };

  function rng(seed) { let a = seed >>> 0 || 1; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
  function gauss(R) { let u = 0; while (!u) u = R(); return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * R()); }

  // ---- 3x3 complex matrices as Float64Array(18): [re00, im00, re01, im01, ...] row-major ----
  const M3 = () => new Float64Array(18);
  function setId(o) { o.fill(0); o[0] = o[8] = o[16] = 1; return o; }
  function mul(a, b, o) { // o = a b  (o must not alias a or b)
    for (let i = 0; i < 3; i++) for (let j = 0; j < 3; j++) {
      let re = 0, im = 0;
      for (let k = 0; k < 3; k++) {
        const ar = a[(i * 3 + k) * 2], ai = a[(i * 3 + k) * 2 + 1], br = b[(k * 3 + j) * 2], bi = b[(k * 3 + j) * 2 + 1];
        re += ar * br - ai * bi; im += ar * bi + ai * br;
      }
      o[(i * 3 + j) * 2] = re; o[(i * 3 + j) * 2 + 1] = im;
    }
    return o;
  }
  function mulDag(a, b, o) { // o = a b^dagger
    for (let i = 0; i < 3; i++) for (let j = 0; j < 3; j++) {
      let re = 0, im = 0;
      for (let k = 0; k < 3; k++) {
        const ar = a[(i * 3 + k) * 2], ai = a[(i * 3 + k) * 2 + 1], br = b[(j * 3 + k) * 2], bi = -b[(j * 3 + k) * 2 + 1];
        re += ar * br - ai * bi; im += ar * bi + ai * br;
      }
      o[(i * 3 + j) * 2] = re; o[(i * 3 + j) * 2 + 1] = im;
    }
    return o;
  }
  function dagMul(a, b, o) { // o = a^dagger b
    for (let i = 0; i < 3; i++) for (let j = 0; j < 3; j++) {
      let re = 0, im = 0;
      for (let k = 0; k < 3; k++) {
        const ar = a[(k * 3 + i) * 2], ai = -a[(k * 3 + i) * 2 + 1], br = b[(k * 3 + j) * 2], bi = b[(k * 3 + j) * 2 + 1];
        re += ar * br - ai * bi; im += ar * bi + ai * br;
      }
      o[(i * 3 + j) * 2] = re; o[(i * 3 + j) * 2 + 1] = im;
    }
    return o;
  }
  const reTr = a => a[0] + a[8] + a[16];
  const imTr = a => a[1] + a[9] + a[17];
  // Re Tr (a b) without building the product
  function reTrMul(a, b) {
    let s = 0;
    for (let i = 0; i < 3; i++) for (let k = 0; k < 3; k++) {
      const ar = a[(i * 3 + k) * 2], ai = a[(i * 3 + k) * 2 + 1], br = b[(k * 3 + i) * 2], bi = b[(k * 3 + i) * 2 + 1];
      s += ar * br - ai * bi;
    }
    return s;
  }
  // Gram-Schmidt the first two rows, third = conj(row0 x row1): back onto SU(3) exactly
  function reunitarize(u, off = 0) {
    let n = 0;
    for (let k = 0; k < 6; k++) n += u[off + k] * u[off + k];
    n = Math.sqrt(n); for (let k = 0; k < 6; k++) u[off + k] /= n;
    let dr = 0, di = 0; // <row0, row1> = sum conj(r0) r1
    for (let k = 0; k < 3; k++) {
      const ar = u[off + 2 * k], ai = u[off + 2 * k + 1], br = u[off + 6 + 2 * k], bi = u[off + 6 + 2 * k + 1];
      dr += ar * br + ai * bi; di += ar * bi - ai * br;
    }
    for (let k = 0; k < 3; k++) {
      const ar = u[off + 2 * k], ai = u[off + 2 * k + 1];
      u[off + 6 + 2 * k] -= dr * ar - di * ai; u[off + 6 + 2 * k + 1] -= dr * ai + di * ar;
    }
    n = 0; for (let k = 6; k < 12; k++) n += u[off + k] * u[off + k];
    n = Math.sqrt(n); for (let k = 6; k < 12; k++) u[off + k] /= n;
    for (let k = 0; k < 3; k++) { // row2_k = conj(row0_{k+1} row1_{k+2} - row0_{k+2} row1_{k+1})
      const p = (k + 1) % 3, q = (k + 2) % 3;
      const ar = u[off + 2 * p], ai = u[off + 2 * p + 1], br = u[off + 6 + 2 * q], bi = u[off + 6 + 2 * q + 1];
      const cr = u[off + 2 * q], ci = u[off + 2 * q + 1], dr2 = u[off + 6 + 2 * p], di2 = u[off + 6 + 2 * p + 1];
      const re = (ar * br - ai * bi) - (cr * dr2 - ci * di2), im = (ar * bi + ai * br) - (cr * di2 + ci * dr2);
      u[off + 12 + 2 * k] = re; u[off + 12 + 2 * k + 1] = -im;
    }
  }
  // random SU(3) element near the identity: exp(i eps H), H random traceless Hermitian (series to 4th order, then reunitarized)
  function nearIdentity(R, eps) {
    const H = M3();
    for (let i = 0; i < 3; i++) for (let j = i; j < 3; j++) {
      if (i === j) H[(i * 3 + i) * 2] = gauss(R);
      else { const re = gauss(R), im = gauss(R); H[(i * 3 + j) * 2] = re; H[(i * 3 + j) * 2 + 1] = im; H[(j * 3 + i) * 2] = re; H[(j * 3 + i) * 2 + 1] = -im; }
    }
    const tr = (H[0] + H[8] + H[16]) / 3; H[0] -= tr; H[8] -= tr; H[16] -= tr;
    const X = M3(); for (let k = 0; k < 9; k++) { X[2 * k] = -eps * H[2 * k + 1]; X[2 * k + 1] = eps * H[2 * k]; } // X = i eps H
    const out = setId(M3()), term = setId(M3()), tmp = M3();
    for (let n = 1; n <= 4; n++) { mul(term, X, tmp); for (let k = 0; k < 18; k++) term[k] = tmp[k] / n; for (let k = 0; k < 18; k++) out[k] += term[k]; }
    reunitarize(out); return out;
  }
  function randomSU3(R) {
    const u = M3(); for (let k = 0; k < 18; k++) u[k] = gauss(R);
    reunitarize(u); return u;
  }

  class Lattice {
    constructor(params = {}) {
      const p = this.p = Object.assign({}, DEFAULTS, params);
      this.R = rng(p.seed);
      this.dims = [p.Ns, p.Ns, p.Ns, p.Nt]; // x, y, z, t
      this.V = p.Ns * p.Ns * p.Ns * p.Nt;
      this.U = new Float64Array(this.V * 4 * 18);
      // neighbour tables: up[x*4+mu], dn[x*4+mu]
      this.up = new Int32Array(this.V * 4); this.dn = new Int32Array(this.V * 4);
      const [X, Y, Z, T] = this.dims;
      for (let t = 0; t < T; t++) for (let z = 0; z < Z; z++) for (let y = 0; y < Y; y++) for (let x = 0; x < X; x++) {
        const c = [x, y, z, t], i = this.index(c);
        for (let mu = 0; mu < 4; mu++) {
          const u = c.slice(), d = c.slice();
          u[mu] = (u[mu] + 1) % this.dims[mu]; d[mu] = (d[mu] - 1 + this.dims[mu]) % this.dims[mu];
          this.up[i * 4 + mu] = this.index(u); this.dn[i * 4 + mu] = this.index(d);
        }
      }
      for (let l = 0; l < this.V * 4; l++) {
        const m = p.start === "hot" ? randomSU3(this.R) : setId(M3());
        this.U.set(m, l * 18);
      }
      this.pool = []; for (let k = 0; k < 200; k++) { const m = nearIdentity(this.R, p.eps); this.pool.push(m); const d = M3(); dagMul(m, setId(M3()), d); this.pool.push(d); }
      this.sweeps = 0; this.accepted = 0; this.tried = 0;
      this._a = M3(); this._b = M3(); this._c = M3(); this._s = M3(); this._n = M3(); this._u = M3();
    }
    index(c) { const [X, Y, Z] = this.dims; return ((c[3] * Z + c[2]) * Y + c[1]) * X + c[0]; }
    coords(i) { const [X, Y, Z] = this.dims; return [i % X, ((i / X) | 0) % Y, ((i / (X * Y)) | 0) % Z, (i / (X * Y * Z)) | 0]; }
    link(i, mu) { return this.U.subarray((i * 4 + mu) * 18, (i * 4 + mu) * 18 + 18); }
    // sum of the 6 staples around link (i, mu): Re Tr(U A) is the part of the action that depends on U
    staple(i, mu, A) {
      A.fill(0); const a = this._a, b = this._b, ip = this.up[i * 4 + mu];
      for (let nu = 0; nu < 4; nu++) {
        if (nu === mu) continue;
        // forward: U_nu(x+mu) U_mu(x+nu)^dag U_nu(x)^dag
        mulDag(this.link(ip, nu), this.link(this.up[i * 4 + nu], mu), a);
        mulDag(a, this.link(i, nu), b); for (let k = 0; k < 18; k++) A[k] += b[k];
        // backward: U_nu(x+mu-nu)^dag U_mu(x-nu)^dag U_nu(x-nu)
        const xmn = this.dn[i * 4 + nu], xpmn = this.dn[ip * 4 + nu];
        mulDag(setId(this._c), this.link(xpmn, nu), a);           // a = U_nu(x+mu-nu)^dag
        mulDag(a, this.link(xmn, mu), b);                          // b = a U_mu(x-nu)^dag
        mul(b, this.link(xmn, nu), a); for (let k = 0; k < 18; k++) A[k] += a[k];
      }
      return A;
    }
    sweep() {
      const p = this.p, A = this._s, nu = this._n, R = this.R, f = p.beta / 3;
      for (let i = 0; i < this.V; i++) for (let mu = 0; mu < 4; mu++) {
        this.staple(i, mu, A);
        const u = this.link(i, mu); let old = reTrMul(u, A);
        for (let h = 0; h < p.hits; h++) {
          mul(this.pool[(R() * this.pool.length) | 0], u, nu);
          const nw = reTrMul(nu, A); this.tried++;
          if (nw >= old || R() < Math.exp(f * (nw - old))) { u.set(nu); old = nw; this.accepted++; }
        }
        reunitarize(this.U, (i * 4 + mu) * 18);
      }
      this.sweeps++;
    }
    acceptance() { return this.tried ? this.accepted / this.tried : 0; }
    // Re Tr of the plaquette in plane (mu, nu) at site i, / 3
    plaq(i, mu, nu) {
      const a = this._a, b = this._b;
      mul(this.link(i, mu), this.link(this.up[i * 4 + mu], nu), a);
      mulDag(a, this.link(this.up[i * 4 + nu], mu), b);
      return reTrMul(b, dagMul(this.link(i, nu), setId(this._c), a)) / 3; // Re Tr(b U_nu(x)^dag)
    }
    plaquette() {
      let s = 0;
      for (let i = 0; i < this.V; i++) for (let mu = 0; mu < 4; mu++) for (let nu = mu + 1; nu < 4; nu++) s += this.plaq(i, mu, nu);
      return s / (this.V * 6);
    }
    // per-site action density: sum over the 6 planes of (1 - Re Tr P / 3)
    actionDensity() {
      const out = new Float64Array(this.V);
      for (let i = 0; i < this.V; i++) { let s = 0; for (let mu = 0; mu < 4; mu++) for (let nu = mu + 1; nu < 4; nu++) s += 1 - this.plaq(i, mu, nu); out[i] = s; }
      return out;
    }
    // walk n steps along mu (negative n = backward), multiplying links into M
    _walk(i, mu, n, M) {
      const t = this._u;
      if (n > 0) for (let k = 0; k < n; k++) { mul(M, this.link(i, mu), t); M.set(t); i = this.up[i * 4 + mu]; }
      else for (let k = 0; k < -n; k++) { i = this.dn[i * 4 + mu]; mulDag(M, this.link(i, mu), t); M.set(t); }
      return i;
    }
    // W(R, T): R along a spatial direction, T along time. Averaged over sites and the 3 spatial directions.
    wilson(Rr, Tt) {
      const M = M3(); let s = 0, n = 0;
      for (let i = 0; i < this.V; i++) for (let mu = 0; mu < 3; mu++) {
        setId(M); let j = i;
        j = this._walk(j, mu, Rr, M); j = this._walk(j, 3, Tt, M); j = this._walk(j, mu, -Rr, M); j = this._walk(j, 3, -Tt, M);
        s += reTr(M) / 3; n++;
      }
      return s / n;
    }
    // spatial-only Wilson loops (both sides spatial), used when Nt is short
    wilsonSpatial(Rr, Tt) {
      const M = M3(); let s = 0, n = 0;
      for (let i = 0; i < this.V; i++) for (let mu = 0; mu < 3; mu++) for (let nu = 0; nu < 3; nu++) {
        if (nu === mu) continue;
        setId(M); let j = i;
        j = this._walk(j, mu, Rr, M); j = this._walk(j, nu, Tt, M); j = this._walk(j, mu, -Rr, M); j = this._walk(j, nu, -Tt, M);
        s += reTr(M) / 3; n++;
      }
      return s / n;
    }
    // Polyakov loop: average over spatial sites of Tr(prod of time links)/3. Returns [re, im] of the average.
    polyakov(perSite = false) {
      const [X, Y, Z, T] = this.dims, M = M3(); let re = 0, im = 0; const sites = perSite ? [] : null;
      for (let s = 0; s < X * Y * Z; s++) {
        setId(M); this._walk(s, 3, T, M);
        const r = reTr(M) / 3, m = imTr(M) / 3; re += r; im += m; if (sites) sites.push([r, m]);
      }
      const n = X * Y * Z;
      return perSite ? { re: re / n, im: im / n, sites } : [re / n, im / n];
    }
    // largest unitarity error of any link (should stay ~1e-15)
    unitarityError() {
      let worst = 0; const t = M3();
      for (let l = 0; l < this.V * 4; l++) {
        const u = this.U.subarray(l * 18, l * 18 + 18); mulDag(u, u, t);
        for (let i = 0; i < 3; i++) for (let j = 0; j < 3; j++) { const d = Math.hypot(t[(i * 3 + j) * 2] - (i === j ? 1 : 0), t[(i * 3 + j) * 2 + 1]); if (d > worst) worst = d; }
      }
      return worst;
    }
  }
  // Creutz ratio from a table of W values keyed "R,T"
  function creutz(W, r) { const a = W[`${r},${r}`], b = W[`${r - 1},${r - 1}`], c = W[`${r},${r - 1}`]; return a > 0 && b > 0 && c > 0 ? -Math.log(a * b / (c * c)) : NaN; }
  // Leading expansions of the plaquette, for checks
  const strongCoupling = beta => beta / 18 + beta * beta / 216; // small beta
  const weakCoupling = beta => 1 - 2 / beta;                   // large beta, one loop
  const api = { Lattice, DEFAULTS, creutz, strongCoupling, weakCoupling, _m: { mul, mulDag, dagMul, reTr, reunitarize, M3, setId } };
  if (typeof module !== "undefined") module.exports = api; else root.SU3Lab = api;
})(this);
