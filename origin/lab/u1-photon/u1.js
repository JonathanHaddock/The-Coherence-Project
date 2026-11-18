// ORIGIN lab: compact U(1) lattice gauge theory (the field theory behind Levin & Wen's emergent photons).
// Standard physics, separate from origin's pixel rules.
//
// Each link holds an angle theta in (-pi, pi]: a phase. A plaquette angle is the sum around a unit square,
// theta_p = th_mu(x) + th_nu(x+mu) - th_mu(x+nu) - th_nu(x). Action S = beta * sum_p (1 - cos theta_p).
// Levin & Wen's rotor model maps onto exactly this theory: its "string-net condensed" phase is the
// Coulomb phase here (massless photon, charges feel 1/R), and its uncondensed phase is the confined phase.
// In 4D the two are separated by a transition near beta ~ 1.01. In 2D there is no Coulomb phase.
//
// Runs in node (require) and in the browser (window.U1Lab).
(function (root) {
  const DEFAULTS = { d: 4, L: 8, beta: 1.1, start: "cold", hits: 4, delta: 1.0, seed: 1 };
  function rng(seed) { let a = seed >>> 0 || 1; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
  const wrap = a => a - 2 * Math.PI * Math.round(a / (2 * Math.PI));

  class U1 {
    constructor(params = {}) {
      const p = this.p = Object.assign({}, DEFAULTS, params), d = p.d, L = p.L;
      this.R = rng(p.seed); this.V = L ** d;
      this.th = new Float64Array(this.V * d);
      if (p.start === "hot") for (let k = 0; k < this.th.length; k++) this.th[k] = (2 * this.R() - 1) * Math.PI;
      this.up = new Int32Array(this.V * d); this.dn = new Int32Array(this.V * d);
      for (let i = 0; i < this.V; i++) for (let mu = 0; mu < d; mu++) {
        const s = L ** mu, c = Math.floor(i / s) % L;
        this.up[i * d + mu] = i + ((c + 1) % L - c) * s; this.dn[i * d + mu] = i + ((c - 1 + L) % L - c) * s;
      }
      this.sweeps = 0; this.acc = 0; this.tried = 0;
    }
    plaqAngle(i, mu, nu, th = this.th) { const d = this.p.d; return th[i * d + mu] + th[this.up[i * d + mu] * d + nu] - th[this.up[i * d + nu] * d + mu] - th[i * d + nu]; }
    // sum over the plaquettes containing link (i, mu) of cos(theta_link + rest): returns [C, S] with
    // sum cos(theta + a_k) = C cos theta - S sin theta, so the local action is -beta (C cos - S sin)
    staple(i, mu) {
      const d = this.p.d, th = this.th, up = this.up, dn = this.dn; let C = 0, S = 0;
      for (let nu = 0; nu < d; nu++) {
        if (nu === mu) continue;
        let a = th[up[i * d + mu] * d + nu] - th[up[i * d + nu] * d + mu] - th[i * d + nu]; C += Math.cos(a); S += Math.sin(a);
        const j = dn[i * d + nu]; // plaquette (j, mu, nu) contains link (i,mu) with sign -
        const b = th[j * d + mu] + th[up[j * d + mu] * d + nu] - th[j * d + nu]; // theta_p = b - theta_link
        C += Math.cos(b); S -= Math.sin(b);                                                // cos(b - t) = cos b cos t + sin b sin t
      }
      return [C, S];
    }
    sweep() {
      const p = this.p, d = p.d, R = this.R;
      for (let l = 0; l < this.V * d; l++) {
        const i = (l / d) | 0, mu = l % d, [C, S] = this.staple(i, mu);
        let t = this.th[l], old = C * Math.cos(t) - S * Math.sin(t);
        for (let h = 0; h < p.hits; h++) {
          const nt = wrap(t + (2 * R() - 1) * p.delta), nw = C * Math.cos(nt) - S * Math.sin(nt); this.tried++;
          if (nw >= old || R() < Math.exp(p.beta * (nw - old))) { t = nt; old = nw; this.acc++; }
        }
        this.th[l] = t;
      }
      this.sweeps++;
    }
    plaquette() {
      const d = this.p.d; let s = 0, n = 0;
      for (let i = 0; i < this.V; i++) for (let mu = 0; mu < d; mu++) for (let nu = mu + 1; nu < d; nu++) { s += Math.cos(this.plaqAngle(i, mu, nu)); n++; }
      return s / n;
    }
    // APE smearing of links in `dirs` (complex average of link and staples, take the angle)
    ape(dirs, alpha, steps) {
      const d = this.p.d, up = this.up, dn = this.dn; let src = Float64Array.from(this.th), dst = new Float64Array(src.length);
      const w = dirs.length > 1 ? alpha / (2 * (dirs.length - 1)) : 0;
      for (let n = 0; n < steps; n++) {
        dst.set(src);
        for (let i = 0; i < this.V; i++) for (const mu of dirs) {
          let re = (1 - alpha) * Math.cos(src[i * d + mu]), im = (1 - alpha) * Math.sin(src[i * d + mu]);
          for (const nu of dirs) {
            if (nu === mu) continue;
            let a = src[i * d + nu] + src[up[i * d + nu] * d + mu] - src[up[i * d + mu] * d + nu]; re += w * Math.cos(a); im += w * Math.sin(a);
            const j = dn[i * d + nu]; a = -src[j * d + nu] + src[j * d + mu] + src[up[j * d + mu] * d + nu]; re += w * Math.cos(a); im += w * Math.sin(a);
          }
          dst[i * d + mu] = Math.atan2(im, re);
        }
        const t = src; src = dst; dst = t;
      }
      return src;
    }
    // time-like Wilson loops <cos(sum of angles around R x T)>, R along each direction != tau
    loops(Rmax, Tmax, tau, space = this.th) {
      const d = this.p.d, V = this.V, up = this.up, out = {};
      const line = (arr, mu, n) => { const o = [null, new Float64Array(V)]; for (let i = 0; i < V; i++) o[1][i] = arr[i * d + mu];
        for (let r = 2; r <= n; r++) { const nx = new Float64Array(V); for (let i = 0; i < V; i++) { let j = i; for (let k = 0; k < r - 1; k++) j = up[j * d + mu]; nx[i] = o[r - 1][i] + arr[j * d + mu]; } o.push(nx); } return o; };
      const sh = (i, mu, n) => { for (let k = 0; k < n; k++) i = up[i * d + mu]; return i; };
      const Tl = line(this.th, tau, Tmax); let ndir = 0;
      for (let mu = 0; mu < d; mu++) {
        if (mu === tau) continue; ndir++;
        const Rl = line(space, mu, Rmax);
        for (let R = 1; R <= Rmax; R++) for (let T = 1; T <= Tmax; T++) {
          let s = 0; for (let i = 0; i < V; i++) s += Math.cos(Rl[R][i] + Tl[T][sh(i, mu, R)] - Rl[R][sh(i, tau, T)] - Tl[T][i]);
          out[R + "," + T] = (out[R + "," + T] || 0) + s / V;
        }
      }
      for (const k in out) out[k] /= ndir;
      return out;
    }
  }
  // modified Bessel I_n(x) by series, for the exact 2D result <cos theta_p> = I1(beta)/I0(beta)
  function besselI(n, x) { let s = 0, t = Math.pow(x / 2, n); for (let k = 1; k <= n; k++) t /= k; for (let k = 0; k < 200; k++) { s += t; t *= (x / 2) * (x / 2) / ((k + 1) * (k + 1 + n)); if (t < 1e-17 * s) break; } return s; }
  const api = { U1, DEFAULTS, besselI, wrap };
  if (typeof module !== "undefined") module.exports = api; else root.U1Lab = api;
})(this);
