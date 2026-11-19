// JS port of origin/src/engine/grid3.zig + pixel.zig (3D lattice, carrier, rule 6 gravity).
const S = 48, N = S * S * S, H = 24;
const DISPLAYS = ["fill_empty", "hold", "one_cell", "flip_all"];

function radius(i) {
  const x = i % S, y = ((i / S) | 0) % S, z = (i / (S * S)) | 0;
  return Math.sqrt((x - H) ** 2 + (y - H) ** 2 + (z - H) ** 2);
}
const POPC = [0, 1, 1, 2, 1, 2, 2, 3], Q3 = [0, -1, 2, -3]; // filled count; charge in thirds
const NB = new Int32Array(N * 6);
const RAD = new Float64Array(N);
for (let i = 0; i < N; i++) {
  const x = i % S, y = ((i / S) | 0) % S, z = (i / (S * S)) | 0;
  const idx = (a, b, c) => (c * S + b) * S + a;
  NB.set([idx((x + 1) % S, y, z), idx((x + S - 1) % S, y, z), idx(x, (y + 1) % S, z),
          idx(x, (y + S - 1) % S, z), idx(x, y, (z + 1) % S), idx(x, y, (z + S - 1) % S)], i * 6);
  RAD[i] = radius(i);
}

// RULE 28: links. LK[i*6+f] = link id through face f of site i (-1 at the box edge).
// Link id = site*3 + axis, owned by the lower site (+x, +y, +z).
const LK = new Int32Array(N * 6);
for (let i = 0; i < N; i++) {
  const x = i % S, y = ((i / S) | 0) % S, z = (i / (S * S)) | 0;
  LK.set([x + 1 < S ? i * 3 : -1, x > 0 ? (i - 1) * 3 : -1, y + 1 < S ? i * 3 + 1 : -1,
          y > 0 ? (i - S) * 3 + 1 : -1, z + 1 < S ? i * 3 + 2 : -1, z > 0 ? (i - S * S) * 3 + 2 : -1], i * 6);
}
// rule 29 (c): Brannen-Koide mass ratios by kind (filled count) and generation
const MASS = [[0, 0, 0], [1, 20, 884], [1, 721, 97300], [1, 207, 3477]];
const SEL = [0, 1, 2, 3, 4, 5, 6, 7].map(p => { const c = (p & 1) + ((p >> 1) & 1) + ((p >> 2) & 1); return c === 0 ? [1, 0, 0] : c === 3 ? [1, 1, 0] : [1, 1, 1]; });

class Engine {
  constructor(cfg) {
    this.cfg = Object.assign({ mode: "lattice", display: "one_cell", update: "sync", core: 8, gravity: false, seed: 20261110n }, cfg);
    this.pat = new Uint8Array(N);
    this.rf = new Uint32Array(N * 3);
    this.cs = new Uint32Array(N * 3);
    this.fired = new Uint8Array(N);
    this.carrier = new Float64Array(N);
    this.next = new Float64Array(N);
    this.car3 = new Float64Array(N * 3); this.nxt3 = new Float64Array(N * 3); this.absorbed = new Float64Array(12);
    this.car6 = new Float64Array(N * 6); this.nxt6 = new Float64Array(N * 6);
    this.t = 0; this.total = 0;
    this.home = new Uint32Array(N).map((_, i) => i); this.moved = new Uint8Array(N); this.swaps = 0;
    this.phi = new Float64Array(N); this.phin = new Float64Array(N);
    const M = (1n << 64n) - 1n;
    let s = BigInt(this.cfg.seed);
    for (let i = 0; i < N; i++) {
      s ^= (s << 13n) & M; s ^= s >> 7n; s ^= (s << 17n) & M;
      this.pat[i] = Number(s & 7n);
      for (let k = 0; k < 3; k++) this.cs[i * 3 + k] = Number((s >> BigInt(8 + 2 * k)) % 2n);
    }
    if (this.cfg.links) this.initLinks(s, M);
    if (this.cfg.core > 0) for (let i = 0; i < N; i++) if (RAD[i] <= this.cfg.core) {
      this.pat[i] = 7; this.cs[i * 3] = this.cs[i * 3 + 1] = this.cs[i * 3 + 2] = 1;
    }
    this.kick = (H * S + H) * S + H;
    if (this.cfg.five) this.initFive();
  }
  ready(i) { return this.cs[i * 3] + this.cs[i * 3 + 1] + this.cs[i * 3 + 2] >= 3; }
  // pattern pixel i would display if it flashed now (no state change)
  nextPat(i) {
    const d = this.cfg.display, r = this.rf, c = this.cs, b = i * 3;
    let p = this.pat[i];
    if (d === "fill_empty") {
      for (let k = 0; k < 3; k++) { if (r[b + k] > c[b + k]) p |= 1 << k; else if (r[b + k] < c[b + k]) p &= ~(1 << k); }
    } else if (d === "one_cell") {
      let best = -1, sur = 0;
      for (let k = 0; k < 3; k++) if (c[b + k] > r[b + k] && c[b + k] - r[b + k] > sur) { sur = c[b + k] - r[b + k]; best = k; }
      if (best >= 0) p ^= 1 << best;
    } else if (d === "flip_all") {
      for (let k = 0; k < 3; k++) if (c[b + k] > r[b + k]) p ^= 1 << k;
    }
    return p & 7;
  }
  // RULE 22: a flash may not display a pattern any neighbour is showing; blocked = wait.
  blocked(i) {
    if (!this.cfg.exclusion) return false;
    const nx = this.nextPat(i);
    for (let q = 0; q < 6; q++) if (this.pat[NB[i * 6 + q]] === nx) return true;
    return false;
  }
  flash(i) {
    const d = this.cfg.display, r = this.rf, c = this.cs, b = i * 3;
    let p = this.pat[i];
    if (d === "fill_empty") {
      for (let k = 0; k < 3; k++) { if (r[b + k] > c[b + k]) p |= 1 << k; else if (r[b + k] < c[b + k]) p &= ~(1 << k); }
    } else if (d === "one_cell") {
      let best = -1, sur = 0;
      for (let k = 0; k < 3; k++) if (c[b + k] > r[b + k] && c[b + k] - r[b + k] > sur) { sur = c[b + k] - r[b + k]; best = k; }
      if (best >= 0) p ^= 1 << best;
    } else if (d === "flip_all") {
      for (let k = 0; k < 3; k++) if (c[b + k] > r[b + k]) p ^= 1 << k;
    }
    this.pat[i] = p & 7;
    const rel = c[b] + c[b + 1] + c[b + 2];
    if (this.cfg.conserve) { if (!this.rel3) this.rel3 = new Uint32Array(N * 3); this.rel3[b] = c[b]; this.rel3[b + 1] = c[b + 1]; this.rel3[b + 2] = c[b + 2]; }
    r[b] = r[b + 1] = r[b + 2] = c[b] = c[b + 1] = c[b + 2] = 0;
    if (!this.cfg.conserve) this.deposit(i, rel);
    this.fired[i] = 1;
  }
  deposit(i, amt) {
    if (this.cfg.channels) {
      const sl = Engine.select(this.pat[i]); let k = 0; for (const on of sl) k += on ? 1 : 0;
      const share = amt / k;
      for (let ch = 0; ch < 3; ch++) if (sl[ch]) this.car3[i * 3 + ch] += share;
    } else this.carrier[i] += amt;
  }
  // neighbours hear pixel i's flash. RULE 27: memory is dealt out, not created.
  shout(i) {
    const sh = this.pat[i];
    if (!this.cfg.conserve) { for (let q = 0; q < 6; q++) this.receive(NB[i * 6 + q], sh); return; }
    const tg = [0, 0, 0, 0, 0, 0];
    for (let k = 0; k < 3; k++) {
      const bit = (sh >> k) & 1; let m = 0;
      for (let q = 0; q < 6; q++) { const j = NB[i * 6 + q]; if (((this.pat[j] >> k) & 1) === bit) this.rf[j * 3 + k]++; else tg[m++] = j; }
      const units = this.rel3[i * 3 + k];
      if (m === 0) { this.deposit(i, units); continue; }
      for (let u = 0; u < units; u++) this.cs[tg[u % m] * 3 + k]++;
    }
  }
  receive(j, shown) {
    const p = this.pat[j], b = j * 3;
    for (let k = 0; k < 3; k++) { if (((p >> k) & 1) === ((shown >> k) & 1)) this.rf[b + k]++; else this.cs[b + k]++; }
  }
  tick() {
    if (this.cfg.five) return this.tickFive();
    if (this.cfg.mode === "control") return this.tickControl();
    if (this.cfg.mode === "photo") return this.tickPhoto();
    return this.cfg.mode === "lattice" ? this.tickLattice() : this.tickLepton(this.cfg.mode === "signed");
  }
  // PHOTOGRAPH MODE (rules 12-14): lattice, one_cell, sweep, no gravity.
  initPhoto() {
    this.before = new Uint8Array(N); this.f3 = new Float64Array(N * 3); this.n3 = new Float64Array(N * 3);
    this.ph = { events: 0, noflip: 0, up: 0, down: 0, flips: [[0,0],[0,0],[0,0]], realized: new Array(8).fill(0),
      edSum: 0, edMax: 0, elecSum: 0, elecN: 0, totals: [0,0,0], wholeFail: 0 };
  }
  static makeup(p, w) {
    const m = [0,0,0]; let c = 0;
    for (let q = 0; q < 8; q++) { if (q === p) continue; const x = q ^ p; if (w === "next" && (x & (x - 1)) !== 0) continue;
      c++; for (let k = 0; k < 3; k++) if ((q >> k) & 1) m[k]++; }
    return m.map(v => v / c);
  }
  static Dv(v) { const s = v[0]+v[1]+v[2]; if (!s) return 0; return 1.5*((v[0]*v[0]+v[1]*v[1]+v[2]*v[2])/(s*s) - 1/3); }
  tickPhoto() {
    if (!this.ph) this.initPhoto();
    this.before.set(this.pat);
    const c = this.cfg, sv = [c.display, c.update, c.gravity];
    c.display = "one_cell"; c.update = "sweep"; c.gravity = false;
    const count = this.tickLattice();
    [c.display, c.update, c.gravity] = sv;
    const ph = this.ph, w = c.weight || "all7", f = this.f3;
    for (let i = 0; i < N; i++) {
      if (!this.fired[i]) continue;
      const p = this.pat[i], d = p ^ this.before[i];
      ph.events++; ph.realized[p]++;
      if (!d) ph.noflip++;
      for (let k = 0; k < 3; k++) if ((d >> k) & 1) ph.flips[k][((p >> k) & 1) ? 0 : 1]++;
      const pc = x => (x & 1) + ((x >> 1) & 1) + ((x >> 2) & 1), dc = pc(p) - pc(this.before[i]);
      if (dc > 0) ph.up++; else if (dc < 0) ph.down++;
      if (p) { ph.elecSum += Engine.Dv([p & 1, (p >> 1) & 1, (p >> 2) & 1]); ph.elecN++; }
      const m = Engine.makeup(p, w), md = Engine.Dv(m);
      ph.edSum += md; if (md > ph.edMax) ph.edMax = md;
      for (let k = 0; k < 3; k++) { f[i*3+k] += m[k]; ph.totals[k] += m[k]; }
      const a7 = Engine.makeup(p, "all7");
      for (let k = 0; k < 3; k++) if (Math.abs(((p >> k) & 1) + 7 * a7[k] - 4) > 1e-9) { ph.wholeFail++; break; }
    }
    const nx = this.n3; nx.fill(0);
    for (let i = 0; i < N; i++) {
      const a = f[i*3], b = f[i*3+1], cc = f[i*3+2]; if (!a && !b && !cc) continue;
      for (let q = 0; q < 6; q++) { const j = NB[i*6+q] * 3; nx[j] += a/6; nx[j+1] += b/6; nx[j+2] += cc/6; }
    }
    this.f3 = nx; this.n3 = f;
    if (c.deliver === "same" || c.deliver === "unreal") this.deliverNu(c.deliver);
    return count;
  }
  // RULE CHOICES 15-16: neutrinos delivered by pattern, not by space; arrive as memory.
  deliverNu(mode) {
    if (!this.acc) { this.acc = new Float64Array(N * 3); this.recv = new Float64Array(N * 3); }
    const weak = this.cfg.weak, hand = this.cfg.hand, ph = this.ph;
    const pc = x => (x & 1) + ((x >> 1) & 1) + ((x >> 2) & 1);
    // emit[h][p]: h = 0 antineutrino (beta) or unsigned, 1 neutrino (capture)
    const emit = [[], []]; for (let h = 0; h < 2; h++) for (let p = 0; p < 8; p++) emit[h].push([0, 0, 0]);
    for (let i = 0; i < N; i++) if (this.fired[i]) {
      const p = this.pat[i]; let h = 0;
      if (weak) { // RULE 17: only a flipped cell is a weak event
        const b = this.before[i]; if (p === b) continue;
        if (pc(p) > pc(b)) { ph.beta = (ph.beta || 0) + 1; h = 0; } else { ph.capture = (ph.capture || 0) + 1; h = 1; }
      }
      if (!hand) h = 0;
      const m = Engine.makeup(p, "all7"); for (let k = 0; k < 3; k++) emit[h][p][k] += m[k];
    }
    const nOf = new Array(8).fill(0); for (let i = 0; i < N; i++) nOf[this.pat[i]]++;
    for (let h = 0; h < (hand ? 2 : 1); h++) {
      const toClass = []; for (let q = 0; q < 8; q++) toClass.push([0, 0, 0]);
      for (let p = 0; p < 8; p++) {
        const em = emit[h][p]; if (!em[0] && !em[1] && !em[2]) continue;
        if (mode === "same") { for (let k = 0; k < 3; k++) toClass[p][k] += em[k]; }
        else { let tot = 0; for (let q = 0; q < 8; q++) if (q !== p) tot += nOf[q]; if (!tot) continue;
          for (let q = 0; q < 8; q++) if (q !== p && nOf[q]) for (let k = 0; k < 3; k++) toClass[q][k] += em[k] * nOf[q] / tot; }
      }
      for (let i = 0; i < N; i++) { const q = this.pat[i], n = nOf[q]; if (!n) continue;
        for (let k = 0; k < 3; k++) {
          if (hand) { const filled = (q >> k) & 1; if (h === 0 && !filled) continue; if (h === 1 && filled) continue; }
          const v = toClass[q][k] / n; if (!v) continue; this.recv[i*3+k] += v;
          const a = this.acc[i*3+k] + v, w = Math.floor(a); this.acc[i*3+k] = a - w; if (w) this.cs[i*3+k] += w; } }
    }
  }

  fieldD(i) { const f = this.f3; return f ? Engine.Dv([f[i*3], f[i*3+1], f[i*3+2]]) : 0; }
  // CONTROL (not the engine): each pixel flashes with fixed chance p per tick.
  tickControl() {
    if (this.rs === undefined) this.rs = 2463534242 ^ Number(this.cfg.seed & 0xffffffffn);
    const p = this.cfg.p ?? 0.2; let count = 0;
    for (let i = 0; i < N; i++) {
      let x = this.rs; x ^= x << 13; x ^= x >>> 17; x ^= x << 5; this.rs = x >>> 0;
      const f = (this.rs / 4294967296) < p; this.fired[i] = f ? 1 : 0; if (f) count++;
    }
    this.t++; this.total += count; return count;
  }
  tickLepton(signed) {
    const kick = this.t === 0 ? this.kick : -1, cs = this.cs, car = this.car6;
    let count = 0;
    for (let i = 0; i < N; i++) this.fired[i] = (this.ready(i) || i === kick) ? 1 : 0;
    const save = this.cfg.display; this.cfg.display = "one_cell";
    for (let i = 0; i < N; i++) if (this.fired[i]) {
      const m0 = cs[i * 3], m1 = cs[i * 3 + 1], m2 = cs[i * 3 + 2];
      const c0 = this.carrier[i];
      this.flash(i); this.carrier[i] = c0; count++;
      const p = this.pat[i], m = [m0, m1, m2];
      for (let k = 0; k < 3; k++) { const ch = (!signed || ((p >> k) & 1)) ? k : k + 3; car[i * 6 + ch] += m[k]; }
    }
    this.cfg.display = save;
    for (let i = 0; i < N; i++) if (this.fired[i]) { const sh = this.pat[i]; for (let q = 0; q < 6; q++) this.receive(NB[i * 6 + q], sh); }
    // spread on wrapped edges
    const nx = this.nxt6; nx.fill(0);
    for (let i = 0; i < N; i++) {
      const b = i * 6; let any = false;
      for (let c = 0; c < 6; c++) if (car[b + c] !== 0) { any = true; break; }
      if (!any) continue;
      for (let q = 0; q < 6; q++) { const j = NB[i * 6 + q] * 6; for (let c = 0; c < 6; c++) nx[j + c] += car[b + c] / 6; }
    }
    this.car6 = nx; this.nxt6 = car;
    const C = this.car6, rf = this.rf;
    if (this.cfg.mode === "turing") {
      for (let i = 0; i < N; i++) for (let k = 0; k < 3; k++) {
        const v = C[i * 6 + k]; if (v < 1) continue;
        const m = Math.min(Math.floor(v), cs[i * 3 + k]);
        C[i * 6 + k] = v - m; cs[i * 3 + k] -= m;
      }
    } else for (let i = 0; i < N; i++) for (let ch = 0; ch < 6; ch++) {
      const v = C[i * 6 + ch]; if (v < 1) continue;
      const m = Math.floor(v); C[i * 6 + ch] = v - m;
      const k = ch % 3, has = (this.pat[i] >> k) & 1, shown = ch < 3 ? 1 : 0;
      if (has === shown) rf[i * 3 + k] += m; else cs[i * 3 + k] += m;
    }
    let tot = 0; for (let i = 0; i < N; i++) { let s = 0; for (let c = 0; c < 6; c++) s += C[i * 6 + c]; this.carrier[i] = s; }
    this.t++; this.total += count;
    return count;
  }
  // ---------------- RULE 28: fields on links ----------------
  initLinks(s, M) {
    // rule 28 (b, as amended): EM, weak and strong start at rest (0) on every link
    this.L = [new Int32Array(N * 3), new Int32Array(N * 3), new Int32Array(N * 3)];
    // rule 29 (b): a generation per pixel, from the seed
    this.gen = new Uint8Array(N);
    for (let i = 0; i < N; i++) { s ^= (s << 13n) & M; s ^= s >> 7n; s ^= (s << 17n) & M; this.gen[i] = Number(s % 3n); }
  }
  // rule 29 (c): mass = generation coupling x background (1 unit everywhere)
  mass(i) { return this.cfg.higgs ? MASS[POPC[this.pat[i]]][this.gen[i]] : 0; }
  readyL(i) { const b = i * 3; return this.cs[b] + this.cs[b + 1] + this.cs[b + 2] >= 3 + this.mass(i); }
  flashL(i) {
    const sel = SEL[this.pat[i]], b = i * 3, c = this.cs;
    const rel = c[b] + c[b + 1] + c[b + 2];
    this.pat[i] = this.nextPat(i);
    this.rf[b] = this.rf[b + 1] = this.rf[b + 2] = c[b] = c[b + 1] = c[b + 2] = 0;
    this.fired[i] = 1;
    const sl = []; // field by field: weak, EM, strong, weak, ... then the next link (face order)
    for (let f = 0; f < 6; f++) { const l = LK[i * 6 + f]; if (l < 0) continue; for (let fl = 0; fl < 3; fl++) if (sel[fl]) sl.push(fl * N * 3 + l); }
    for (let u = 0; u < rel; u++) { const x = sl[u % sl.length]; this.L[(x / (N * 3)) | 0][x % (N * 3)]++; }
  }
  flowLinks() {
    for (let i = 0; i < N; i++) {
      const si = SEL[this.pat[i]];
      for (let fl = 0; fl < 3; fl++) {
        const F = this.L[fl]; let mx = -1, mn = -1;
        for (let f = 0; f < 6; f++) {
          const l = LK[i * 6 + f]; if (l < 0) continue;
          if (si[fl] && SEL[this.pat[NB[i * 6 + f]]][fl]) continue; // held
          if (mx < 0 || F[l] > F[mx]) mx = l;
          if (mn < 0 || F[l] < F[mn]) mn = l;
        }
        if (mx >= 0 && F[mx] - F[mn] >= 2) { F[mx]--; F[mn]++; }
      }
    }
  }
  expressLinks() {
    const c = this.cs;
    for (let i = 0; i < N; i++) {
      const si = SEL[this.pat[i]];
      for (let fl = 0; fl < 3; fl++) {
        if (!si[fl]) continue;
        const F = this.L[fl]; let mx = -1, mn = -1;
        for (let f = 0; f < 6; f++) { const l = LK[i * 6 + f]; if (l < 0) continue;
          if (mx < 0 || F[l] > F[mx]) mx = l; if (mn < 0 || F[l] < F[mn]) mn = l; }
        if (F[mx] - F[mn] < 2) continue;
        F[mx]--;
        const b = i * 3; let k = 0; if (c[b + 1] < c[b + k]) k = 1; if (c[b + 2] < c[b + k]) k = 2;
        c[b + k]++;
      }
    }
  }
  tickLinks() {
    const kick = this.t === 0 ? this.kick : -1;
    this.fired.fill(0);
    let count = 0;
    if (this.cfg.update === "sync") {
      const go = new Uint8Array(N);
      for (let i = 0; i < N; i++) go[i] = ((this.readyL(i) || i === kick) && !this.blocked(i)) ? 1 : 0;
      for (let i = 0; i < N; i++) if (go[i]) { this.flashL(i); count++; }
    } else {
      for (let i = 0; i < N; i++) if ((this.readyL(i) || i === kick) && !this.blocked(i)) { this.flashL(i); count++; }
    }
    this.flowLinks(); this.expressLinks();
    this.t++; this.total += count;
    return count;
  }
  tickLattice() {
    if (this.cfg.links) return this.tickLinks();
    const kick = this.t === 0 ? this.kick : -1;
    this.fired.fill(0);
    let count = 0;
    if (this.cfg.update === "sync") {
      for (let i = 0; i < N; i++) this.fired[i] = ((this.ready(i) || i === kick) && !this.blocked(i)) ? 1 : 0;
      for (let i = 0; i < N; i++) if (this.fired[i]) { this.flash(i); count++; }
      for (let i = 0; i < N; i++) if (this.fired[i]) this.shout(i);
    } else {
      for (let i = 0; i < N; i++) {
        if (!(this.ready(i) || i === kick)) continue;
        if (this.blocked(i)) continue;
        this.flash(i); count++;
        this.shout(i);
      }
    }
    if (this.cfg.channels) {
      this.spread3(); this.absorb3();
      for (let i = 0; i < N; i++) this.carrier[i] = this.car3[i * 3] + this.car3[i * 3 + 1] + this.car3[i * 3 + 2];
    } else {
      this.spread();
      if (this.cfg.gravity) this.absorb(); else if (this.cfg.cancel) this.cancelMemory(); else if (this.cfg.excite) this.exciteMemory();
    }
    if (this.cfg.em) this.emField();
    if (this.cfg.motion) this.move();
    this.t++; this.total += count;
    return count;
  }
  // RULE 25: every pixel adds its charge (thirds) to phi at its site; phi spreads like rule 5.
  emField() {
    const ph = this.phi, nx = this.phin;
    for (let i = 0; i < N; i++) ph[i] += Q3[POPC[this.pat[i]]];
    nx.fill(0);
    for (let i = 0; i < N; i++) {
      const q = ph[i]; if (q === 0) continue;
      const sh = q / 6, x = i % S, y = ((i / S) | 0) % S, z = (i / (S * S)) | 0;
      if (x + 1 < S) nx[i + 1] += sh;
      if (x > 0) nx[i - 1] += sh;
      if (y + 1 < S) nx[i + S] += sh;
      if (y > 0) nx[i - S] += sh;
      if (z + 1 < S) nx[i + S * S] += sh;
      if (z > 0) nx[i - S * S] += sh;
    }
    this.phi = nx; this.phin = ph;
  }
  // RULE 24: a pixel that flashed hops toward the neighbour with the most carrier (if more than
  // its own site), swapping whole state with a pixel that didn't flash. Carrier stays.
  move() {
    const c = this.carrier, f = this.fired, m = this.moved; m.fill(0); this.swaps = 0;
    const sw = (a, x, y) => { const t = a[x]; a[x] = a[y]; a[y] = t; };
    for (let i = 0; i < N; i++) {
      if (!f[i] || m[i]) continue;
      let best = i;
      const qc = Q3[POPC[this.pat[i]]];
      if (this.cfg.em && qc !== 0) { // RULE 25: toward the lowest q*phi
        const ph = this.phi; let bv = qc * ph[i];
        for (let q = 0; q < 6; q++) { const j = NB[i * 6 + q]; if (qc * ph[j] < bv) { best = j; bv = qc * ph[j]; } }
      } else {
        let bc = c[i];
        for (let q = 0; q < 6; q++) { const j = NB[i * 6 + q]; if (c[j] > bc) { best = j; bc = c[j]; } }
      }
      if (best === i || f[best] || m[best]) continue;
      sw(this.pat, i, best); sw(this.home, i, best); sw(f, i, best);
      for (let k = 0; k < 3; k++) { sw(this.rf, i * 3 + k, best * 3 + k); sw(this.cs, i * 3 + k, best * 3 + k); }
      m[i] = m[best] = 1; this.swaps++;
    }
  }
  spread() {
    const c = this.carrier, nx = this.next; nx.fill(0);
    for (let i = 0; i < N; i++) {
      const q = c[i]; if (q === 0) continue;
      const sh = q / 6, x = i % S, y = ((i / S) | 0) % S, z = (i / (S * S)) | 0;
      if (x + 1 < S) nx[i + 1] += sh;
      if (x > 0) nx[i - 1] += sh;
      if (y + 1 < S) nx[i + S] += sh;
      if (y > 0) nx[i - S] += sh;
      if (z + 1 < S) nx[i + S * S] += sh;
      if (z > 0) nx[i - S * S] += sh;
    }
    this.carrier = nx; this.next = c;
  }
  // RULE 23: channel selection (0 weak, 1 EM, 2 strong) by charge.
  static select(p) { const c = (p & 1) + ((p >> 1) & 1) + ((p >> 2) & 1);
    return c === 0 ? [true, false, false] : c === 3 ? [true, true, false] : [true, true, true]; }
  spread3() {
    const c = this.car3, nx = this.nxt3; nx.fill(0);
    for (let i = 0; i < N; i++) for (let ch = 0; ch < 3; ch++) {
      const q = c[i * 3 + ch]; if (q === 0) continue;
      const sh = q / 6, x = i % S, y = ((i / S) | 0) % S, z = (i / (S * S)) | 0;
      if (x + 1 < S) nx[(i + 1) * 3 + ch] += sh;
      if (x > 0) nx[(i - 1) * 3 + ch] += sh;
      if (y + 1 < S) nx[(i + S) * 3 + ch] += sh;
      if (y > 0) nx[(i - S) * 3 + ch] += sh;
      if (z + 1 < S) nx[(i + S * S) * 3 + ch] += sh;
      if (z > 0) nx[(i - S * S) * 3 + ch] += sh;
    }
    this.car3 = nx; this.nxt3 = c;
  }
  absorb3() {
    const c = this.car3, rf = this.rf;
    for (let i = 0; i < N; i++) {
      const sl = Engine.select(this.pat[i]), p = this.pat[i], kind = (p & 1) + ((p >> 1) & 1) + ((p >> 2) & 1);
      for (let ch = 0; ch < 3; ch++) {
        const v = c[i * 3 + ch]; if (!sl[ch] || v < 3) continue;
        const k = Math.floor(v / 3); c[i * 3 + ch] = v - k * 3;
        rf[i * 3] += k; rf[i * 3 + 1] += k; rf[i * 3 + 2] += k; this.absorbed[kind * 3 + ch] += k;
      }
    }
  }
  // RULE 21: each whole pixel's worth of carrier (3 units) cancels one conserved unit
  // on each cell that holds one; one carrier unit used per memory unit cancelled.
  cancelMemory() {
    const c = this.carrier, cs = this.cs;
    for (let i = 0; i < N; i++) {
      if (c[i] < 3) continue;
      const k = Math.floor(c[i] / 3);
      for (let q = 0; q < 3; q++) { const m = Math.min(k, cs[i * 3 + q]); cs[i * 3 + q] -= m; c[i] -= m; }
    }
  }
  // RULE 26: each whole pixel's worth of carrier (3 units) adds +1 memory to every cell.
  exciteMemory() {
    const c = this.carrier, cs = this.cs;
    for (let i = 0; i < N; i++) {
      if (c[i] < 3) continue;
      const k = Math.floor(c[i] / 3); c[i] -= k * 3;
      cs[i * 3] += k; cs[i * 3 + 1] += k; cs[i * 3 + 2] += k;
    }
  }
  absorb() {
    const c = this.carrier;
    for (let i = 0; i < N; i++) {
      if (c[i] < 3) continue;
      const k = Math.floor(c[i] / 3);
      c[i] -= k * 3;
      this.rf[i * 3] += k; this.rf[i * 3 + 1] += k; this.rf[i * 3 + 2] += k;
    }
  }
  // ================= RULE 30: five-cell pixel (r, g, b, u, d) =================
  // Cells 0-2 = colour r, g, b; 3 = u; 4 = d. Charge (thirds) = 3u - (r+g+b). Colour charge = filled colour cells
  // (counted modulo r+g+b). RULE 31: flashes are conserving exchanges with a neighbour; colour flux on links obeys
  // a Gauss law; strings relax and pull. See RULES.md.
  static q5(p) { return 3 * ((p >> 3) & 1) - ((p & 1) + ((p >> 1) & 1) + ((p >> 2) & 1)); }
  static ncol(p) { return (p & 1) + ((p >> 1) & 1) + ((p >> 2) & 1); }
  initFive() {
    // fresh stream from the seed (independent of the 3-cell start), same generator as the constructor
    const M = (1n << 64n) - 1n; let s = BigInt(this.cfg.seed) ^ 0x5f5f5f5fn;
    this.p5 = new Uint8Array(N); this.cs5 = new Uint32Array(N * 5); this.rf5 = new Uint32Array(N * 5);
    for (let i = 0; i < N; i++) {
      s ^= (s << 13n) & M; s ^= s >> 7n; s ^= (s << 17n) & M;
      this.p5[i] = Number(s & 31n);
      for (let k = 0; k < 5; k++) this.cs5[i * 5 + k] = Number((s >> BigInt(8 + 2 * k)) % 2n);
    }
    if (this.cfg.neutral) { // RULE 33: colour-neutral vacuum; the core is quark-antiquark pairs along +x
      const inCore = i => this.cfg.core > 0 && RAD[i] <= this.cfg.core, done = new Uint8Array(N), lep = p => (p & 24) | (Engine.ncol(p) >= 2 ? 7 : 0);
      for (let i = 0; i < N; i++) { if (done[i]) continue; const x = i % S;
        if (inCore(i) && x + 1 < S && inCore(i + 1)) { const c = this.p5[i] % 3; this.p5[i] = (this.p5[i] & 24) | (1 << c); this.p5[i + 1] = (this.p5[i + 1] & 24) | (7 ^ (1 << c)); done[i] = done[i + 1] = 1; }
        else { this.p5[i] = lep(this.p5[i]); done[i] = 1; } }
      for (let i = 0; i < N; i++) if (inCore(i)) for (let k = 0; k < 5; k++) this.cs5[i * 5 + k] = 1;
    } else if (this.cfg.core > 0) for (let i = 0; i < N; i++) if (RAD[i] <= this.cfg.core) { this.p5[i] = 7; for (let k = 0; k < 5; k++) this.cs5[i * 5 + k] = 1; }
    this.taken = new Uint8Array(N); this.exchanges = 0; this.blocked5 = 0; this.relaxed = 0; this.broke = 0; this.lost = 0; this.exchDE = 0;
    // RULE 31 (b): colour flux on links (3 counts per link; link id = site*3 + axis, as rule 28) and out of the +x edge
    this.fx = new Int32Array(N * 9); this.edge = new Int32Array(N * 3);
    for (let z = 0; z < S; z++) for (let y = 0; y < S; y++) { let r = 0, g = 0, b = 0;
      for (let x = 0; x < S; x++) { const i = (z * S + y) * S + x, p = this.p5[i]; r += p & 1; g += (p >> 1) & 1; b += (p >> 2) & 1;
        const o = x + 1 < S ? (i * 3 + 0) * 3 : i * 3, arr = x + 1 < S ? this.fx : this.edge; arr[o] = r; arr[o + 1] = g; arr[o + 2] = b; } }
  }
  // flux energy of one link: |f|^2 - (sum f)^2 / 3, times 3 to stay in whole numbers
  static fE(a, b, c) { return 3 * (a * a + b * b + c * c) - (a + b + c) * (a + b + c); }
  // add colour vector v (3 ints) to the link between site i and its neighbour through face f, oriented so that
  // site i's out-flux grows by v
  exchCost5(i, f, v) { const l = LK[i * 6 + f], sg = (f & 1) ? -1 : 1, F = [this.fx[l * 3], this.fx[l * 3 + 1], this.fx[l * 3 + 2]]; return Engine.fE(F[0] + sg * v[0], F[1] + sg * v[1], F[2] + sg * v[2]) - Engine.fE(...F); }
  mem5(i) { let m = 0; for (let k = 0; k < 5; k++) m += this.cs5[i * 5 + k]; return m; }
  addFlux(i, f, v) { const l = LK[i * 6 + f], sg = (f & 1) ? -1 : 1; for (let c = 0; c < 3; c++) this.fx[l * 3 + c] += sg * v[c]; }
  surplus5(i, k) { return this.cs5[i * 5 + k] - this.rf5[i * 5 + k]; }
  // rule 1 one_cell over 5 cells (the only display rule built for five cells): the cell with the largest positive surplus
  pick5(i) { let best = -1, sur = 0; for (let k = 0; k < 5; k++) { const v = this.surplus5(i, k); if (v > sur) { sur = v; best = k; } } return best; }
  // the change a flash makes: returns [newPattern, partnerTest(p) -> partner's new pattern or -1, colourDelta] or null (can't)
  plan5(i) { const k = this.pick5(i); if (k < 0) return { np: this.p5[i], part: null, dv: null }; return this.planCell(i, k); }
  // RULE 31 (a): the change that changing cell k means for this pixel, or null if its kind can't make it
  planCell(i, k) {
    const p = this.p5[i];
    if (k < 3) {
      const filled = (p >> k) & 1; let j = -1, best = 0;
      for (let c = 0; c < 3; c++) { if (c === k || ((p >> c) & 1) !== (filled ^ 1)) continue; // the other colour cell must be in the opposite state
        const v = this.surplus5(i, c); if (j < 0 || (filled ? v > best : v < best)) { j = c; best = v; } }
      if (j < 0) return null;
      const np = p ^ (1 << k) ^ (1 << j), dv = [0, 0, 0]; dv[k] += filled ? -1 : 1; dv[j] += filled ? 1 : -1;
      return { np, dv, part: q => (((q >> k) & 1) === (filled ^ 1) && ((q >> j) & 1) === filled) ? (q ^ (1 << k) ^ (1 << j)) : -1 };
    }
    const u = (p >> 3) & 1, d = (p >> 4) & 1; if (u === d) return null;
    return { np: p ^ 24, dv: null, part: q => (((q >> 3) & 1) === d && ((q >> 4) & 1) === u) ? (q ^ 24) : -1 };
  }
  excluded5(i, np) { if (!this.cfg.exclusion) return false; for (let q = 0; q < 6; q++) if (this.p5[NB[i * 6 + q]] === np) return true; return false; }
  // rule 27 with five cells: the flash hands out its released memory, cell by cell, to mismatched neighbours
  shout5(i, rel) {
    const sh = this.p5[i];
    if (!this.cfg.conserve) { for (let q = 0; q < 6; q++) { const j = NB[i * 6 + q]; for (let k = 0; k < 5; k++) { if (((this.p5[j] >> k) & 1) === ((sh >> k) & 1)) this.rf5[j * 5 + k]++; else this.cs5[j * 5 + k]++; } } this.carrier[i] += rel.reduce((a, b) => a + b, 0); return; }
    const tg = [0, 0, 0, 0, 0, 0];
    for (let k = 0; k < 5; k++) { const bit = (sh >> k) & 1; let m = 0;
      for (let q = 0; q < 6; q++) { const j = NB[i * 6 + q]; if (((this.p5[j] >> k) & 1) === bit) this.rf5[j * 5 + k]++; else tg[m++] = j; }
      if (m === 0) { this.carrier[i] += rel[k]; continue; }
      for (let u = 0; u < rel[k]; u++) this.cs5[tg[u % m] * 5 + k]++; }
  }
  tickFive() {
    const kick = this.t === 0 ? this.kick : -1, colour = this.cfg.colour;
    this.fired.fill(0); this.taken.fill(0); this.exchanges = 0; this.blocked5 = 0; this.released5 = 0;
    const ready = []; for (let i = 0; i < N; i++) { let m = 0; for (let k = 0; k < 5; k++) m += this.cs5[i * 5 + k]; if (m >= 5 || i === kick) ready.push(i); }
    let count = 0; const shouts = [];
    for (const i of ready) {
      if (this.taken[i]) { this.blocked5++; continue; }
      const findPartner = pl => { for (let f = 0; f < 6; f++) { if (LK[i * 6 + f] < 0) continue; const j = NB[i * 6 + f]; if (this.taken[j]) continue; const r = pl.part(this.p5[j]); if (r >= 0) return [j, r, f]; } return null; };
      let pl = null, partner = -1, pnew = -1, face = -1;
      if (this.cfg.allowed) { // RULE 32: the first allowed change by surplus, else a flash without change
        const order = [0, 1, 2, 3, 4].filter(k => this.surplus5(i, k) > 0).sort((a, b) => this.surplus5(i, b) - this.surplus5(i, a) || a - b);
        for (const k of order) { const c = this.planCell(i, k); if (!c) continue; const fp = findPartner(c); if (!fp) continue; if (this.excluded5(i, c.np)) continue; if (colour && this.cfg.tension && c.dv && this.exchCost5(i, fp[2], c.dv) > this.mem5(i)) continue; pl = c; [partner, pnew, face] = fp; break; }
        if (!pl) { pl = { np: this.p5[i], part: null, dv: null }; this.released5++; }
      } else {
        pl = this.plan5(i); if (!pl) { this.blocked5++; continue; }
        if (pl.part) { const fp = findPartner(pl); if (!fp) { this.blocked5++; continue; } [partner, pnew, face] = fp; if (colour && this.cfg.tension && pl.dv && this.exchCost5(i, face, pl.dv) > this.mem5(i)) { this.blocked5++; continue; } }
        if (this.excluded5(i, pl.np)) { this.blocked5++; continue; }
      }
      // the flash: x changes, the partner takes the opposite change; colour flux moves with it (Gauss law)
      let owe = 0; this.p5[i] = pl.np; if (partner >= 0) { this.p5[partner] = pnew; this.taken[partner] = 1; this.exchanges++; if (colour && pl.dv) { const l = LK[i * 6 + face], fx = this.fx, e0 = Engine.fE(fx[l * 3], fx[l * 3 + 1], fx[l * 3 + 2]); this.addFlux(i, face, pl.dv); const de = Engine.fE(fx[l * 3], fx[l * 3 + 1], fx[l * 3 + 2]) - e0; if (this.cfg.tension) owe = de; else this.exchDE += de; } }
      this.taken[i] = 1; this.fired[i] = 1; count++;
      const rel = []; for (let k = 0; k < 5; k++) { rel.push(this.cs5[i * 5 + k]); this.cs5[i * 5 + k] = 0; this.rf5[i * 5 + k] = 0; }
      if (owe < 0) this.carrier[i] += -owe; while (owe > 0) { let k = 0; for (let q = 1; q < 5; q++) if (rel[q] > rel[k]) k = q; rel[k]--; owe--; } // RULE 35
      shouts.push([i, rel]);
    }
    for (const [i, rel] of shouts) this.shout5(i, rel);
    // carrier (rule 5) and its response, with 5 units per whole pixel and 5 cells
    { let b = 0; for (let i = 0; i < N; i++) b += this.carrier[i]; this.spread(); let a = 0; for (let i = 0; i < N; i++) a += this.carrier[i]; this.lost += b - a; }
    const c = this.carrier;
    if (this.cfg.gravity || this.cfg.cancel || this.cfg.excite) for (let i = 0; i < N; i++) { if (c[i] < 5) continue; const k = Math.floor(c[i] / 5);
      if (this.cfg.gravity) { c[i] -= k * 5; for (let q = 0; q < 5; q++) this.rf5[i * 5 + q] += k; }
      else if (this.cfg.cancel) { for (let q = 0; q < 5; q++) { const m = Math.min(k, this.cs5[i * 5 + q]); this.cs5[i * 5 + q] -= m; c[i] -= m; } }
      else { c[i] -= k * 5; for (let q = 0; q < 5; q++) this.cs5[i * 5 + q] += k; } }
    if (this.cfg.em) { const ph = this.phi, nx = this.phin; for (let i = 0; i < N; i++) ph[i] += Engine.q5(this.p5[i]); nx.fill(0);
      for (let i = 0; i < N; i++) { const q = ph[i]; if (q === 0) continue; const sh = q / 6, x = i % S, y = ((i / S) | 0) % S, z = (i / (S * S)) | 0;
        if (x + 1 < S) nx[i + 1] += sh; if (x > 0) nx[i - 1] += sh; if (y + 1 < S) nx[i + S] += sh; if (y > 0) nx[i - S] += sh; if (z + 1 < S) nx[i + S * S] += sh; if (z > 0) nx[i - S * S] += sh; }
      this.phi = nx; this.phin = ph; }
    if (colour) this.relax5();
    this.broke = 0; if (colour && this.cfg.tension) this.break5();
    if (this.cfg.motion) this.move5();
    this.t++; this.total += count;
    return count;
  }
  // RULE 31 (c): one pass of plaquette moves, each lowering the flux energy if it can
  relax5() {
    const fx = this.fx; let moves = 0;
    const opts = [[1, 0, 0], [-1, 0, 0], [0, 1, 0], [0, -1, 0], [0, 0, 1], [0, 0, -1]];
    for (let i = 0; i < N; i++) for (let mu = 0; mu < 3; mu++) for (let nu = mu + 1; nu < 3; nu++) {
      const a = LK[i * 6 + 2 * mu], d = LK[i * 6 + 2 * nu]; if (a < 0 || d < 0) continue;
      const iu = NB[i * 6 + 2 * mu], iv = NB[i * 6 + 2 * nu], b = LK[iu * 6 + 2 * nu], c2 = LK[iv * 6 + 2 * mu]; if (b < 0 || c2 < 0) continue;
      const L = [a, b, c2, d], sg = [1, 1, -1, -1];
      let E0 = 0; for (const l of L) E0 += Engine.fE(fx[l * 3], fx[l * 3 + 1], fx[l * 3 + 2]);
      let best = -1, bestE = E0;
      for (let o = 0; o < 6; o++) { let E = 0; for (let k = 0; k < 4; k++) { const l = L[k], v = opts[o]; E += Engine.fE(fx[l * 3] + sg[k] * v[0], fx[l * 3 + 1] + sg[k] * v[1], fx[l * 3 + 2] + sg[k] * v[2]); } if (E < bestE) { bestE = E; best = o; } }
      if (best >= 0) { for (let k = 0; k < 4; k++) { const l = L[k], v = opts[best]; for (let cc = 0; cc < 3; cc++) fx[l * 3 + cc] += sg[k] * v[cc]; } moves++; if (this.cfg.tension) this.carrier[i] += E0 - bestE; }
    }
    this.relaxed = moves;
  }
  // RULE 34 (c): a link between an all-colour pixel and a no-colour pixel may break the string by passing a colour cell
  break5() {
    const used = new Uint8Array(N), fx = this.fx;
    for (let i = 0; i < N; i++) for (let ax = 0; ax < 3; ax++) {
      const l = LK[i * 6 + 2 * ax]; if (l < 0) continue; const j = NB[i * 6 + 2 * ax]; if (used[i] || used[j]) continue;
      const ci = Engine.ncol(this.p5[i]), cj = Engine.ncol(this.p5[j]); if (!((ci === 3 && cj === 0) || (ci === 0 && cj === 3))) continue;
      const sgn = ci === 3 ? -1 : 1, F = [fx[l * 3], fx[l * 3 + 1], fx[l * 3 + 2]], e0 = Engine.fE(...F);
      let best = -1, be = e0;
      for (let c = 0; c < 3; c++) { const Fn = F.slice(); Fn[c] += sgn; const e = Engine.fE(...Fn); if (e < be) { be = e; best = c; } }
      if (best < 0) continue;
      fx[l * 3 + best] += sgn; this.p5[i] ^= 1 << best; this.p5[j] ^= 1 << best; this.carrier[i] += e0 - be;
      used[i] = used[j] = 1; this.broke++;
    }
  }
  // RULE 24 with five cells, RULE 31 (d): strings pull colour-charged pixels
  move5() {
    const f = this.fired, m = this.moved; m.fill(0); this.swaps = 0;
    const sw = (a, x, y) => { const t = a[x]; a[x] = a[y]; a[y] = t; };
    const col = p => [p & 1, (p >> 1) & 1, (p >> 2) & 1];
    for (let i = 0; i < N; i++) {
      if (!f[i] || m[i]) continue;
      let best = -1, bestFace = -1;
      const n3 = Engine.ncol(this.p5[i]);
      if (this.cfg.colour && n3 % 3 !== 0) { // colour-charged: the move that most lowers the flux energy of the link it moves along
        let bestD = 0; const ri = col(this.p5[i]);
        for (let q = 0; q < 6; q++) { const l = LK[i * 6 + q]; if (l < 0) continue; const j = NB[i * 6 + q]; if (f[j] || m[j]) continue;
          const rj = col(this.p5[j]), sg = (q & 1) ? -1 : 1, F = [this.fx[l * 3], this.fx[l * 3 + 1], this.fx[l * 3 + 2]];
          const Fn = F.map((v, cc) => v + sg * (rj[cc] - ri[cc])), d = Engine.fE(...Fn) - Engine.fE(...F);
          if (d < bestD) { bestD = d; best = j; bestFace = q; } }
      }
      if (best < 0) { // rule 24 / 25 targets, inside the box only (no move crosses the edge)
        const qc = Engine.q5(this.p5[i]);
        if (this.cfg.em && qc !== 0) { const ph = this.phi; let bv = qc * ph[i]; for (let q = 0; q < 6; q++) { if (LK[i * 6 + q] < 0) continue; const j = NB[i * 6 + q]; if (qc * ph[j] < bv) { best = j; bestFace = q; bv = qc * ph[j]; } } }
        else { const c = this.carrier; let bc = c[i]; for (let q = 0; q < 6; q++) { if (LK[i * 6 + q] < 0) continue; const j = NB[i * 6 + q]; if (c[j] > bc) { best = j; bestFace = q; bc = c[j]; } } }
      }
      if (best < 0 || f[best] || m[best]) continue;
      if (this.cfg.colour && this.cfg.tension) { // RULE 34 (a): a move pays for the string it stretches
        const l = LK[i * 6 + bestFace], ri = col(this.p5[i]), rj = col(this.p5[best]), sg = (bestFace & 1) ? -1 : 1;
        const F = [this.fx[l * 3], this.fx[l * 3 + 1], this.fx[l * 3 + 2]], d = Engine.fE(...F.map((v, cc) => v + sg * (rj[cc] - ri[cc]))) - Engine.fE(...F);
        if (d > 0) { let mem = 0; for (let k = 0; k < 5; k++) mem += this.cs5[i * 5 + k];
          if (mem + this.carrier[i] < d) continue;
          let owe = d; while (owe > 0 && mem > 0) { let k = 0; for (let q = 1; q < 5; q++) if (this.cs5[i * 5 + q] > this.cs5[i * 5 + k]) k = q; this.cs5[i * 5 + k]--; mem--; owe--; }
          this.carrier[i] -= owe; }
        else if (d < 0) this.carrier[best] += -d;
      }
      if (this.cfg.colour) { const ri = col(this.p5[i]), rj = col(this.p5[best]); this.addFlux(i, bestFace, [rj[0] - ri[0], rj[1] - ri[1], rj[2] - ri[2]]); }
      sw(this.p5, i, best); sw(this.home, i, best); sw(f, i, best);
      for (let k = 0; k < 5; k++) { sw(this.rf5, i * 5 + k, best * 5 + k); sw(this.cs5, i * 5 + k, best * 5 + k); }
      m[i] = m[best] = 1; this.swaps++;
    }
  }
  // measurements for rules 30-31
  stats5() {
    let Q = 0, R = 0, G = 0, B = 0, quarks = 0, leptons = 0, gauss = 0, fluxE = 0, strings = 0, qr = 0;
    for (let i = 0; i < N; i++) { const p = this.p5[i]; Q += Engine.q5(p); R += p & 1; G += (p >> 1) & 1; B += (p >> 2) & 1; if (Engine.ncol(p) % 3) { quarks++; qr += RAD[i]; } else leptons++; }
    if (this.cfg.colour) {
      for (let l = 0; l < N * 3; l++) { const e = Engine.fE(this.fx[l * 3], this.fx[l * 3 + 1], this.fx[l * 3 + 2]); fluxE += e; if (e) strings++; }
      for (let i = 0; i < N; i++) { const d = [0, 0, 0], p = this.p5[i];
        for (let q = 0; q < 6; q++) { const l = LK[i * 6 + q]; if (l < 0) continue; const sg = (q & 1) ? -1 : 1; for (let c = 0; c < 3; c++) d[c] += sg * this.fx[l * 3 + c]; }
        if (i % S === S - 1) for (let c = 0; c < 3; c++) d[c] += this.edge[i * 3 + c];
        const r = [d[0] - (p & 1), d[1] - ((p >> 1) & 1), d[2] - ((p >> 2) & 1)]; gauss = Math.max(gauss, Math.abs(r[0] - r[1]), Math.abs(r[1] - r[2])); }
    }
    return { charge3: Q, colour: [R - B, G - B], quarks, leptons, gauss, fluxE: fluxE / 3, strings, exchanges: this.exchanges, blocked: this.blocked5, relaxed: this.relaxed, swaps: this.swaps, released: this.released5 || 0, quarkR: quarks ? qr / quarks : 0, broke: this.broke || 0, lost: this.lost || 0, exchDE: this.exchDE || 0 };
  }
  agreement(i) {
    if (this.cfg.five) { let m = 0; const p = this.p5[i]; for (let q = 0; q < 6; q++) { const x = p ^ this.p5[NB[i * 6 + q]]; let d = 0; for (let k = 0; k < 5; k++) d += (x >> k) & 1; m += 5 - d; } return m / 30; }
    let m = 0; const p = this.pat[i];
    for (let q = 0; q < 6; q++) { const x = p ^ this.pat[NB[i * 6 + q]]; m += 3 - ((x & 1) + ((x >> 1) & 1) + ((x >> 2) & 1)); }
    return m / 18;
  }
}
if (typeof module !== "undefined") module.exports = { Engine, S, N, H, RAD };
