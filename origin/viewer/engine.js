// JS port of origin/src/engine/grid3.zig + pixel.zig (3D lattice, carrier, rule 6 gravity).
const S = 48, N = S * S * S, H = 24;
const DISPLAYS = ["fill_empty", "hold", "one_cell", "flip_all"];

function radius(i) {
  const x = i % S, y = ((i / S) | 0) % S, z = (i / (S * S)) | 0;
  return Math.sqrt((x - H) ** 2 + (y - H) ** 2 + (z - H) ** 2);
}
const NB = new Int32Array(N * 6);
const RAD = new Float64Array(N);
for (let i = 0; i < N; i++) {
  const x = i % S, y = ((i / S) | 0) % S, z = (i / (S * S)) | 0;
  const idx = (a, b, c) => (c * S + b) * S + a;
  NB.set([idx((x + 1) % S, y, z), idx((x + S - 1) % S, y, z), idx(x, (y + 1) % S, z),
          idx(x, (y + S - 1) % S, z), idx(x, y, (z + 1) % S), idx(x, y, (z + S - 1) % S)], i * 6);
  RAD[i] = radius(i);
}

class Engine {
  constructor(cfg) {
    this.cfg = Object.assign({ mode: "lattice", display: "one_cell", update: "sync", core: 8, gravity: false, seed: 20261110n }, cfg);
    this.pat = new Uint8Array(N);
    this.rf = new Uint32Array(N * 3);
    this.cs = new Uint32Array(N * 3);
    this.fired = new Uint8Array(N);
    this.carrier = new Float64Array(N);
    this.next = new Float64Array(N);
    this.car6 = new Float64Array(N * 6); this.nxt6 = new Float64Array(N * 6);
    this.t = 0; this.total = 0;
    const M = (1n << 64n) - 1n;
    let s = BigInt(this.cfg.seed);
    for (let i = 0; i < N; i++) {
      s ^= (s << 13n) & M; s ^= s >> 7n; s ^= (s << 17n) & M;
      this.pat[i] = Number(s & 7n);
      for (let k = 0; k < 3; k++) this.cs[i * 3 + k] = Number((s >> BigInt(8 + 2 * k)) % 2n);
    }
    if (this.cfg.core > 0) for (let i = 0; i < N; i++) if (RAD[i] <= this.cfg.core) {
      this.pat[i] = 7; this.cs[i * 3] = this.cs[i * 3 + 1] = this.cs[i * 3 + 2] = 1;
    }
    this.kick = (H * S + H) * S + H;
  }
  ready(i) { return this.cs[i * 3] + this.cs[i * 3 + 1] + this.cs[i * 3 + 2] >= 3; }
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
    r[b] = r[b + 1] = r[b + 2] = c[b] = c[b + 1] = c[b + 2] = 0;
    this.carrier[i] += rel;
    this.fired[i] = 1;
  }
  receive(j, shown) {
    const p = this.pat[j], b = j * 3;
    for (let k = 0; k < 3; k++) { if (((p >> k) & 1) === ((shown >> k) & 1)) this.rf[b + k]++; else this.cs[b + k]++; }
  }
  tick() {
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
  tickLattice() {
    const kick = this.t === 0 ? this.kick : -1;
    this.fired.fill(0);
    let count = 0;
    if (this.cfg.update === "sync") {
      for (let i = 0; i < N; i++) this.fired[i] = (this.ready(i) || i === kick) ? 1 : 0;
      for (let i = 0; i < N; i++) if (this.fired[i]) { this.flash(i); count++; }
      for (let i = 0; i < N; i++) if (this.fired[i]) { const sh = this.pat[i]; for (let q = 0; q < 6; q++) this.receive(NB[i * 6 + q], sh); }
    } else {
      for (let i = 0; i < N; i++) {
        if (!(this.ready(i) || i === kick)) continue;
        this.flash(i); count++;
        const sh = this.pat[i]; for (let q = 0; q < 6; q++) this.receive(NB[i * 6 + q], sh);
      }
    }
    this.spread();
    if (this.cfg.gravity) this.absorb();
    this.t++; this.total += count;
    return count;
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
  absorb() {
    const c = this.carrier;
    for (let i = 0; i < N; i++) {
      if (c[i] < 3) continue;
      const k = Math.floor(c[i] / 3);
      c[i] -= k * 3;
      this.rf[i * 3] += k; this.rf[i * 3 + 1] += k; this.rf[i * 3 + 2] += k;
    }
  }
  agreement(i) {
    let m = 0; const p = this.pat[i];
    for (let q = 0; q < 6; q++) { const x = p ^ this.pat[NB[i * 6 + q]]; m += 3 - ((x & 1) + ((x >> 1) & 1) + ((x >> 2) & 1)); }
    return m / 18;
  }
}
if (typeof module !== "undefined") module.exports = { Engine, S, N, H, RAD };
