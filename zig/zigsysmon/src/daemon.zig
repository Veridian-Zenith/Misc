//! Daemon operation modes for zigsysmon
//!
//! This module provides three operational modes:
//!
//! 1. **runDaemon()**: Continuous monitoring to stdout
//!    - Useful for: `watch` command, log streaming, real-time dashboards
//!    - Usage: `zigsysmon --daemon 500`
//!
//! 2. **runDaemonFile()**: Continuous monitoring to a file
//!    - Useful for: rofi integration via named pipes, metrics aggregation
//!    - Usage: `zigsysmon --daemon 1000 --output /tmp/metrics.json`
//!
//! 3. **runOnce()**: Single metric snapshot (default mode)
//!    - Useful for: cron jobs, adhoc checking, integration with other tools
//!    - Usage: `zigsysmon` or `zigsysmon --format json`
//!
//! All modes support multiple output formats (plain, JSON, CSV) via the format module.

const std = @import("std");
const metrics = @import("metrics.zig");
const output = @import("output.zig");

/// Continuously output metrics to stdout at regular intervals
///
/// Runs indefinitely, collecting and formatting metrics every interval_ms milliseconds.
/// Uses nanosleep for precise timing (converted from milliseconds).
///
/// Useful for:
/// - Real-time monitoring with human-readable output
/// - Piping to other tools: `zigsysmon --daemon 500 --format json | jq '.memory'`
/// - Integration with terminal multiplexers and monitoring dashboards
///
/// Arguments:
/// - allocator: Memory allocator (required for metrics.collect())
/// - interval_ms: Milliseconds between updates
/// - format_type: Output format (plain, json, or csv)
pub fn runDaemon(
    allocator: std.mem.Allocator,
    interval_ms: u64,
    format_type: output.OutputFormat,
) !void {
    // Main loop: collect, format, sleep, repeat
    while (true) {
        var m = try metrics.collect(allocator);
        defer m.deinit(allocator);

        // Output metrics in requested format
        try output.format(m, format_type, undefined, allocator);

        // Sleep for interval (convert milliseconds to nanoseconds)
        const nanos = interval_ms * 1_000_000;
        _ = std.posix.nanosleep(nanos, 0);
    }
}

/// Continuously output metrics to a file at regular intervals
///
/// Creates or truncates the target file, then overwrites it with fresh metrics
/// at each interval. The file is synced to disk after each write.
///
/// Useful for:
/// - Named pipe integration with rofi: `mkfifo /tmp/sys.json && zigsysmon -d 500 -f json -o /tmp/sys.json`
/// - Metrics aggregation by external scripts
/// - Creating a "metrics endpoint" for system tools
///
/// Arguments:
/// - allocator: Memory allocator (required for metrics.collect())
/// - interval_ms: Milliseconds between updates
/// - format_type: Output format (plain, json, or csv)
/// - filepath: Path to output file (created if doesn't exist, truncated if exists)
pub fn runDaemonFile(
    allocator: std.mem.Allocator,
    interval_ms: u64,
    format_type: output.OutputFormat,
    filepath: []const u8,
) !void {
    var file = try std.fs.cwd().createFile(filepath, .{
        .truncate = false, // We'll manually seek/clear
    });
    defer file.close();

    // Main loop: collect, write to file, sync, sleep, repeat
    while (true) {
        var m = try metrics.collect(allocator);
        defer m.deinit(allocator);

        // Overwrite file with fresh metrics
        try file.seekTo(0); // Go to beginning
        try output.format(m, format_type, file, allocator); // Write new data
        try file.sync(); // Ensure written to disk

        // Sleep for the specified interval
        const nanos = interval_ms * 1_000_000;
        _ = std.posix.nanosleep(nanos, 0);
    }
}

/// Collect and output metrics once, then exit
///
/// This is the default mode when --daemon is not specified.
/// Collects a single snapshot of system metrics and outputs them in the
/// requested format, then the program terminates.
///
/// Useful for:
/// - Cron jobs and automated monitoring scripts
/// - Quick system health checks
/// - Integration with other CLI tools
/// - Generating exports: `zigsysmon --format csv >> archive.csv`
///
/// Arguments:
/// - allocator: Memory allocator (required for metrics.collect())
/// - format_type: Output format (plain, json, or csv)
pub fn runOnce(
    allocator: std.mem.Allocator,
    format_type: output.OutputFormat,
) !void {
    var m = try metrics.collect(allocator);
    defer m.deinit(allocator);

    try output.format(m, format_type, undefined, allocator);
}
