// ORIGIN: one pixel as an active model, and a 3D field made of copies of it.
//
// A Pixel owns all of its own state and runs every rule itself. It only talks to the
// outside through its 6 faces (+x, -x, +y, -y, +z, -z): it hears the patterns neighbours
// flash, sends and receives carrier, and can trade places with a neighbour.
// Field is nothing but S^3 Pixels wired face to face. It runs no physics of its own;
// it only decides the order pixels act in and passes messages between faces.
// Field must give exactly the same results as engine.js (the reference) for the same seed.
//
// Rules carried by the Pixel: 1-3 (display, trigger, no memory), 5 (carrier), 6 (gravity),
// 21 (cancel), 22 (exclusion), 23 (three carriers), 24 (motion), 25 (signed EM).
(function (root) {
  const POPC = [0, 1, 1, 2, 1, 2, 2, 3];
  const CHARGE3 = [0, -1, 2, -3];           // thirds: neutrino, down, up, electron
  const KIND = ["neutrino", "down", "up", "electron"];
  const FACES = ["+x", "-x", "+y", "-y", "+z", "-z"];
  const OPP = [1, 0, 3, 2, 5, 4];

  class Pixel {
    constructor(pattern = 0, memory = [0, 0, 0]) {
      this.pattern = pattern & 7;
      this.rf = [0, 0, 0];                   // reinforcement per cell
      this.cs = memory.slice();              // conserved share (memory) per cell
      this.carrier = 0;                      // rule 5 carrier held here
      this.car3 = [0, 0, 0];                 // rule 23: weak, EM, strong
      this.phi = 0;                          // rule 25: signed EM field held here
      this.fired = false;
      this.home = -1;                        // measurement only: where this pixel started
      this.flashes = 0;
    }
    // --- what the pixel is (read from its own pattern) ---
    get filled() { return POPC[this.pattern]; }
    get kind() { return KIND[this.filled]; }
    get charge3() { return CHARGE3[this.filled]; }
    // Colour (not a rule yet, a reading): position of the odd cell in a quark.
    get colour() {
      const f = this.filled; if (f !== 1 && f !== 2) return -1;
      for (let k = 0; k < 3; k++) if (((this.pattern >> k) & 1) === (f === 1 ? 1 : 0)) return k;
      return -1;
    }
    get memory() { return this.cs[0] + this.cs[1] + this.cs[2]; }

    // --- rule 2: trigger ---
    ready() { return this.memory >= 3; }

    // --- rule 1: what it would show if it flashed now ---
    wouldShow(display) {
      const r = this.rf, c = this.cs; let p = this.pattern;
      if (display === "fill_empty") {
        for (let k = 0; k < 3; k++) { if (r[k] > c[k]) p |= 1 << k; else if (r[k] < c[k]) p &= ~(1 << k); }
      } else if (display === "one_cell") {
        let best = -1, sur = 0;
        for (let k = 0; k < 3; k++) if (c[k] > r[k] && c[k] - r[k] > sur) { sur = c[k] - r[k]; best = k; }
        if (best >= 0) p ^= 1 << best;
      } else if (display === "flip_all") {
        for (let k = 0; k < 3; k++) if (c[k] > r[k]) p ^= 1 << k;
      }
      return p & 7;
    }
    // --- rule 22: blocked if any neighbour already shows what it would show ---
    blocked(display, neighbourPatterns) {
      const nx = this.wouldShow(display);
      for (const q of neighbourPatterns) if (q === nx) return true;
      return false;
    }
    // --- rules 1-3 (+23 split): flash. Returns what it shows; carrier goes into itself ---
    flash(display, channels) {
      this.pattern = this.wouldShow(display);
      const rel = this.memory;
      this.rf = [0, 0, 0]; this.cs = [0, 0, 0];
      if (channels) {
        const sl = Pixel.select(this.pattern); let k = 0; for (const on of sl) k += on ? 1 : 0;
        const share = rel / k;
        for (let ch = 0; ch < 3; ch++) if (sl[ch]) this.car3[ch] += share;
      } else this.carrier += rel;
      this.fired = true; this.flashes++;
      return this.pattern;
    }
    // --- hearing a neighbour's flash: matching cells reinforce, others go to memory ---
    hear(shown) {
      for (let k = 0; k < 3; k++) { if (((this.pattern >> k) & 1) === ((shown >> k) & 1)) this.rf[k]++; else this.cs[k]++; }
    }
    // --- rule 6: whole pixels of carrier reinforce every cell ---
    absorb() {
      if (this.carrier < 3) return;
      const k = Math.floor(this.carrier / 3); this.carrier -= k * 3;
      this.rf[0] += k; this.rf[1] += k; this.rf[2] += k;
    }
    // --- rule 21: whole pixels of carrier cancel memory one for one ---
    cancel() {
      const k = Math.floor(this.carrier / 3);
      for (let q = 0; q < 3; q++) { const m = Math.min(k, this.cs[q]); this.cs[q] -= m; this.carrier -= m; }
    }
    // --- rule 23: which channels this pixel takes part in, and absorbing them ---
    static select(p) { const c = POPC[p]; return c === 0 ? [true, false, false] : c === 3 ? [true, true, false] : [true, true, true]; }
    absorb3() {
      const sl = Pixel.select(this.pattern);
      for (let ch = 0; ch < 3; ch++) {
        const v = this.car3[ch]; if (!sl[ch] || v < 3) continue;
        const k = Math.floor(v / 3); this.car3[ch] = v - k * 3;
        this.rf[0] += k; this.rf[1] += k; this.rf[2] += k;
      }
    }
    // --- rule 25: add own charge to the field held here ---
    emitCharge() { this.phi += this.charge3; }
    // --- rules 24/25: which face it wants to move through (-1 = stay) ---
    wantMove(em, nb) { // nb[f] = { carrier, phi } at the neighbour through face f
      let best = -1;
      const q = this.charge3;
      if (em && q !== 0) {
        let bv = q * this.phi;
        for (let f = 0; f < 6; f++) if (q * nb[f].phi < bv) { best = f; bv = q * nb[f].phi; }
      } else {
        let bc = this.carrier;
        for (let f = 0; f < 6; f++) if (nb[f].carrier > bc) { best = f; bc = nb[f].carrier; }
      }
      return best;
    }
    // The pixel's own state (what travels when it moves). Fields held at a site stay put.
    takeBody() { return { pattern: this.pattern, rf: this.rf, cs: this.cs, fired: this.fired, home: this.home, flashes: this.flashes }; }
    putBody(b) { this.pattern = b.pattern; this.rf = b.rf; this.cs = b.cs; this.fired = b.fired; this.home = b.home; this.flashes = b.flashes; }
  }

  class Field {
    constructor(cfg, S = 48) {
      this.cfg = Object.assign({ display: "one_cell", update: "sync", core: 8, gravity: false, seed: 20261110n }, cfg);
      this.S = S; const N = this.N = S * S * S, H = this.H = S >> 1;
      this.px = new Array(N);
      this.nb = new Int32Array(N * 6); this.edge = new Uint8Array(N * 6); // edge = carrier lost there
      const idx = (a, b, c) => (c * S + b) * S + a;
      const M = (1n << 64n) - 1n; let s = BigInt(this.cfg.seed);
      for (let i = 0; i < N; i++) {
        const x = i % S, y = ((i / S) | 0) % S, z = (i / (S * S)) | 0;
        this.nb.set([idx((x + 1) % S, y, z), idx((x + S - 1) % S, y, z), idx(x, (y + 1) % S, z),
                     idx(x, (y + S - 1) % S, z), idx(x, y, (z + 1) % S), idx(x, y, (z + S - 1) % S)], i * 6);
        this.edge.set([x + 1 >= S, x === 0, y + 1 >= S, y === 0, z + 1 >= S, z === 0], i * 6);
        s ^= (s << 13n) & M; s ^= s >> 7n; s ^= (s << 17n) & M;
        const mem = [0, 1, 2].map(k => Number((s >> BigInt(8 + 2 * k)) % 2n));
        const p = new Pixel(Number(s & 7n), mem); p.home = i;
        const r = Math.sqrt((x - H) ** 2 + (y - H) ** 2 + (z - H) ** 2);
        if (this.cfg.core > 0 && r <= this.cfg.core) { p.pattern = 7; p.cs = [1, 1, 1]; }
        this.px[i] = p;
      }
      this.kick = (H * S + H) * S + H; this.t = 0; this.total = 0; this.swaps = 0;
    }
    neighbourPatterns(i) { const o = []; for (let f = 0; f < 6; f++) o.push(this.px[this.nb[i * 6 + f]].pattern); return o; }
    shout(i) { const sh = this.px[i].pattern; for (let f = 0; f < 6; f++) this.px[this.nb[i * 6 + f]].hear(sh); }
    // carrier passes face to face: each pixel sends 1/6 out of every face; edge faces lose it.
    passOn(get, set) {
      const N = this.N, inbox = new Float64Array(N);
      for (let i = 0; i < N; i++) {
        const q = get(this.px[i]); if (q === 0) continue; const sh = q / 6;
        for (let f = 0; f < 6; f++) if (!this.edge[i * 6 + f]) inbox[this.nb[i * 6 + f]] += sh;
      }
      for (let i = 0; i < N; i++) set(this.px[i], inbox[i]);
    }
    tick() {
      const c = this.cfg, N = this.N, px = this.px, kick = this.t === 0 ? this.kick : -1;
      let count = 0;
      for (const p of px) p.fired = false;
      const may = i => (px[i].ready() || i === kick) && !(c.exclusion && px[i].blocked(c.display, this.neighbourPatterns(i)));
      if (c.update === "sync") {
        const go = new Uint8Array(N); for (let i = 0; i < N; i++) go[i] = may(i) ? 1 : 0;
        for (let i = 0; i < N; i++) if (go[i]) { px[i].flash(c.display, c.channels); count++; }
        for (let i = 0; i < N; i++) if (go[i]) this.shout(i);
      } else {
        for (let i = 0; i < N; i++) if (may(i)) { px[i].flash(c.display, c.channels); count++; this.shout(i); }
      }
      if (c.channels) {
        for (let ch = 0; ch < 3; ch++) this.passOn(p => p.car3[ch], (p, v) => { p.car3[ch] = v; });
        for (const p of px) { p.absorb3(); p.carrier = p.car3[0] + p.car3[1] + p.car3[2]; }
      } else {
        this.passOn(p => p.carrier, (p, v) => { p.carrier = v; });
        if (c.gravity) for (const p of px) p.absorb(); else if (c.cancel) for (const p of px) p.cancel();
      }
      if (c.em) { for (const p of px) p.emitCharge(); this.passOn(p => p.phi, (p, v) => { p.phi = v; }); }
      if (c.motion) this.move();
      this.t++; this.total += count;
      return count;
    }
    move() {
      const N = this.N, px = this.px, moved = new Uint8Array(N); this.swaps = 0;
      for (let i = 0; i < N; i++) {
        const p = px[i]; if (!p.fired || moved[i]) continue;
        const nb = []; for (let f = 0; f < 6; f++) nb.push(px[this.nb[i * 6 + f]]);
        const f = p.wantMove(this.cfg.em, nb); if (f < 0) continue;
        const j = this.nb[i * 6 + f], q = px[j]; if (q.fired || moved[j]) continue;
        const a = p.takeBody(); p.putBody(q.takeBody()); q.putBody(a);
        moved[i] = moved[j] = 1; this.swaps++;
      }
    }
  }
  const api = { Pixel, Field, FACES, OPP, KIND, CHARGE3, POPC };
  if (typeof module !== "undefined") module.exports = api; else root.OriginPixel = api;
})(this);
