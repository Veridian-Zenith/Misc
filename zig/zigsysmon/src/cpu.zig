const std = @import("std");

/// CPU time metrics structure
/// Represents the amount of time (in jiffies/ticks) spent in different execution states
/// CPU time metrics structure (all fields represent jiffies/ticks)
pub const CpuTime = struct {
    /// Time spent in user mode
    user: u64,
    /// Time spent in user mode with low priority (nice)
    nice: u64,
    /// Time spent in kernel/system mode
    system: u64,
    /// Time spent idle
    idle: u64,
};

/// Read CPU times from /proc/stat
///
/// Parses the Linux /proc/stat file to extract CPU time counters.
/// The file format has one line per logical CPU:
///   cpu  <user> <nice> <system> <idle> <iowait> <irq> <softirq> ...
///   cpu0 <user> <nice> <system> <idle> <iowait> <irq> <softirq> ...
///
/// Args:
///   allocator: Memory allocator for the returned slice
///
/// Returns:
///   A slice of CpuTime structs, where [0] is the aggregate and [1..n] are per-core.
///   Caller must free this allocation.
///
/// Errors:
///   - OpenError if /proc/stat cannot be accessed
///   - ParseIntError if numeric fields are malformed
pub fn getCpuTimes(allocator: std.mem.Allocator) ![]CpuTime {
    const file = try std.fs.openFileAbsolute("/proc/stat", .{});
    defer file.close();

    const buffer = try file.readToEndAlloc(allocator, 1024 * 64);
    defer allocator.free(buffer);

    var lines = std.mem.splitSequence(u8, buffer, "\n");
    var cpu_count: usize = 0;

    // First pass: count CPU lines (cpu, cpu0, cpu1, ...)
    var temp_lines = std.mem.splitSequence(u8, buffer, "\n");
    while (temp_lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " ");
        if (std.mem.startsWith(u8, trimmed, "cpu")) {
            cpu_count += 1;
        }
    }

    const times = try allocator.alloc(CpuTime, cpu_count);
    var idx: usize = 0;

    // Second pass: parse CPU times
    lines = std.mem.splitSequence(u8, buffer, "\n");
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " ");
        if (!std.mem.startsWith(u8, trimmed, "cpu")) {
            continue;
        }

        // Tokenize respecting multiple whitespace characters
        var parts = std.mem.tokenizeAny(u8, trimmed, " \t");
        _ = parts.next(); // skip "cpu" or "cpu#" label

        var user: u64 = 0;
        var nice: u64 = 0;
        var system: u64 = 0;
        var idle: u64 = 0;

        // Parse numeric fields, using 0 as default on parse error
        if (parts.next()) |part| user = std.fmt.parseInt(u64, part, 10) catch 0;
        if (parts.next()) |part| nice = std.fmt.parseInt(u64, part, 10) catch 0;
        if (parts.next()) |part| system = std.fmt.parseInt(u64, part, 10) catch 0;
        if (parts.next()) |part| idle = std.fmt.parseInt(u64, part, 10) catch 0;

        times[idx] = CpuTime{ .user = user, .nice = nice, .system = system, .idle = idle };
        idx += 1;
    }

    return times;
}
