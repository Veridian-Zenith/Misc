const std = @import("std");
const cpu = @import("cpu.zig");
const mem = @import("mem.zig");
const network = @import("network.zig");

// Test CPU time parsing with valid /proc/stat format
test "CPU times parsing" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const result = gpa.deinit();
        if (result == .leak) std.debug.print("Memory leak in test\n", .{});
    }

    const allocator = gpa.allocator();

    // This test requires actual /proc/stat access on Linux
    const times = try cpu.getCpuTimes(allocator);
    defer allocator.free(times);

    try std.testing.expect(times.len > 0);
    try std.testing.expect(times[0].idle > 0);
}

// Test memory parsing with valid /proc/meminfo format
test "Memory stats parsing" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const result = gpa.deinit();
        if (result == .leak) std.debug.print("Memory leak in test\n", .{});
    }

    const allocator = gpa.allocator();

    // This test requires actual /proc/meminfo access on Linux
    const stats = try mem.getMemStats(allocator);
    try std.testing.expect(stats.total > 0);
}

// Test network stats parsing with valid /proc/net/dev format
test "Network stats parsing" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const result = gpa.deinit();
        if (result == .leak) std.debug.print("Memory leak in test\n", .{});
    }

    const allocator = gpa.allocator();

    // This test requires actual /proc/net/dev access on Linux
    const stats = try network.getNetStats(allocator);
    try std.testing.expect(stats.rx_bytes >= 0);
}

// Test that tokenizeAny correctly splits strings with multiple delimiters
test "Tokenize with whitespace handling" {
    const input = "cpu0   123456   789   10   20";
    var tokens = std.mem.tokenizeAny(u8, input, " \t");

    try std.testing.expectEqualStrings("cpu0", tokens.next().?);
    try std.testing.expectEqualStrings("123456", tokens.next().?);
    try std.testing.expectEqualStrings("789", tokens.next().?);
}

// Test u64 parsing with error handling
test "Integer parsing with error handling" {
    const valid = "12345";
    try std.testing.expectEqual(@as(u64, 12345), try std.fmt.parseInt(u64, valid, 10));

    const invalid = "not_a_number";
    try std.testing.expectError(std.fmt.ParseIntError.InvalidCharacter, std.fmt.parseInt(u64, invalid, 10));
}
