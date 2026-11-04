const std = @import("std");

/// One downloadable dataset: where it lives and how to verify it.
pub const Entry = struct {
    name: []const u8,
    size: u64,
    adler32: u32,
    url: []const u8,
};

/// Parse a whitespace-separated manifest ("name size adler32 url" per line,
/// '#' comments). Returned entries borrow from `text`.
pub fn parse(gpa: std.mem.Allocator, text: []const u8) ![]Entry {
    var entries: std.ArrayList(Entry) = .empty;
    errdefer entries.deinit(gpa);

    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \t\r");
        if (line.len == 0 or line[0] == '#') continue;

        var fields = std.mem.tokenizeAny(u8, line, " \t");
        const name = fields.next() orelse return error.InvalidManifest;
        const size = fields.next() orelse return error.InvalidManifest;
        const checksum = fields.next() orelse return error.InvalidManifest;
        const url = fields.next() orelse return error.InvalidManifest;

        try entries.append(gpa, .{
            .name = name,
            .size = try std.fmt.parseInt(u64, size, 10),
            .adler32 = try std.fmt.parseInt(u32, checksum, 16),
            .url = url,
        });
    }
    return entries.toOwnedSlice(gpa);
}

test "parse skips comments and reads fields" {
    const text =
        \\# comment
        \\Zmumu.csv  970550  0d4cfe9f  https://example.org/Zmumu.csv
        \\
    ;
    const entries = try parse(std.testing.allocator, text);
    defer std.testing.allocator.free(entries);
    try std.testing.expectEqual(1, entries.len);
    try std.testing.expectEqualStrings("Zmumu.csv", entries[0].name);
    try std.testing.expectEqual(970550, entries[0].size);
    try std.testing.expectEqual(0x0d4cfe9f, entries[0].adler32);
}
