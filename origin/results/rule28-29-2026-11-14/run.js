// Rules 28 (fields on links) and 29 (Higgs-like mass), on the one-pixel field.
// node run.js display update higgs(on|off) seed ticks
// Columns: flashing; expressed memory per pixel; field units on links (weak, EM, strong);
// share of field held (both ends select it); flashes by kind (before flashing) and generation.
const { Field, Pixel } = require("../../viewer/pixel-model.js");
const [display, update, hg, seed, ticks] = process.argv.slice(2);
const f = new Field({ display, update, core: 8, links: true, higgs: hg === "on", seed: BigInt(seed) });
const byKG = Array.from({ length: 4 }, () => [0, 0, 0]);
const out = [];
const before = new Uint8Array(f.N);
for (let t = 1; t <= +ticks; t++) {
  for (let i = 0; i < f.N; i++) before[i] = f.px[i].filled;   // kind before this tick's flash
  const c = f.tick();
  for (let i = 0; i < f.N; i++) if (f.px[i].fired) byKG[before[i]][f.px[i].gen]++;
  if (!(t <= 10 || t % 50 === 0)) continue;
  let mem = 0; for (const p of f.px) mem += p.memory;
  const tot = [0, 0, 0], held = [0, 0, 0];
  for (let i = 0; i < f.N; i++) for (let k = 0; k < 6; k += 2) {
    const l = f.lk[i * 6 + k]; if (l < 0) continue; const j = f.nb[i * 6 + k];
    const a = Pixel.select(f.px[i].pattern), b = Pixel.select(f.px[j].pattern);
    for (let fl = 0; fl < 3; fl++) { tot[fl] += f.L[fl][l]; if (a[fl] && b[fl]) held[fl] += f.L[fl][l]; }
  }
  const T = tot[0] + tot[1] + tot[2], Hd = held[0] + held[1] + held[2];
  out.push([display, update, hg, seed, t, (c / f.N).toFixed(5), (mem / f.N).toFixed(4), ...tot, T ? (Hd / T).toFixed(3) : "", (mem + T) / f.N].join("\t"));
}
console.log(out.join("\n"));
console.error([display, update, hg, seed, "flashes kind x gen", JSON.stringify(byKG)].join("\t"));
