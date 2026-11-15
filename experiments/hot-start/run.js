// Hot start: does a world under rules 28 (+29) run down if the force fields start excited?
// node run.js T higgs(on|off) seed ticks [display update]
// Starting condition only (no rule): each of weak, EM, strong on every link starts at a random
// whole number 0..2T (mean T), the same for every generation. Its own xorshift stream, seeded
// from the run seed, so the engine's own start (patterns, memory, generations) is unchanged.
// "Runs down" = flashing goes to 0 while energy (conserved) stays: the energy is there but
// no longer uneven enough (a link difference of 2) to be expressed.
const { Field } = require("../../origin/viewer/pixel-model.js");
const [T, hg, seed, ticks, display = "one_cell", update = "sync"] = process.argv.slice(2);
const f = new Field({ display, update, core: 8, links: true, higgs: hg === "on", seed: BigInt(seed) });
let r = (Number(seed) * 2654435761 + 12345) >>> 0 || 1;
const rnd = () => { r ^= r << 13; r >>>= 0; r ^= r >>> 17; r ^= r << 5; r >>>= 0; return r; };
for (let l = 0; l < f.N * 3; l++) {
  const i = (l / 3) | 0, a = l % 3, S = f.S, c = a === 0 ? i % S : a === 1 ? ((i / S) | 0) % S : (i / (S * S)) | 0;
  if (c + 1 >= S) continue;
  for (let fl = 0; fl < 3; fl++) f.L[fl][l] = rnd() % (2 * +T + 1);
}
const out = [];
for (let t = 1; t <= +ticks; t++) {
  const c = f.tick();
  if (!(t <= 5 || t % 100 === 0)) continue;
  let mem = 0, fld = 0, uneven = 0;
  for (const p of f.px) mem += p.memory;
  for (let fl = 0; fl < 3; fl++) for (let l = 0; l < f.N * 3; l++) fld += f.L[fl][l];
  // pixels that could express now: some selected field with a link difference >= 2
  for (let i = 0; i < f.N; i++) { const sel = [1, f.px[i].filled !== 0, f.px[i].filled === 1 || f.px[i].filled === 2];
    for (let fl = 0; fl < 3; fl++) { if (!sel[fl]) continue; let mx = -1e9, mn = 1e9;
      for (let q = 0; q < 6; q++) { const l = f.lk[i * 6 + q]; if (l < 0) continue; const v = f.L[fl][l]; if (v > mx) mx = v; if (v < mn) mn = v; }
      if (mx - mn >= 2) { uneven++; break; } } }
  out.push([T, hg, seed, t, (c / f.N).toFixed(5), (mem / f.N).toFixed(3), (fld / f.N).toFixed(3), ((mem + fld) / f.N).toFixed(4), (uneven / f.N).toFixed(4)].join("\t"));
}
console.log(out.join("\n"));
