// JS twin of `origin five`: same arguments, same per-tick line. node run5.js [ticks] [key=on|off|number ...]
const path = require("path"), { Engine } = require(path.join(__dirname, "../../viewer/engine.js"));
const cfg = { mode: "lattice", display: "one_cell", update: "sync", five: true, colour: true, conserve: true, excite: true, core: 0, seed: 20261110n };
let ticks = 40;
for (const a of process.argv.slice(2)) { const eq = a.indexOf("="); if (eq < 0) { ticks = +a; continue; } const k = a.slice(0, eq), v = a.slice(eq + 1);
  if (k === "core") cfg.core = +v; else if (k === "seed") cfg.seed = BigInt(v); else cfg[k] = v === "on"; }
const e = new Engine(cfg);
console.log("tick\tflashes\texchanges\tblocked\treleased\tquark_r\trelaxed\tswaps\tcharge3\tcolour_rb\tcolour_gb\tquarks\tgauss\tflux_e3\tstrings\tcarrier\tmemory");
for (let t = 0; t < ticks; t++) { const f = e.tick(), s = e.stats5(); let car = 0, mem = 0; for (let i = 0; i < e.carrier.length; i++) car += e.carrier[i]; for (const v of e.cs5) mem += v;
  console.log([t, f, s.exchanges, s.blocked, s.released, s.quarkR.toFixed(4), s.relaxed, e.cfg.motion ? s.swaps : 0, s.charge3, s.colour[0], s.colour[1], s.quarks, s.gauss, Math.round(s.fluxE * 3), s.strings, car.toFixed(6), mem].join("\t")); }
