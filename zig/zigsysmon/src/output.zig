//! Output formatting module for zigsysmon
//!
//! This module provides formatters for converting system metrics into various
//! output formats suitable for different use cases:
//!
//! - **plain**: Human-readable text output (default)
//! - **json**: Structured JSON for machine parsing and integration with tools like rofi
//! - **csv**: Comma-separated values for data analysis and time-series archival
//!
//! All formatters write to stdout via std.debug.print() for simplicity and
//! compatibility with shell redirection and piping.

const std = @import("std");
const metrics = @import("metrics.zig");

/// Output format options for metrics display
pub const OutputFormat = enum {
    /// Human-readable plain text: "CPU: user=X system=Y idle=Z"
    plain,
    /// Structured JSON: {"cpu_total": {...}, "memory": {...}, ...}
    json,
    /// CSV format: timestamp,metric,value (useful for time-series data)
    csv,
};

/// Format metrics as human-readable plain text
///
/// Output format:
/// ```
/// CPU (total): user=X system=Y idle=Z
/// CPU 0: user=X system=Y idle=Z
/// ...
/// Memory: total=1000MB used=500MB free=500MB
/// Disk: total=1000MB used=500MB free=500MB
/// Network: RX=1000000B TX=500000B
/// ```
pub fn formatPlain(m: metrics.Metrics) void {
    std.debug.print("CPU (total): user={} system={} idle={}\n", .{
        m.cpu_times[0].user,
        m.cpu_times[0].system,
        m.cpu_times[0].idle,
    });

    for (1..m.cpu_times.len) |i| {
        std.debug.print("CPU {}: user={} system={} idle={}\n", .{
            i - 1,
            m.cpu_times[i].user,
            m.cpu_times[i].system,
            m.cpu_times[i].idle,
        });
    }

    std.debug.print("Memory: total={}MB used={}MB free={}MB\n", .{
        m.memory.total,
        m.memory.used,
        m.memory.free,
    });

    std.debug.print("Disk: total={}MB used={}MB free={}MB\n", .{
        m.disk.total,
        m.disk.used,
        m.disk.free,
    });

    std.debug.print("Network: RX={}B TX={}B\n", .{
        m.network.rx_bytes,
        m.network.tx_bytes,
    });
}

/// Format metrics as JSON for machine parsing and tool integration
///
/// Output format:
/// ```json
/// {
///   "timestamp": 1234567890,
///   "cpu_count": 8,
///   "cpu_total": {"user": 1000, "system": 500, "idle": 5000},
///   "cpu_cores": [{"id": 0, "user": 100, "system": 50, "idle": 625}, ...],
///   "memory": {"total": 15175, "used": 7621, "free": 7554},
///   "disk": {"total": 512000, "used": 200000, "free": 312000},
///   "network": {"rx_bytes": 5194166717, "tx_bytes": 836854465}
/// }
/// ```
///
/// Suitable for integration with jq, rofi, and other JSON-aware tools.
pub fn formatJson(m: metrics.Metrics) void {
    std.debug.print("{{", .{});

    std.debug.print("\"timestamp\":{}", .{m.timestamp});

    std.debug.print(",\"cpu_count\":{}", .{m.cpu_times.len});
    std.debug.print(",\"cpu_total\":{{\"user\":{},\"system\":{},\"idle\":{}}}", .{
        m.cpu_times[0].user,
        m.cpu_times[0].system,
        m.cpu_times[0].idle,
    });

    std.debug.print(",\"cpu_cores\":[", .{});
    for (1..m.cpu_times.len) |i| {
        if (i > 1) std.debug.print(",", .{});
        std.debug.print("{{\"id\":{},\"user\":{},\"system\":{},\"idle\":{}}}", .{
            i - 1,
            m.cpu_times[i].user,
            m.cpu_times[i].system,
            m.cpu_times[i].idle,
        });
    }
    std.debug.print("]", .{});

    std.debug.print(",\"memory\":{{\"total\":{},\"used\":{},\"free\":{}}}", .{
        m.memory.total,
        m.memory.used,
        m.memory.free,
    });

    std.debug.print(",\"disk\":{{\"total\":{},\"used\":{},\"free\":{}}}", .{
        m.disk.total,
        m.disk.used,
        m.disk.free,
    });

    std.debug.print(",\"network\":{{\"rx_bytes\":{},\"tx_bytes\":{}}}", .{
        m.network.rx_bytes,
        m.network.tx_bytes,
    });

    std.debug.print("}}\n", .{});
}

/// Format metrics as CSV for time-series data analysis
///
/// Output format:
/// ```csv
/// timestamp,metric,value
/// 1234567890,cpu_total_user,5585709
/// 1234567890,cpu_total_system,1092448
/// 1234567890,cpu0_user,645450
/// ...
/// 1234567890,memory_total_mb,15175
/// 1234567890,memory_used_mb,7621
/// ...
/// ```
///
/// Use for:
/// - Long-term metric archival: `zigsysmon --format csv >> metrics.csv`
/// - Time-series analysis with tools like awk, gnuplot, or pandas
/// - Integration with monitoring systems
pub fn formatCsv(m: metrics.Metrics) void {
    std.debug.print("timestamp,metric,value\n", .{});

    std.debug.print("{},cpu_total_user,{}\n", .{ m.timestamp, m.cpu_times[0].user });
    std.debug.print("{},cpu_total_system,{}\n", .{ m.timestamp, m.cpu_times[0].system });
    std.debug.print("{},cpu_total_idle,{}\n", .{ m.timestamp, m.cpu_times[0].idle });

    for (1..m.cpu_times.len) |i| {
        std.debug.print("{},cpu{}_user,{}\n", .{ m.timestamp, i - 1, m.cpu_times[i].user });
        std.debug.print("{},cpu{}_system,{}\n", .{ m.timestamp, i - 1, m.cpu_times[i].system });
        std.debug.print("{},cpu{}_idle,{}\n", .{ m.timestamp, i - 1, m.cpu_times[i].idle });
    }

    std.debug.print("{},memory_total_mb,{}\n", .{ m.timestamp, m.memory.total });
    std.debug.print("{},memory_used_mb,{}\n", .{ m.timestamp, m.memory.used });
    std.debug.print("{},memory_free_mb,{}\n", .{ m.timestamp, m.memory.free });

    std.debug.print("{},disk_total_mb,{}\n", .{ m.timestamp, m.disk.total });
    std.debug.print("{},disk_used_mb,{}\n", .{ m.timestamp, m.disk.used });
    std.debug.print("{},disk_free_mb,{}\n", .{ m.timestamp, m.disk.free });

    std.debug.print("{},network_rx_bytes,{}\n", .{ m.timestamp, m.network.rx_bytes });
    std.debug.print("{},network_tx_bytes,{}\n", .{ m.timestamp, m.network.tx_bytes });
}

/// Main formatter dispatcher
///
/// Routes metrics to the appropriate formatter based on OutputFormat.
/// Currently uses std.debug.print() for output, which writes to stderr.
/// To redirect to stdout, use shell redirection: `zigsysmon 2>&1`
///
/// Arguments:
/// - m: Metrics snapshot containing all system data
/// - fmt_type: OutputFormat enum selecting the desired output format
/// - writer: Unused (kept for future file-based output support)
/// - allocator: Unused (kept for future buffered output)
pub fn format(m: metrics.Metrics, fmt_type: OutputFormat, writer: anytype, allocator: std.mem.Allocator) !void {
    switch (fmt_type) {
        .plain => formatPlain(m),
        .json => formatJson(m),
        .csv => formatCsv(m),
    }

    _ = writer;
    _ = allocator;
}
