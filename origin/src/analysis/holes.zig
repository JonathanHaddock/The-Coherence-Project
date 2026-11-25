//! Holes test: which scales on a pixel ring can be built from smaller ones?
//!
//! A ring of n pixels. A pattern "at scale a" repeats every a pixels. For
//! each n, collect every pattern you can make from smaller scales that fit
//! the ring (a divides n, a < n), and count how many independent patterns
//! of the n-ring are still missing: the part that has to be new.
//!
//! Two ways to overlap smaller patterns:
//!   add:      two patterns shining on the same pixels (values summed)
//!   multiply: a pixel is lit only where both patterns are lit
//!
//! A scale with nothing missing is fully built from smaller scales.
//! A scale with something missing is a hole: it cannot be made from below.

const std = @import("std");

/// Rank of a set of row vectors (length n), by elimination. Entries are
/// 0/1 so pivots stay well away from zero.
fn rank(rows: [][]f64, n: usize) usize {
    var r: usize = 0;
    for (0..n) |col| {
        var piv: ?usize = null;
        var best: f64 = 1e-9;
        for (r..rows.len) |i| if (@abs(rows[i][col]) > best) {
            best = @abs(rows[i][col]);
            piv = i;
        };
        const p = piv orelse continue;
        std.mem.swap([]f64, &rows[r], &rows[p]);
        for (0..rows.len) |i| {
            if (i == r) continue;
            const f = rows[i][col] / rows[r][col];
            if (f == 0) continue;
            for (0..n) |j| rows[i][j] -= f * rows[r][j];
        }
        r += 1;
        if (r == rows.len) break;
    }
    return r;
}

pub const Result = struct { n: usize, missing_add: usize, missing_mul: usize };

pub fn scale(gpa: std.mem.Allocator, n: usize) !Result {
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    // Building blocks at scale a: "lit at positions r, r+a, r+2a, ...".
    var add_rows: std.ArrayList([]f64) = .empty;
    var mul_rows: std.ArrayList([]f64) = .empty;
    for (1..n) |a| {
        if (n % a != 0) continue;
        for (0..a) |r| {
            const v = try arena.alloc(f64, n);
            for (v, 0..) |*x, i| x.* = if (i % a == r) 1 else 0;
            try add_rows.append(arena, v);
        }
    }
    // Multiply: overlap a block at scale a with a block at scale b (both < n).
    for (1..n) |a| for (a..n) |b| {
        if (n % a != 0 or n % b != 0) continue;
        for (0..a) |r| for (0..b) |q| {
            const v = try arena.alloc(f64, n);
            var any = false;
            for (v, 0..) |*x, i| {
                x.* = if (i % a == r and i % b == q) 1 else 0;
                if (x.* != 0) any = true;
            }
            if (any) try mul_rows.append(arena, v);
        };
    };
    const ra = if (add_rows.items.len == 0) 0 else rank(add_rows.items, n);
    const rm = if (mul_rows.items.len == 0) 0 else rank(mul_rows.items, n);
    return .{ .n = n, .missing_add = n - ra, .missing_mul = n - rm };
}

test "small scales" {
    const gpa = std.testing.allocator;
    // 6 = 2 x 3: multiplying a 2-pattern and a 3-pattern builds everything.
    try std.testing.expectEqual(@as(usize, 0), (try scale(gpa, 6)).missing_mul);
    // 7: nothing smaller fits but 1.
    try std.testing.expectEqual(@as(usize, 6), (try scale(gpa, 7)).missing_mul);
    // 4: only 2s fit, and 2 times 2 is still 2.
    try std.testing.expect((try scale(gpa, 4)).missing_mul > 0);
    // Adding: every scale n leaves phi(n) new patterns (6 -> 2).
    try std.testing.expectEqual(@as(usize, 2), (try scale(gpa, 6)).missing_add);
}
