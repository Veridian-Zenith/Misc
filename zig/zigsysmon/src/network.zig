const std = @import("std");

/// Network interface statistics
/// Aggregates counters across all network interfaces (except loopback)
pub const NetStats = struct {
    /// Total bytes received across all interfaces
    rx_bytes: u64,
    /// Total bytes transmitted across all interfaces
    tx_bytes: u64,
};

/// Read aggregate network statistics from /proc/net/dev
///
/// Parses the Linux /proc/net/dev file to extract per-interface traffic counters.
/// The loopback interface (lo) is excluded to focus on real network activity.
///
/// File format (with | separators):
///   Inter-|   Receive                                                |  Transmit
///    face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets ...
///     eth0: 1234567 5678   0    0    0     0     0          0        |9876543  1234 ...
///
/// Args:
///   allocator: Memory allocator for temporary buffers
///
/// Returns:
///   NetStats struct with aggregate RX/TX bytes
///
/// Errors:
///   - OpenError if /proc/net/dev cannot be accessed
///   - ParseIntError if numeric fields are malformed
pub fn getNetStats(allocator: std.mem.Allocator) !NetStats {
    const file = try std.fs.openFileAbsolute("/proc/net/dev", .{});
    defer file.close();

    const buffer = try file.readToEndAlloc(allocator, 1024 * 64);
    defer allocator.free(buffer);

    var rx_bytes: u64 = 0;
    var tx_bytes: u64 = 0;

    // Parse network device file line by line
    var lines = std.mem.splitSequence(u8, buffer, "\n");
    var skip_count: usize = 0;

    while (lines.next()) |line| {
        skip_count += 1;
        // /proc/net/dev has two header lines that must be skipped
        if (skip_count <= 2) {
            continue;
        }

        const trimmed = std.mem.trim(u8, line, " ");
        if (trimmed.len == 0) {
            continue;
        }

        // Skip loopback interface
        if (std.mem.startsWith(u8, trimmed, "lo:")) {
            continue;
        }

        // Parse interface line: "eth0:  rx_bytes rx_packets ... tx_bytes ..."
        // The colon separates interface name from statistics
        var interface_sep = std.mem.splitSequence(u8, trimmed, ":");
        if (interface_sep.next()) |_| {
            if (interface_sep.next()) |data_part| {
                var parts = std.mem.tokenizeAny(u8, data_part, " \t");

                // Field 1: rx_bytes - sum all interfaces
                if (parts.next()) |rx_str| {
                    if (std.fmt.parseInt(u64, rx_str, 10)) |rx| {
                        rx_bytes += rx;
                    } else |_| {}
                }

                // Fields 2-8: Skip rx_packets, rx_errors, rx_dropped, rx_fifo, rx_frame, rx_compressed, rx_multicast
                for (0..7) |_| {
                    _ = parts.next();
                }

                // Field 9: tx_bytes - sum all interfaces
                if (parts.next()) |tx_str| {
                    if (std.fmt.parseInt(u64, tx_str, 10)) |tx| {
                        tx_bytes += tx;
                    } else |_| {}
                }
            }
        }
    }

    return NetStats{
        .rx_bytes = rx_bytes, // Aggregate bytes from all interfaces (except loopback)
        .tx_bytes = tx_bytes, // Aggregate bytes from all interfaces (except loopback)
    };
}
