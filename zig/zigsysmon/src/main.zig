const std = @import("std");
const metrics_module = @import("metrics.zig");
const output = @import("output.zig");
const daemon = @import("daemon.zig");

/// zigsysmon - A lightweight system monitor written in Zig
///
/// This tool displays real-time system statistics including:
/// - CPU times per core (user, nice, system, idle)
/// - Memory usage (total, used, free)
/// - Disk space (total, used, free)
/// - Network traffic (bytes received/transmitted)
///
/// Can run as:
/// - Single snapshot (default)
/// - Continuous daemon with configurable interval
/// - Multiple output formats (plain, JSON, CSV)
///
/// Usage:
///   zigsysmon              # Single snapshot, plain text
///   zigsysmon --format json # Single snapshot, JSON
///   zigsysmon --daemon 1000 # Daemon mode, output every 1000ms
///   zigsysmon --help       # Show this message
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.debug.print("Warning: Memory leak detected!\n", .{});
        }
    }

    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // Parse command-line arguments
    // Supported flags: --help, --version, --daemon MS, --format FORMAT, --output FILE
    var daemon_mode = false;
    var interval_ms: u64 = 1000;
    var format_str: []const u8 = "plain";
    var output_file: ?[]const u8 = null;

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            // Display help and exit
            printHelp();
            return;
        } else if (std.mem.eql(u8, arg, "--version") or std.mem.eql(u8, arg, "-v")) {
            // Display version and exit
            std.debug.print("zigsysmon v1.0.0\n", .{});
            return;
        } else if (std.mem.eql(u8, arg, "--daemon") or std.mem.eql(u8, arg, "-d")) {
            // Enable daemon mode; parse optional interval in milliseconds
            // Usage: --daemon 1000  (updates every 1 second)
            daemon_mode = true;
            if (i + 1 < args.len) {
                interval_ms = std.fmt.parseInt(u64, args[i + 1], 10) catch 1000;
                i += 1;
            }
        } else if (std.mem.eql(u8, arg, "--format") or std.mem.eql(u8, arg, "-f")) {
            // Set output format: plain, json, or csv
            // Usage: --format json
            if (i + 1 < args.len) {
                format_str = args[i + 1];
                i += 1;
            }
        } else if (std.mem.eql(u8, arg, "--output") or std.mem.eql(u8, arg, "-o")) {
            // Set output file path (used only in daemon mode with file writing)
            // Usage: --output /tmp/metrics.json
            if (i + 1 < args.len) {
                output_file = args[i + 1];
                i += 1;
            }
        }
    }

    // Validate and convert format string to OutputFormat enum
    // Defaults to plain if unrecognized
    const fmt: output.OutputFormat = if (std.mem.eql(u8, format_str, "json"))
        .json
    else if (std.mem.eql(u8, format_str, "csv"))
        .csv
    else
        .plain;

    // Execute appropriate mode
    // Choose between one-shot (runOnce) or daemon (runDaemon/runDaemonFile) based on flags
    if (daemon_mode) {
        if (output_file) |file| {
            // Daemon mode with file output: continuously update specified file
            // Useful for named pipes (e.g., rofi integration)
            try daemon.runDaemonFile(allocator, interval_ms, fmt, file);
        } else {
            // Daemon mode with stdout: continuous output at specified interval
            // Can be redirected to file/pipe: zigsysmon --daemon 500 > output.json
            try daemon.runDaemon(allocator, interval_ms, fmt);
        }
    } else {
        // One-shot mode: collect metrics once and exit
        // Default behavior, most common use case
        try daemon.runOnce(allocator, fmt);
    }
}

/// Print help message with usage, options, and integration examples
///
/// Outputs comprehensive documentation to stderr via std.debug.print.
/// Includes all command-line options, example invocations, and common integration
/// patterns for tools like rofi, jq, and monitoring systems.
///
/// This function does not return a value and is called when --help or -h is specified.
fn printHelp() void {
    std.debug.print(
        \\zigsysmon - Lightweight system monitor
        \\
        \\Usage:
        \\  zigsysmon [OPTIONS]
        \\
        \\Options:
        \\  --help, -h                Show this help message
        \\  --version, -v             Show version information
        \\  --daemon, -d MS           Run in daemon mode (updates every MS milliseconds)
        \\  --format, -f FORMAT       Output format: plain (default), json, csv
        \\  --output, -o FILE         Write output to FILE instead of stdout
        \\
        \\Examples:
        \\  zigsysmon                           # Single snapshot, plain text
        \\  zigsysmon --format json             # Single snapshot, JSON format
        \\  zigsysmon --daemon 1000             # Daemon mode, update every 1 second
        \\  zigsysmon -d 500 -f json -o /tmp/sys.json  # Daemon with custom settings
        \\
        \\Integration examples:
        \\  # Watch in real-time (using watch command)
        \\  watch -n 1 'zigsysmon'
        \\
        \\  # JSON output for tools like rofi
        \\  zigsysmon --format json | jq '.memory'
        \\
        \\  # CSV export for analysis
        \\  zigsysmon --format csv >> metrics.csv
        \\
    , .{});
}
