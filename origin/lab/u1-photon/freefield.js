// Control: the static potential of a FREE photon (non-compact U(1), weak coupling) on the same periodic L^3 box.
// a V(R) = (1/beta) [G(0) - G(R)],  G(R) = (1/L^3) sum_{k != 0} cos(k_x R) / (4 sum_i sin^2(k_i/2))
// Fitted the same way as the Monte Carlo, it shows how much "string tension" the finite box alone fakes.
const L = +(process.argv[2] ?? 10), beta = +(process.argv[3] ?? 1);
const G = R => { let s = 0; for (let a = 0; a < L; a++) for (let b = 0; b < L; b++) for (let c = 0; c < L; c++) { if (!a && !b && !c) continue;
  const k = [a, b, c].map(n => 2 * Math.PI * n / L), den = 4 * k.reduce((t, q) => t + Math.sin(q / 2) ** 2, 0); s += Math.cos(k[0] * R) / den; } return s / L ** 3; };
const V = []; for (let R = 1; R <= L / 2; R++) V.push((G(0) - G(R)) / beta);
const rows = V.map((v, k) => [k + 1, v]); const n = 3, M = [[0,0,0],[0,0,0],[0,0,0]], y = [0,0,0];
for (const [R, v] of rows) { const b = [1, R, -1 / R]; for (let i = 0; i < n; i++) { y[i] += b[i] * v; for (let j = 0; j < n; j++) M[i][j] += b[i] * b[j]; } }
for (let c = 0; c < n; c++) for (let r = 0; r < n; r++) if (r !== c) { const f = M[r][c] / M[c][c]; for (let k = 0; k < n; k++) M[r][k] -= f * M[c][k]; y[r] -= f * y[c]; }
const [V0, sigma, e] = y.map((v, i) => v / M[i][i]);
console.log(`free photon, L ${L}, beta ${beta}: V(R) = ${V.map(v => v.toFixed(4)).join(" ")}`);
console.log(`Cornell fit R >= 1: sigma a^2 = ${sigma.toFixed(4)}, e = ${e.toFixed(4)} (infinite-volume value 1/(4 pi beta) = ${(1 / (4 * Math.PI * beta)).toFixed(4)})`);
