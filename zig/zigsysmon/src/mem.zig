const std = @import("std");

/// Memory statistics structure
/// Reports memory usage in megabytes (MB)
pub const MemStats = struct {
    /// Total system memory (MB)
    total: u64,
    /// Currently used memory (MB)
    used: u64,
    /// Available memory including buffers and cache (MB)
    free: u64,
};

/// Read memory statistics from /proc/meminfo
///
/// Parses the Linux /proc/meminfo file to extract memory usage metrics.
/// Automatically adjusts for buffers and cached memory to give a realistic
/// picture of available memory.
///
/// Args:
///   allocator: Memory allocator (not currently used, kept for interface consistency)
///
/// Returns:
///   MemStats struct with all values in megabytes
///
/// Errors:
///   - OpenError if /proc/meminfo cannot be accessed
///   - ParseIntError if numeric fields are malformed
pub fn getMemStats(allocator: std.mem.Allocator) !MemStats {
    const file = try std.fs.openFileAbsolute("/proc/meminfo", .{});
    defer file.close();

    const buffer = try file.readToEndAlloc(allocator, 1024 * 4);
    defer allocator.free(buffer);

    var mem_total: u64 = 0;
    var mem_free: u64 = 0;
    var buffers: u64 = 0;
    var cached: u64 = 0;

    // Parse /proc/meminfo line by line
    var lines = std.mem.splitSequence(u8, buffer, "\n");
    while (lines.next()) |line| {
        // Tokenize on colon and spaces to handle "MemTotal:    12345 kB" format
        var parts = std.mem.tokenizeAny(u8, line, ": \t");

        if (parts.next()) |key| {
            if (std.mem.eql(u8, key, "MemTotal")) {
                if (parts.next()) |num_str| {
                    mem_total = std.fmt.parseInt(u64, num_str, 10) catch 0;
                }
            } else if (std.mem.eql(u8, key, "MemFree")) {
                if (parts.next()) |num_str| {
                    mem_free = std.fmt.parseInt(u64, num_str, 10) catch 0;
                }
            } else if (std.mem.eql(u8, key, "Buffers")) {
                if (parts.next()) |num_str| {
                    buffers = std.fmt.parseInt(u64, num_str, 10) catch 0;
                }
            } else if (std.mem.eql(u8, key, "Cached")) {
                if (parts.next()) |num_str| {
                    cached = std.fmt.parseInt(u64, num_str, 10) catch 0;
                }
            }
        }
    }

    // Calculate used memory (total - free - buffers - cached)
    const mem_used = mem_total - mem_free - buffers - cached;
    return MemStats{
        // All values from /proc/meminfo are in KB, convert to MB by dividing by 1024
        .total = mem_total / 1024,
        .used = if (mem_used > 0) mem_used / 1024 else 0,
        .free = (mem_free + buffers + cached) / 1024,
    };
}
