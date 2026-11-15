// ORIGIN lab: superconductor, layer 1 ("watch it"). Classical 2D lattice of ions on springs,
// with electrons that actually move through it. Standard physics, separate from origin's pixel rules.
//
// What it can show: the lattice wake an electron leaves, and whether that wake makes two electrons
// attract (the mechanism behind Cooper pairing). What it can't show: superconductivity itself,
// which needs quantum mechanics (layer 2). See README.md.
//
// Units: nearest-neighbour bond = 1, electron mass = 1, Boltzmann constant = 1.
(function (root) {
  const DEFAULTS = {
    lattice: "square",   // square | triangular | honeycomb (every nearest-neighbour bond has length 1)
    cells: 16,           // unit cells along x and y
    M: 400,              // ion mass (electron mass = 1). Real ratios are 1,800 (H) to 380,000 (Pb).
    k0: 0.2,             // spring tying each ion to its site
    k1: 1.0,             // spring along each nearest-neighbour bond (stiffness; stands in for pressure)
    g: 1.0,              // electron-ion coupling: depth of each ion's Gaussian pull on an electron
    sigma: 0.6,          // width of that pull (broad, so a perfect lattice feels nearly flat)
    U: 1.0,              // electron-electron repulsion strength (screened Coulomb)
    screen: 1.5,         // screening length of that repulsion
    ne: 2,               // number of electrons
    vF: 1.0,             // Fermi speed: degenerate electrons keep this speed (see fermi)
    fermi: true,         // hold each electron at vF (Pauli: electrons can't slow into filled states)
    T: 0.002,            // temperature of the ions (Langevin thermostat)
    gamma: 0.02,         // thermostat friction on ions
    vacancy: 0,          // fraction of ions removed (disorder)
    dt: 0.02,            // time step
    seed: 1,
  };

  function rng(seed) { let a = seed >>> 0 || 1; return () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }

  const CELLS = {
    square: { w: 1, h: 1, basis: [[0, 0]] },
    triangular: { w: 1, h: Math.sqrt(3), basis: [[0, 0], [0.5, Math.sqrt(3) / 2]] },
    honeycomb: { w: Math.sqrt(3), h: 3, basis: [[0, 0], [0, 1], [Math.sqrt(3) / 2, 1.5], [Math.sqrt(3) / 2, 2.5]] },
  };

  class Lab2D {
    constructor(params = {}) {
      const p = this.p = Object.assign({}, DEFAULTS, params);
      const R = this.rand = rng(p.seed);
      const c = CELLS[p.lattice];
      this.Lx = p.cells * c.w; this.Ly = p.cells * c.h;
      // ions: equilibrium sites (x0, y0), displacement (ux, uy), velocity
      const sites = [];
      for (let j = 0; j < p.cells; j++) for (let i = 0; i < p.cells; i++) for (const [bx, by] of c.basis) sites.push([i * c.w + bx, j * c.h + by]);
      const all = sites.length;
      this.allSites = all;
      this.ion = sites.filter(() => R() >= p.vacancy);
      const n = this.n = this.ion.length;
      this.x0 = new Float64Array(n); this.y0 = new Float64Array(n);
      this.ux = new Float64Array(n); this.uy = new Float64Array(n);
      this.vx = new Float64Array(n); this.vy = new Float64Array(n);
      this.fx = new Float64Array(n); this.fy = new Float64Array(n);
      this.ion.forEach(([x, y], k) => { this.x0[k] = x; this.y0[k] = y; });
      // thermal start for ions
      const sd = Math.sqrt(p.T / p.M);
      for (let k = 0; k < n; k++) { this.vx[k] = sd * gauss(R); this.vy[k] = sd * gauss(R); }
      // bonds: pairs at distance 1 (periodic)
      const bins = this.binIons();
      const bonds = [];
      for (let a = 0; a < n; a++) this.near(this.x0[a], this.y0[a], 1.2, bins, (b, dx, dy) => {
        if (b > a && Math.abs(Math.hypot(dx, dy) - 1) < 1e-6) bonds.push([a, b]);
      });
      this.bonds = bonds;
      this.bins = bins;
      // electrons: random positions, random directions at speed vF
      this.ne = p.ne;
      this.ex = new Float64Array(p.ne); this.ey = new Float64Array(p.ne);
      this.evx = new Float64Array(p.ne); this.evy = new Float64Array(p.ne);
      this.efx = new Float64Array(p.ne); this.efy = new Float64Array(p.ne);
      for (let e = 0; e < p.ne; e++) {
        this.ex[e] = R() * this.Lx; this.ey[e] = R() * this.Ly;
        const th = R() * 2 * Math.PI; this.evx[e] = p.vF * Math.cos(th); this.evy[e] = p.vF * Math.sin(th);
      }
      this.t = 0;
      this.forces();
    }
    // periodic minimal image
    wrapD(d, L) { return d - L * Math.round(d / L); }
    // bin ions by their equilibrium site (displacements are small), bins of size 1
    binIons() {
      const bx = Math.max(1, Math.floor(this.Lx)), by = Math.max(1, Math.floor(this.Ly));
      const b = { bx, by, cell: Array.from({ length: bx * by }, () => []) };
      for (let k = 0; k < this.n; k++) {
        const i = Math.min(bx - 1, Math.floor(this.x0[k] / this.Lx * bx)), j = Math.min(by - 1, Math.floor(this.y0[k] / this.Ly * by));
        b.cell[j * bx + i].push(k);
      }
      return b;
    }
    near(x, y, r, b, fn) {
      const sx = this.Lx / b.bx, sy = this.Ly / b.by, ri = Math.ceil(r / sx) + 1, rj = Math.ceil(r / sy) + 1;
      const ci = Math.floor(x / sx), cj = Math.floor(y / sy), seen = new Set();
      for (let dj = -rj; dj <= rj; dj++) for (let di = -ri; di <= ri; di++) {
        const i = ((ci + di) % b.bx + b.bx) % b.bx, j = ((cj + dj) % b.by + b.by) % b.by, key = j * b.bx + i;
        if (seen.has(key)) continue; seen.add(key);
        for (const k of b.cell[key]) {
          const dx = this.wrapD(this.x0[k] - x, this.Lx), dy = this.wrapD(this.y0[k] - y, this.Ly);
          if (dx * dx + dy * dy <= r * r) fn(k, dx, dy);
        }
      }
    }
    forces() {
      const p = this.p, n = this.n;
      this.fx.fill(0); this.fy.fill(0); this.efx.fill(0); this.efy.fill(0);
      let pot = 0;
      // ion springs: to own site, and along bonds (central, rest length 1)
      for (let k = 0; k < n; k++) { this.fx[k] -= p.k0 * this.ux[k]; this.fy[k] -= p.k0 * this.uy[k]; pot += 0.5 * p.k0 * (this.ux[k] ** 2 + this.uy[k] ** 2); }
      for (const [a, b] of this.bonds) {
        const dx = this.wrapD(this.x0[b] + this.ux[b] - this.x0[a] - this.ux[a], this.Lx), dy = this.wrapD(this.y0[b] + this.uy[b] - this.y0[a] - this.uy[a], this.Ly);
        const d = Math.hypot(dx, dy), s = p.k1 * (d - 1) / d;
        this.fx[a] += s * dx; this.fy[a] += s * dy; this.fx[b] -= s * dx; this.fy[b] -= s * dy; pot += 0.5 * p.k1 * (d - 1) ** 2;
      }
      // electron-ion: V = -g exp(-r^2 / 2 sigma^2), equal and opposite
      // cutoff at 5 sigma, with the potential shifted to 0 there, so nothing jumps when an ion crosses it
      const s2 = p.sigma * p.sigma, cut = 5 * p.sigma, vcut = Math.exp(-12.5);
      for (let e = 0; e < this.ne; e++) {
        const x = this.ex[e], y = this.ey[e];
        this.near(x, y, cut + 0.5, this.bins, (k) => {
          const dx = this.wrapD(this.x0[k] + this.ux[k] - x, this.Lx), dy = this.wrapD(this.y0[k] + this.uy[k] - y, this.Ly);
          const r2 = dx * dx + dy * dy; if (r2 > cut * cut) return;
          const v = p.g * Math.exp(-r2 / (2 * s2)), f = v / s2; // force on electron toward ion = f * (dx, dy)
          this.efx[e] += f * dx; this.efy[e] += f * dy; this.fx[k] -= f * dx; this.fy[k] -= f * dy; pot -= v - p.g * vcut;
        });
      }
      // electron-electron: V = U exp(-r/screen) / sqrt(r^2 + 0.25)
      for (let a = 0; a < this.ne; a++) for (let b = a + 1; b < this.ne; b++) {
        const dx = this.wrapD(this.ex[b] - this.ex[a], this.Lx), dy = this.wrapD(this.ey[b] - this.ey[a], this.Ly);
        const r = Math.hypot(dx, dy), q = Math.sqrt(r * r + 0.25), ex = Math.exp(-r / p.screen), V = p.U * ex / q;
        const dVdr = -V / p.screen - p.U * ex * r / (q * q * q), F = -dVdr / (r || 1e-9);
        this.efx[a] -= F * dx; this.efy[a] -= F * dy; this.efx[b] += F * dx; this.efy[b] += F * dy; pot += V;
      }
      this.pot = pot;
    }
    step() {
      const p = this.p, dt = p.dt, n = this.n, R = this.rand;
      // velocity Verlet, half kick
      for (let k = 0; k < n; k++) { this.vx[k] += 0.5 * dt * this.fx[k] / p.M; this.vy[k] += 0.5 * dt * this.fy[k] / p.M; }
      for (let e = 0; e < this.ne; e++) { this.evx[e] += 0.5 * dt * this.efx[e]; this.evy[e] += 0.5 * dt * this.efy[e]; }
      for (let k = 0; k < n; k++) { this.ux[k] += dt * this.vx[k]; this.uy[k] += dt * this.vy[k]; }
      for (let e = 0; e < this.ne; e++) {
        this.ex[e] = ((this.ex[e] + dt * this.evx[e]) % this.Lx + this.Lx) % this.Lx;
        this.ey[e] = ((this.ey[e] + dt * this.evy[e]) % this.Ly + this.Ly) % this.Ly;
      }
      this.forces();
      for (let k = 0; k < n; k++) { this.vx[k] += 0.5 * dt * this.fx[k] / p.M; this.vy[k] += 0.5 * dt * this.fy[k] / p.M; }
      for (let e = 0; e < this.ne; e++) { this.evx[e] += 0.5 * dt * this.efx[e]; this.evy[e] += 0.5 * dt * this.efy[e]; }
      // ion thermostat (Langevin)
      if (p.gamma > 0) {
        const c1 = Math.exp(-p.gamma * dt), c2 = Math.sqrt((1 - c1 * c1) * p.T / p.M);
        for (let k = 0; k < n; k++) { this.vx[k] = c1 * this.vx[k] + c2 * gauss(R); this.vy[k] = c1 * this.vy[k] + c2 * gauss(R); }
      }
      // degenerate electrons stay at the Fermi speed (direction is free)
      if (p.fermi) for (let e = 0; e < this.ne; e++) { const s = Math.hypot(this.evx[e], this.evy[e]) || 1; this.evx[e] *= p.vF / s; this.evy[e] *= p.vF / s; }
      this.t += dt;
    }
    // --- measurements ---
    pairDistances() {
      const o = [];
      for (let a = 0; a < this.ne; a++) for (let b = a + 1; b < this.ne; b++)
        o.push(Math.hypot(this.wrapD(this.ex[b] - this.ex[a], this.Lx), this.wrapD(this.ey[b] - this.ey[a], this.Ly)));
      return o;
    }
    // local compression of each ion: mean bond shortening (positive = squeezed = extra positive charge)
    compression() {
      const c = new Float64Array(this.n), m = new Float64Array(this.n);
      for (const [a, b] of this.bonds) {
        const dx = this.wrapD(this.x0[b] + this.ux[b] - this.x0[a] - this.ux[a], this.Lx), dy = this.wrapD(this.y0[b] + this.uy[b] - this.y0[a] - this.uy[a], this.Ly);
        const s = 1 - Math.hypot(dx, dy); c[a] += s; c[b] += s; m[a]++; m[b]++;
      }
      for (let k = 0; k < this.n; k++) if (m[k]) c[k] /= m[k];
      return c;
    }
    // phonon frequencies of the perfect lattice (harmonic, k-grid): for omega_log in layer 3
    phonons(grid = 24) {
      const p = this.p, cdef = CELLS[p.lattice], nb = cdef.basis.length, D = 2 * nb, out = [];
      // bonds within/among basis atoms of neighbouring cells, from the perfect lattice
      const links = [];
      for (let a = 0; a < nb; a++) for (let b = 0; b < nb; b++) for (let i = -2; i <= 2; i++) for (let j = -2; j <= 2; j++) {
        const dx = cdef.basis[b][0] + i * cdef.w - cdef.basis[a][0], dy = cdef.basis[b][1] + j * cdef.h - cdef.basis[a][1];
        if (Math.abs(Math.hypot(dx, dy) - 1) < 1e-6) links.push([a, b, i, j, dx, dy]);
      }
      for (let gi = 0; gi < grid; gi++) for (let gj = 0; gj < grid; gj++) {
        const kx = 2 * Math.PI * gi / (grid * cdef.w), ky = 2 * Math.PI * gj / (grid * cdef.h);
        const Re = Array.from({ length: D }, () => new Float64Array(D)), Im = Array.from({ length: D }, () => new Float64Array(D));
        for (let a = 0; a < nb; a++) { Re[2 * a][2 * a] += p.k0; Re[2 * a + 1][2 * a + 1] += p.k0; }
        for (const [a, b, i, j, dx, dy] of links) {
          const ux = dx, uy = dy, K = [[ux * ux, ux * uy], [uy * ux, uy * uy]].map(r => r.map(v => v * p.k1));
          const ph = kx * (i * cdef.w) + ky * (j * cdef.h), cr = Math.cos(ph), ci = Math.sin(ph);
          for (let r = 0; r < 2; r++) for (let s = 0; s < 2; s++) {
            Re[2 * a + r][2 * a + s] += K[r][s];
            Re[2 * a + r][2 * b + s] -= K[r][s] * cr; Im[2 * a + r][2 * b + s] -= K[r][s] * ci;
          }
        }
        // Hermitian D x D -> real symmetric 2D x 2D, eigenvalues come in pairs
        const H = Array.from({ length: 2 * D }, () => new Float64Array(2 * D));
        for (let r = 0; r < D; r++) for (let s = 0; s < D; s++) {
          H[r][s] = Re[r][s]; H[r + D][s + D] = Re[r][s]; H[r][s + D] = -Im[r][s]; H[r + D][s] = Im[r][s];
        }
        const ev = jacobi(H).sort((x, y) => x - y);
        for (let q = 0; q < ev.length; q += 2) out.push(Math.sqrt(Math.max(0, ev[q]) / p.M));
      }
      return out;
    }
  }
  function gauss(R) { let u = 0; while (!u) u = R(); return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * R()); }
  function jacobi(A0) {
    const n = A0.length, A = A0.map(r => Float64Array.from(r));
    for (let sweep = 0; sweep < 60; sweep++) {
      let off = 0; for (let i = 0; i < n; i++) for (let j = i + 1; j < n; j++) off += A[i][j] ** 2;
      if (off < 1e-20) break;
      for (let p = 0; p < n; p++) for (let q = p + 1; q < n; q++) {
        if (Math.abs(A[p][q]) < 1e-15) continue;
        const th = 0.5 * Math.atan2(2 * A[p][q], A[q][q] - A[p][p]), c = Math.cos(th), s = Math.sin(th);
        for (let k = 0; k < n; k++) { const a = A[k][p], b = A[k][q]; A[k][p] = c * a - s * b; A[k][q] = s * a + c * b; }
        for (let k = 0; k < n; k++) { const a = A[p][k], b = A[q][k]; A[p][k] = c * a - s * b; A[q][k] = s * a + c * b; }
      }
    }
    return A.map((r, i) => r[i]);
  }
  const api = { Lab2D, DEFAULTS, CELLS };
  if (typeof module !== "undefined") module.exports = api; else root.SCLab = api;
})(this);
