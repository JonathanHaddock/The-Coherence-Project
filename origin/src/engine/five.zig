//! RULES 30-31: the five-cell pixel on the 3D lattice (see RULES.md).
//!   Cells 0-2 = colour r, g, b; 3 = u; 4 = d (SU(5)/SO(10) as bits, Baez & Huerta 0904.1556).
//!   Charge (thirds) = 3u - (r+g+b). Colour charge = filled colour cells, modulo r+g+b.
//!   Rule 31: a flash is an exchange with a neighbour (recolour, or u <-> d), so charge and colour are conserved;
//!   colour flux lives on links and obeys a Gauss law; strings relax (plaquette moves) and pull (motion).
//! Same box, neighbours, links, carrier spreading and EM field as grid3.zig. The JS port is the five-cell part of
//! viewer/engine.js and must give identical totals for the same seed (results/rule30-31-2026-11-18/compare).

const std = @import("std");
const g3 = @import("grid3.zig");
pub const n = g3.n;
const side = g3.side;

pub const Cfg = struct {
    seed: u64 = 20261110,
    core: u32 = 0,
    colour: bool = true,
    conserve: bool = true,
    excite: bool = true,
    gravity: bool = false,
    cancel: bool = false,
    exclusion: bool = false,
    motion: bool = false,
    em: bool = false,
    allowed: bool = false, // RULE 32
    neutral: bool = false, // RULE 33
    tension: bool = false, // RULE 34
    drive: f64 = 0, // RULE 36: memory units added per tick from outside
};

pub fn q5(p: u8) i32 {
    return 3 * @as(i32, (p >> 3) & 1) - @as(i32, @popCount(p & 7));
}
pub fn ncol(p: u8) u32 {
    return @popCount(p & 7);
}
fn col(p: u8) [3]i32 {
    return .{ p & 1, (p >> 1) & 1, (p >> 2) & 1 };
}
/// Flux energy of a link, times 3: 3|f|^2 - (sum f)^2 (zero for colour-neutral flux).
pub fn fE(a: i32, b: i32, c: i32) i64 {
    const A: i64 = a;
    const B: i64 = b;
    const C: i64 = c;
    return 3 * (A * A + B * B + C * C) - (A + B + C) * (A + B + C);
}

pub const Stats = struct { flashes: u32, exchanges: u32, blocked: u32, released: u32, quark_r: f64, relaxed: u32, swaps: u32, charge3: i64, colour: [2]i64, quarks: u32, gauss: i64, flux_e3: i64, strings: u32, carrier: f64, memory: u64, broke: u32, lost: f64, exch_de: i64 };

const Plan = struct { np: u8, has_part: bool, k: u3 = 0, j: u3 = 0, filled: u1 = 0, weak: bool = false, u: u1 = 0, d: u1 = 0, dv: [3]i32 = .{ 0, 0, 0 } };

pub const Five = struct {
    cfg: Cfg,
    p5: [n]u8,
    cs5: [n][5]u32,
    rf5: [n][5]u32,
    fired: [n]bool,
    taken: [n]bool,
    moved: [n]bool,
    carrier: [n]f64,
    next: [n]f64,
    phi: [n]f64,
    phin: [n]f64,
    fx: [n * 3][3]i32,
    edge: [n][3]i32,
    t: i64,
    exchanges: u32,
    blocked: u32,
    released: u32,
    relaxed: u32,
    swaps: u32,
    broke: u32,
    lost: f64,
    exch_de: i64,
    drive_acc: f64,
    drive_s: u64,
    drive_cell: u8,
    driven: u64,

    pub fn init(g: *Five, cfg: Cfg) void {
        g.cfg = cfg;
        g.t = 0;
        g.carrier = @splat(0);
        g.phi = @splat(0);
        g.fired = @splat(false);
        g.moved = @splat(false);
        g.rf5 = @splat(@splat(0));
        g.exchanges = 0;
        g.blocked = 0;
        g.released = 0;
        g.relaxed = 0;
        g.swaps = 0;
        g.broke = 0;
        g.lost = 0;
        g.exch_de = 0;
        g.drive_acc = 0;
        g.drive_s = cfg.seed ^ 0x9E3779B97F4A7C15;
        g.drive_cell = 0;
        g.driven = 0;
        var s: u64 = cfg.seed ^ 0x5f5f5f5f;
        for (0..n) |i| {
            s ^= s << 13;
            s ^= s >> 7;
            s ^= s << 17;
            g.p5[i] = @intCast(s & 31);
            for (0..5) |k| g.cs5[i][k] = @intCast((s >> @intCast(8 + 2 * k)) % 2);
        }
        const rc: f64 = @floatFromInt(cfg.core);
        if (cfg.neutral) {
            // RULE 33: colour-neutral vacuum; the core is quark-antiquark pairs along +x
            var done: [n]bool = @splat(false);
            for (0..n) |i| {
                if (done[i]) continue;
                const x = i % side;
                const in_i = cfg.core > 0 and g3.radius(i) <= rc;
                if (in_i and x + 1 < side and g3.radius(i + 1) <= rc) {
                    const c: u3 = @intCast(g.p5[i] % 3);
                    g.p5[i] = (g.p5[i] & 24) | (@as(u8, 1) << c);
                    g.p5[i + 1] = (g.p5[i + 1] & 24) | (7 ^ (@as(u8, 1) << c));
                    done[i] = true;
                    done[i + 1] = true;
                } else {
                    g.p5[i] = (g.p5[i] & 24) | (if (ncol(g.p5[i]) >= 2) @as(u8, 7) else 0);
                    done[i] = true;
                }
            }
            if (cfg.core > 0) for (0..n) |i| if (g3.radius(i) <= rc) {
                g.cs5[i] = .{ 1, 1, 1, 1, 1 };
            };
        } else if (cfg.core > 0) for (0..n) |i| if (g3.radius(i) <= rc) {
            g.p5[i] = 7;
            g.cs5[i] = .{ 1, 1, 1, 1, 1 };
        };
        g.fx = @splat(.{ 0, 0, 0 });
        g.edge = @splat(.{ 0, 0, 0 });
        for (0..side) |z| for (0..side) |y| {
            var run: [3]i32 = .{ 0, 0, 0 };
            for (0..side) |x| {
                const i = g3.index(x, y, z);
                const c = col(g.p5[i]);
                for (0..3) |k| run[k] += c[k];
                if (x + 1 < side) g.fx[i * 3] = run else g.edge[i] = run;
            }
        };
    }

    /// RULE 35: change in flux energy of the link an exchange runs along.
    fn exchCost(g: *const Five, i: usize, face: usize, dv: [3]i32) i64 {
        const l = g3.Grid3.linkOf(i, face).?;
        const sg: i32 = if (face & 1 == 1) -1 else 1;
        const F = g.fx[l];
        return fE(F[0] + sg * dv[0], F[1] + sg * dv[1], F[2] + sg * dv[2]) - fE(F[0], F[1], F[2]);
    }
    fn memOf(g: *const Five, i: usize) i64 {
        var m: i64 = 0;
        for (g.cs5[i]) |v| m += v;
        return m;
    }
    fn addFlux(g: *Five, i: usize, f: usize, v: [3]i32) void {
        const l = g3.Grid3.linkOf(i, f).?;
        const sg: i32 = if (f & 1 == 1) -1 else 1;
        for (0..3) |c| g.fx[l][c] += sg * v[c];
    }
    fn surplus(g: *const Five, i: usize, k: usize) i64 {
        return @as(i64, g.cs5[i][k]) - @as(i64, g.rf5[i][k]);
    }
    fn pick(g: *const Five, i: usize) ?u3 {
        var best: ?u3 = null;
        var sur: i64 = 0;
        for (0..5) |k| {
            const v = g.surplus(i, k);
            if (v > sur) {
                sur = v;
                best = @intCast(k);
            }
        }
        return best;
    }
    fn plan(g: *const Five, i: usize) ?Plan {
        const kk = g.pick(i) orelse return Plan{ .np = g.p5[i], .has_part = false };
        return g.planCell(i, kk);
    }
    /// RULE 31 (a): the change that changing cell kk means for this pixel, or null if its kind can't make it.
    fn planCell(g: *const Five, i: usize, kk: u3) ?Plan {
        const p = g.p5[i];
        if (kk < 3) {
            const filled: u1 = @intCast((p >> kk) & 1);
            var j: ?u3 = null;
            var best: i64 = 0;
            for (0..3) |c| {
                if (c == kk or ((p >> @intCast(c)) & 1) != (filled ^ 1)) continue;
                const v = g.surplus(i, c);
                if (j == null or (if (filled == 1) v > best else v < best)) {
                    j = @intCast(c);
                    best = v;
                }
            }
            const jj = j orelse return null;
            var dv: [3]i32 = .{ 0, 0, 0 };
            dv[kk] += if (filled == 1) -1 else 1;
            dv[jj] += if (filled == 1) 1 else -1;
            return Plan{ .np = p ^ (@as(u8, 1) << kk) ^ (@as(u8, 1) << jj), .has_part = true, .k = kk, .j = jj, .filled = filled, .dv = dv };
        }
        const u: u1 = @intCast((p >> 3) & 1);
        const d: u1 = @intCast((p >> 4) & 1);
        if (u == d) return null;
        return Plan{ .np = p ^ 24, .has_part = true, .weak = true, .u = u, .d = d };
    }
    fn partnerOf(pl: Plan, q: u8) ?u8 {
        if (pl.weak) return if (((q >> 3) & 1) == pl.d and ((q >> 4) & 1) == pl.u) q ^ 24 else null;
        return if (((q >> pl.k) & 1) == (pl.filled ^ 1) and ((q >> pl.j) & 1) == pl.filled) q ^ (@as(u8, 1) << pl.k) ^ (@as(u8, 1) << pl.j) else null;
    }
    fn findPartner(g: *const Five, i: usize, pl: Plan) ?struct { j: usize, r: u8, f: usize } {
        const nb = g3.neighbors(i);
        for (0..6) |f| {
            if (g3.Grid3.linkOf(i, f) == null) continue;
            const j = nb[f];
            if (g.taken[j]) continue;
            if (partnerOf(pl, g.p5[j])) |r| return .{ .j = j, .r = r, .f = f };
        }
        return null;
    }
    fn excluded(g: *const Five, i: usize, np: u8) bool {
        if (!g.cfg.exclusion) return false;
        for (g3.neighbors(i)) |j| if (g.p5[j] == np) return true;
        return false;
    }
    fn shout(g: *Five, i: usize, rel: [5]u32) void {
        const sh = g.p5[i];
        const nb = g3.neighbors(i);
        if (!g.cfg.conserve) {
            for (nb) |j| for (0..5) |k| {
                if (((g.p5[j] >> @intCast(k)) & 1) == ((sh >> @intCast(k)) & 1)) g.rf5[j][k] += 1 else g.cs5[j][k] += 1;
            };
            var tot: u32 = 0;
            for (rel) |v| tot += v;
            g.carrier[i] += @floatFromInt(tot);
            return;
        }
        for (0..5) |k| {
            const bit = (sh >> @intCast(k)) & 1;
            var tg: [6]usize = undefined;
            var m: usize = 0;
            for (nb) |j| {
                if (((g.p5[j] >> @intCast(k)) & 1) == bit) g.rf5[j][k] += 1 else {
                    tg[m] = j;
                    m += 1;
                }
            }
            if (m == 0) {
                g.carrier[i] += @floatFromInt(rel[k]);
                continue;
            }
            var u: usize = 0;
            while (u < rel[k]) : (u += 1) g.cs5[tg[u % m]][k] += 1;
        }
    }

    pub fn tick(g: *Five, alloc: std.mem.Allocator) !u32 {
        const kick: ?usize = if (g.t == 0) g3.index(side / 2, side / 2, side / 2) else null;
        g.fired = @splat(false);
        g.taken = @splat(false);
        g.exchanges = 0;
        g.blocked = 0;
        g.released = 0;
        // RULE 36: slow driving from outside, r units per tick, sites from a fixed sequence, cells in turn
        if (g.cfg.drive > 0) {
            g.drive_acc += g.cfg.drive;
            while (g.drive_acc >= 1) {
                g.drive_acc -= 1;
                g.drive_s ^= g.drive_s << 13;
                g.drive_s ^= g.drive_s >> 7;
                g.drive_s ^= g.drive_s << 17;
                const site: usize = @intCast(g.drive_s % n);
                g.cs5[site][g.drive_cell] += 1;
                g.drive_cell = (g.drive_cell + 1) % 5;
                g.driven += 1;
            }
        }
        var count: u32 = 0;
        var ready = std.ArrayList(usize).empty;
        defer ready.deinit(alloc);
        for (0..n) |i| {
            var m: u32 = 0;
            for (g.cs5[i]) |v| m += v;
            if (m >= 5 or kick == i) try ready.append(alloc, i);
        }
        var shouts = std.ArrayList(struct { i: usize, rel: [5]u32 }).empty;
        defer shouts.deinit(alloc);
        for (ready.items) |i| {
            if (g.taken[i]) {
                g.blocked += 1;
                continue;
            }
            var pl: Plan = undefined;
            var partner: ?usize = null;
            var pnew: u8 = 0;
            var face: usize = 0;
            if (g.cfg.allowed) {
                // RULE 32: the first allowed change by surplus (largest first, lowest index on ties), else no change
                var order: [5]u3 = undefined;
                var m: usize = 0;
                for (0..5) |k| if (g.surplus(i, k) > 0) {
                    order[m] = @intCast(k);
                    m += 1;
                };
                var a: usize = 1;
                while (a < m) : (a += 1) { // insertion sort, stable: surplus descending, index ascending
                    var b = a;
                    while (b > 0 and g.surplus(i, order[b - 1]) < g.surplus(i, order[b])) : (b -= 1) std.mem.swap(u3, &order[b - 1], &order[b]);
                }
                var found = false;
                for (order[0..m]) |k| {
                    const c = g.planCell(i, k) orelse continue;
                    const fp = g.findPartner(i, c) orelse continue;
                    if (g.excluded(i, c.np)) continue;
                    if (g.cfg.colour and g.cfg.tension and !c.weak and g.exchCost(i, fp.f, c.dv) > g.memOf(i)) continue; // RULE 35
                    pl = c;
                    partner = fp.j;
                    pnew = fp.r;
                    face = fp.f;
                    found = true;
                    break;
                }
                if (!found) {
                    pl = Plan{ .np = g.p5[i], .has_part = false };
                    g.released += 1;
                }
            } else {
                pl = g.plan(i) orelse {
                    g.blocked += 1;
                    continue;
                };
                if (pl.has_part) {
                    const fp = g.findPartner(i, pl) orelse {
                        g.blocked += 1;
                        continue;
                    };
                    partner = fp.j;
                    pnew = fp.r;
                    face = fp.f;
                    if (g.cfg.colour and g.cfg.tension and !pl.weak and g.exchCost(i, face, pl.dv) > g.memOf(i)) { // RULE 35
                        g.blocked += 1;
                        continue;
                    }
                }
                if (g.excluded(i, pl.np)) {
                    g.blocked += 1;
                    continue;
                }
            }
            var owe: i64 = 0;
            g.p5[i] = pl.np;
            if (partner) |j| {
                g.p5[j] = pnew;
                g.taken[j] = true;
                g.exchanges += 1;
                if (g.cfg.colour and !pl.weak) {
                    const l = g3.Grid3.linkOf(i, face).?;
                    const e0 = fE(g.fx[l][0], g.fx[l][1], g.fx[l][2]);
                    g.addFlux(i, face, pl.dv);
                    const de = fE(g.fx[l][0], g.fx[l][1], g.fx[l][2]) - e0;
                    if (g.cfg.tension) owe = de else g.exch_de += de;
                }
            }
            g.taken[i] = true;
            g.fired[i] = true;
            count += 1;
            var rel = g.cs5[i];
            if (owe < 0) g.carrier[i] += @floatFromInt(-owe);
            while (owe > 0) : (owe -= 1) { // RULE 35: the exchange pays for the string out of the released memory
                var k: usize = 0;
                for (1..5) |q| if (rel[q] > rel[k]) {
                    k = q;
                };
                rel[k] -= 1;
            }
            g.cs5[i] = .{ 0, 0, 0, 0, 0 };
            g.rf5[i] = .{ 0, 0, 0, 0, 0 };
            try shouts.append(alloc, .{ .i = i, .rel = rel });
        }
        for (shouts.items) |sh| g.shout(sh.i, sh.rel);
        {
            var before: f64 = 0;
            for (g.carrier) |v| before += v;
            g.spread();
            var after: f64 = 0;
            for (g.carrier) |v| after += v;
            g.lost += before - after;
        }
        if (g.cfg.gravity or g.cfg.cancel or g.cfg.excite) for (0..n) |i| {
            if (g.carrier[i] < 5) continue;
            const k: u32 = @intFromFloat(@floor(g.carrier[i] / 5));
            if (g.cfg.gravity) {
                g.carrier[i] -= @as(f64, @floatFromInt(k)) * 5;
                for (0..5) |q| g.rf5[i][q] += k;
            } else if (g.cfg.cancel) {
                for (0..5) |q| {
                    const m = @min(k, g.cs5[i][q]);
                    g.cs5[i][q] -= m;
                    g.carrier[i] -= @floatFromInt(m);
                }
            } else {
                g.carrier[i] -= @as(f64, @floatFromInt(k)) * 5;
                for (0..5) |q| g.cs5[i][q] += k;
            }
        };
        if (g.cfg.em) g.emField();
        if (g.cfg.colour) g.relax();
        g.broke = 0;
        if (g.cfg.colour and g.cfg.tension) g.breakStrings();
        if (g.cfg.motion) g.move();
        g.t += 1;
        return count;
    }

    fn spread(g: *Five) void {
        g.next = @splat(0);
        for (0..n) |i| {
            const q = g.carrier[i];
            if (q == 0) continue;
            const share = q / 6.0;
            const c = g3.coords(i);
            if (c[0] + 1 < side) g.next[i + 1] += share;
            if (c[0] > 0) g.next[i - 1] += share;
            if (c[1] + 1 < side) g.next[i + side] += share;
            if (c[1] > 0) g.next[i - side] += share;
            if (c[2] + 1 < side) g.next[i + side * side] += share;
            if (c[2] > 0) g.next[i - side * side] += share;
        }
        g.carrier = g.next;
    }
    fn emField(g: *Five) void {
        for (0..n) |i| g.phi[i] += @floatFromInt(q5(g.p5[i]));
        g.phin = @splat(0);
        for (0..n) |i| {
            const q = g.phi[i];
            if (q == 0) continue;
            const share = q / 6.0;
            const c = g3.coords(i);
            if (c[0] + 1 < side) g.phin[i + 1] += share;
            if (c[0] > 0) g.phin[i - 1] += share;
            if (c[1] + 1 < side) g.phin[i + side] += share;
            if (c[1] > 0) g.phin[i - side] += share;
            if (c[2] + 1 < side) g.phin[i + side * side] += share;
            if (c[2] > 0) g.phin[i - side * side] += share;
        }
        g.phi = g.phin;
    }
    /// RULE 31 (c): one pass of plaquette moves, each lowering the flux energy if it can.
    fn relax(g: *Five) void {
        const opts = [6][3]i32{ .{ 1, 0, 0 }, .{ -1, 0, 0 }, .{ 0, 1, 0 }, .{ 0, -1, 0 }, .{ 0, 0, 1 }, .{ 0, 0, -1 } };
        const sg = [4]i32{ 1, 1, -1, -1 };
        var moves: u32 = 0;
        for (0..n) |i| for (0..3) |mu| for (mu + 1..3) |nu| {
            const a = g3.Grid3.linkOf(i, 2 * mu) orelse continue;
            const d = g3.Grid3.linkOf(i, 2 * nu) orelse continue;
            const iu = g3.neighbors(i)[2 * mu];
            const iv = g3.neighbors(i)[2 * nu];
            const b = g3.Grid3.linkOf(iu, 2 * nu) orelse continue;
            const c = g3.Grid3.linkOf(iv, 2 * mu) orelse continue;
            const L = [4]usize{ a, b, c, d };
            var e0: i64 = 0;
            for (L) |l| e0 += fE(g.fx[l][0], g.fx[l][1], g.fx[l][2]);
            var best: ?usize = null;
            var best_e = e0;
            for (0..6) |o| {
                var e: i64 = 0;
                for (0..4) |k| {
                    const l = L[k];
                    const v = opts[o];
                    e += fE(g.fx[l][0] + sg[k] * v[0], g.fx[l][1] + sg[k] * v[1], g.fx[l][2] + sg[k] * v[2]);
                }
                if (e < best_e) {
                    best_e = e;
                    best = o;
                }
            }
            if (best) |o| {
                for (0..4) |k| for (0..3) |cc| {
                    g.fx[L[k]][cc] += sg[k] * opts[o][cc];
                };
                moves += 1;
                if (g.cfg.tension) g.carrier[i] += @floatFromInt(e0 - best_e); // RULE 34 (b)
            }
        };
        g.relaxed = moves;
    }
    /// RULE 24 with five cells; RULE 31 (d): strings pull colour-charged pixels. No move crosses the box edge.
    fn move(g: *Five) void {
        g.moved = @splat(false);
        g.swaps = 0;
        for (0..n) |i| {
            if (!g.fired[i] or g.moved[i]) continue;
            var best: ?usize = null;
            var best_face: usize = 0;
            const nb = g3.neighbors(i);
            if (g.cfg.colour and ncol(g.p5[i]) % 3 != 0) {
                var best_d: i64 = 0;
                const ri = col(g.p5[i]);
                for (0..6) |q| {
                    const l = g3.Grid3.linkOf(i, q) orelse continue;
                    const j = nb[q];
                    if (g.fired[j] or g.moved[j]) continue;
                    const rj = col(g.p5[j]);
                    const s: i32 = if (q & 1 == 1) -1 else 1;
                    const F = g.fx[l];
                    var Fn: [3]i32 = undefined;
                    for (0..3) |cc| Fn[cc] = F[cc] + s * (rj[cc] - ri[cc]);
                    const dd = fE(Fn[0], Fn[1], Fn[2]) - fE(F[0], F[1], F[2]);
                    if (dd < best_d) {
                        best_d = dd;
                        best = j;
                        best_face = q;
                    }
                }
            }
            if (best == null) {
                const qc: f64 = @floatFromInt(q5(g.p5[i]));
                if (g.cfg.em and qc != 0) {
                    var bv = qc * g.phi[i];
                    for (0..6) |q| {
                        if (g3.Grid3.linkOf(i, q) == null) continue;
                        if (qc * g.phi[nb[q]] < bv) {
                            best = nb[q];
                            best_face = q;
                            bv = qc * g.phi[nb[q]];
                        }
                    }
                } else {
                    var bc = g.carrier[i];
                    for (0..6) |q| {
                        if (g3.Grid3.linkOf(i, q) == null) continue;
                        if (g.carrier[nb[q]] > bc) {
                            best = nb[q];
                            best_face = q;
                            bc = g.carrier[nb[q]];
                        }
                    }
                }
            }
            const b = best orelse continue;
            if (g.fired[b] or g.moved[b]) continue;
            if (g.cfg.colour and g.cfg.tension) { // RULE 34 (a): a move pays for the string it stretches
                const l = g3.Grid3.linkOf(i, best_face).?;
                const ri = col(g.p5[i]);
                const rj = col(g.p5[b]);
                const s: i32 = if (best_face & 1 == 1) -1 else 1;
                const F = g.fx[l];
                const d = fE(F[0] + s * (rj[0] - ri[0]), F[1] + s * (rj[1] - ri[1]), F[2] + s * (rj[2] - ri[2])) - fE(F[0], F[1], F[2]);
                if (d > 0) {
                    var mem: i64 = 0;
                    for (g.cs5[i]) |v| mem += v;
                    if (@as(f64, @floatFromInt(mem)) + g.carrier[i] < @as(f64, @floatFromInt(d))) continue;
                    var owe = d;
                    while (owe > 0 and mem > 0) : (owe -= 1) {
                        var k: usize = 0;
                        for (1..5) |q| if (g.cs5[i][q] > g.cs5[i][k]) {
                            k = q;
                        };
                        g.cs5[i][k] -= 1;
                        mem -= 1;
                    }
                    g.carrier[i] -= @floatFromInt(owe);
                } else if (d < 0) g.carrier[b] += @floatFromInt(-d);
            }
            if (g.cfg.colour) {
                const ri = col(g.p5[i]);
                const rj = col(g.p5[b]);
                g.addFlux(i, best_face, .{ rj[0] - ri[0], rj[1] - ri[1], rj[2] - ri[2] });
            }
            std.mem.swap(u8, &g.p5[i], &g.p5[b]);
            std.mem.swap(bool, &g.fired[i], &g.fired[b]);
            std.mem.swap([5]u32, &g.rf5[i], &g.rf5[b]);
            std.mem.swap([5]u32, &g.cs5[i], &g.cs5[b]);
            g.moved[i] = true;
            g.moved[b] = true;
            g.swaps += 1;
        }
    }

    /// RULE 34 (c): a link between an all-colour pixel and a no-colour pixel may break the string by passing a colour cell.
    fn breakStrings(g: *Five) void {
        var used: [n]bool = @splat(false);
        for (0..n) |i| for (0..3) |ax| {
            const l = g3.Grid3.linkOf(i, 2 * ax) orelse continue;
            const j = g3.neighbors(i)[2 * ax];
            if (used[i] or used[j]) continue;
            const ci = ncol(g.p5[i]);
            const cj = ncol(g.p5[j]);
            if (!((ci == 3 and cj == 0) or (ci == 0 and cj == 3))) continue;
            const sgn: i32 = if (ci == 3) -1 else 1; // flux change on the link: -e_c if i gives c, +e_c if i takes c
            const F = g.fx[l];
            const e0 = fE(F[0], F[1], F[2]);
            var best: ?usize = null;
            var be = e0;
            for (0..3) |c| {
                var Fn = F;
                Fn[c] += sgn;
                const e = fE(Fn[0], Fn[1], Fn[2]);
                if (e < be) {
                    be = e;
                    best = c;
                }
            }
            const c = best orelse continue;
            g.fx[l][c] += sgn;
            const bit = @as(u8, 1) << @intCast(c);
            g.p5[i] ^= bit;
            g.p5[j] ^= bit;
            g.carrier[i] += @floatFromInt(e0 - be);
            used[i] = true;
            used[j] = true;
            g.broke += 1;
        };
    }

    pub fn stats(g: *const Five, flashes: u32) Stats {
        var st: Stats = .{ .flashes = flashes, .exchanges = g.exchanges, .blocked = g.blocked, .released = g.released, .quark_r = 0, .relaxed = g.relaxed, .swaps = g.swaps, .charge3 = 0, .colour = .{ 0, 0 }, .quarks = 0, .gauss = 0, .flux_e3 = 0, .strings = 0, .carrier = 0, .memory = 0, .broke = g.broke, .lost = g.lost, .exch_de = g.exch_de };
        var R: i64 = 0;
        var G: i64 = 0;
        var B: i64 = 0;
        for (0..n) |i| {
            const p = g.p5[i];
            st.charge3 += q5(p);
            R += p & 1;
            G += (p >> 1) & 1;
            B += (p >> 2) & 1;
            if (ncol(p) % 3 != 0) {
                st.quarks += 1;
                st.quark_r += g3.radius(i);
            }
            st.carrier += g.carrier[i];
            for (g.cs5[i]) |v| st.memory += v;
        }
        st.colour = .{ R - B, G - B };
        if (st.quarks > 0) st.quark_r /= @floatFromInt(st.quarks);
        if (g.cfg.colour) {
            for (0..n * 3) |l| {
                const e = fE(g.fx[l][0], g.fx[l][1], g.fx[l][2]);
                st.flux_e3 += e;
                if (e != 0) st.strings += 1;
            }
            for (0..n) |i| {
                var dsum: [3]i64 = .{ 0, 0, 0 };
                for (0..6) |q| {
                    const l = g3.Grid3.linkOf(i, q) orelse continue;
                    const s: i64 = if (q & 1 == 1) -1 else 1;
                    for (0..3) |c| dsum[c] += s * g.fx[l][c];
                }
                if (i % side == side - 1) for (0..3) |c| {
                    dsum[c] += g.edge[i][c];
                };
                const c = col(g.p5[i]);
                const r = [3]i64{ dsum[0] - c[0], dsum[1] - c[1], dsum[2] - c[2] };
                st.gauss = @max(st.gauss, @as(i64, @intCast(@max(@abs(r[0] - r[1]), @abs(r[1] - r[2])))));
            }
        }
        return st;
    }
};

test "rule 30: charges of the five-cell table" {
    try std.testing.expectEqual(@as(i32, 0), q5(0)); // antineutrino (empty)
    try std.testing.expectEqual(@as(i32, -1), q5(0b00001)); // down
    try std.testing.expectEqual(@as(i32, -2), q5(0b00011)); // anti-up
    try std.testing.expectEqual(@as(i32, -3), q5(0b00111)); // electron
    try std.testing.expectEqual(@as(i32, 2), q5(0b01001)); // up = u + one colour
    try std.testing.expectEqual(@as(i32, 0), q5(0b01111)); // neutrino = u + three colours
    try std.testing.expectEqual(@as(i32, 0), q5(0b11111)); // right-handed neutrino
}

test "rule 30: beta decay is one weak flip, charge balanced by electron and antineutrino" {
    const down: u8 = 0b10001; // d + red
    const up = down ^ 24; // flip d -> u
    try std.testing.expectEqual(@as(u8, 0b01001), up);
    try std.testing.expectEqual(@as(u32, ncol(down)), ncol(up)); // colour untouched
    // d -> u + e (r+g+b+d, left-handed) + antineutrino (empty): -1 = +2 - 3 + 0
    try std.testing.expectEqual(q5(down), q5(up) + q5(0b10111) + q5(0));
}

test "rule 31: the start obeys the Gauss law" {
    const g = try std.testing.allocator.create(Five);
    defer std.testing.allocator.destroy(g);
    g.init(.{});
    try std.testing.expectEqual(@as(i64, 0), g.stats(0).gauss);
}

test "rule 33: the neutral start is colour-neutral outside the core and obeys the Gauss law" {
    const g = try std.testing.allocator.create(Five);
    defer std.testing.allocator.destroy(g);
    g.init(.{ .neutral = true, .core = 6 });
    var quarks_outside: u32 = 0;
    for (0..n) |i| if (g3.radius(i) > 6 and ncol(g.p5[i]) % 3 != 0) {
        quarks_outside += 1;
    };
    try std.testing.expectEqual(@as(u32, 0), quarks_outside);
    const st = g.stats(0);
    try std.testing.expectEqual(@as(i64, 0), st.gauss);
    try std.testing.expectEqual(@as(i64, 0), st.colour[0]);
    try std.testing.expectEqual(@as(i64, 0), st.colour[1]);
}
