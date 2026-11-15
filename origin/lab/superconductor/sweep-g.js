// Where is the self-trapping cliff? One run: node sweep-g.js g seed [ne T steps lattice]
// Prints: g, seed, mean lambda (all electrons), share of electrons self-trapped (lambda > 1),
// mobility (net distance travelled per unit time / vF; 1 = straight line, ~0 = stuck), deepest squeeze.
const { Lab2D } = require("./sim.js");
const [g, seed, ne = 10, T = 0.0005, steps = 60000, lattice = "square"] = process.argv.slice(2);
const L = new Lab2D({ g: +g, seed: +seed, ne: +ne, T: +T, lattice });
const tx = new Float64Array(+ne), ty = new Float64Array(+ne);
let lam = 0, trapped = 0, n = 0, burn = 10000;
for (let s = 0; s < +steps; s++) {
  const px = [...L.ex], py = [...L.ey];
  L.step();
  if (s < burn) continue;
  for (let e = 0; e < +ne; e++) { tx[e] += L.wrapD(L.ex[e] - px[e], L.Lx); ty[e] += L.wrapD(L.ey[e] - py[e], L.Ly); }
  if (s % 500 === 0) { const l = L.coupling(); for (const v of l) { lam += v; if (v > 1) trapped++; n++; } }
}
const time = (+steps - burn) * L.p.dt;
let mob = 0; for (let e = 0; e < +ne; e++) mob += Math.hypot(tx[e], ty[e]) / (time * L.p.vF); mob /= +ne;
let sq = 0; for (const v of L.compression()) sq = Math.max(sq, v);
console.log([lattice, g, seed, ne, T, (lam / n).toFixed(4), (trapped / n).toFixed(3), mob.toFixed(4), sq.toFixed(3)].join("\t"));
