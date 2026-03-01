const std = @import("std");

/// Disk/filesystem statistics structure
/// Reports disk usage in megabytes (MB)
pub const DiskStats = struct {
    /// Total filesystem capacity (MB)
    total: u64,
    /// Currently used disk space (MB)
    used: u64,
    /// Available free space (MB)
    free: u64,
};

/// Read disk statistics for the root filesystem
///
/// Note: Fetching accurate disk stats on Linux requires calling the statfs(2)
/// syscall directly. Without libc, this would require inline assembly or unsafe
/// syscall wrappers. For now, this returns placeholder values.
///
/// Future improvement: Use unsafe syscall wrappers or asm for statfs() call.
///
/// Args:
///   _allocator: Memory allocator (unused, kept for interface consistency)
///
/// Returns:
///   DiskStats struct with values in megabytes (currently placeholder)
pub fn getDiskStats(_allocator: std.mem.Allocator) !DiskStats {
    _ = _allocator;

    // TODO: Implement real disk stats using statfs() syscall
    // This would require either:
    // 1. Unsafe inline syscall (most efficient)
    // 2. Optional libc dependency
    // 3. Reading from /proc or other Linux-specific sources

    return DiskStats{
        .total = 512_000, // Placeholder
        .used = 200_000, // Placeholder
        .free = 312_000, // Placeholder
    };
}
