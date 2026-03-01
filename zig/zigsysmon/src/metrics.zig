//! Metrics aggregation module
//!
//! Provides a unified interface to collect all system metrics in a single atomic
//! operation. This module coordinates with individual metric modules (cpu, mem, disk,
//! network) to build a complete system snapshot with timestamp.
//!
//! The Metrics struct is the primary data structure passed to output formatters.

const std = @import("std");
const cpu = @import("cpu.zig");
const mem = @import("mem.zig");
const disk = @import("disk.zig");
const network = @import("network.zig");

/// Complete system metrics snapshot with timestamp
///
/// Contains all system metrics collected at a specific point in time.
/// The timestamp is obtained from CLOCK_REALTIME for correlation with other
/// system events. Individual metric types are defined in their respective modules.
pub const Metrics = struct {
    /// CPU metrics
    cpu_times: []cpu.CpuTime,
    /// Memory metrics
    memory: mem.MemStats,
    /// Disk metrics
    disk: disk.DiskStats,
    /// Network metrics
    network: network.NetStats,
    /// Timestamp of snapshot
    timestamp: i64,

    /// Free allocated CPU times
    pub fn deinit(self: Metrics, allocator: std.mem.Allocator) void {
        allocator.free(self.cpu_times);
    }
};

/// Atomically collect all system metrics into a single snapshot
///
/// This function gathers metrics from all sources in sequence:
/// 1. CPU times from /proc/stat
/// 2. Memory stats from /proc/meminfo
/// 3. Disk stats from /proc/diskstats (placeholder)
/// 4. Network stats from /proc/net/dev
/// 5. System timestamp from CLOCK_REALTIME
///
/// All metrics components share the same timestamp, ensuring temporal consistency
/// for analysis and correlation.
///
/// Note: The CPU times slice is allocated and must be freed via deinit().
pub fn collect(allocator: std.mem.Allocator) !Metrics {
    const cpu_times = try cpu.getCpuTimes(allocator);
    const memory = try mem.getMemStats(allocator);
    const disk_stats = try disk.getDiskStats(allocator);
    const net_stats = try network.getNetStats(allocator);

    // Get current timestamp in seconds
    const ts = try std.posix.clock_gettime(std.posix.CLOCK.REALTIME);
    const timestamp = ts.sec;

    return Metrics{
        .cpu_times = cpu_times,
        .memory = memory,
        .disk = disk_stats,
        .network = net_stats,
        .timestamp = timestamp,
    };
}
