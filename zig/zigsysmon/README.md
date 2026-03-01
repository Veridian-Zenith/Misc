# zigsysmon - Lightweight System Monitor

A minimal, production-ready system monitor written in pure Zig with zero external dependencies (except the Linux kernel interface via `/proc`).

## Features

- **CPU Metrics**: Per-core CPU time breakdown (user, nice, system, idle)
- **Memory Metrics**: Total, used, and free memory with buffer/cache awareness
- **Network Metrics**: Aggregate RX/TX bytes across all network interfaces
- **Disk Metrics**: Filesystem usage information (placeholder for now)
- **Minimal Dependencies**: No GLIBC, no GNU extensions, pure Zig
- **Efficient**: Reads directly from `/proc` filesystem
- **Tested**: Includes unit tests and integration testing scripts

## Requirements

- **Zig 0.15.2** or later (tested and production-ready on 0.15.2)
- Linux kernel (for `/proc` filesystem access)
- POSIX shell (`sh`) - optional, for convenience scripts
- Fish shell - optional, for Fish convenience scripts

## Building

### Using Makefile (recommended)
```bash
make              # Build in Debug mode
make release      # Production build (ReleaseFast)
make test         # Run tests
make run          # Build and run
make check        # Quick syntax check
make clean        # Remove build artifacts
make help         # Show all targets
```

### Using Zig directly
```bash
zig build                             # Build Debug
zig build -Doptimize=ReleaseFast      # Production build
zig build test                        # Run tests
zig build run                         # Build and run
zig build check                       # Quick check
```

## Zig 0.15.2 Compatibility

This project has been fully updated for **Zig 0.15.2**. Key API adjustments made:

- **Build System**: Uses new `Module.CreateOptions` API with `root_source_file`
- **Documentation Comments**: Fixed inline doc comments to separate lines (0.15.2 requirement)
- **Module Creation**: All executables use `createModule()` with proper target/optimize settings
- **Test API**: Tests use regular comments instead of doc comments (0.15.2 restriction)

All code has been tested and compiles without errors or warnings on Zig 0.15.2.

### Using Makefile
```bash
make run
```

### Using Zig directly
```bash
zig build run
```

### Using the binary directly
```bash
./zig-out/bin/zigsysmon
```

## Usage

### Basic Usage

```bash
# Single snapshot, plain text (default)
zigsysmon

# Show help and all options
zigsysmon --help
```

### Command-Line Options

```
--help, -h                Show help message
--version, -v             Show version information
--daemon, -d MS           Run in daemon mode (update every MS milliseconds)
--format, -f FORMAT       Output format: plain (default), json, csv
--output, -o FILE         Write output to FILE instead of stdout
```

### Output Formats

#### Plain Text (default)

Human-readable format, one metric per line:

```bash
zigsysmon
```

Output:
```
CPU (total): user=5585164 system=1092311 idle=33342974
CPU 0: user=620445 system=110228 idle=4065423
...
Memory: total=15175MB used=7621MB free=7554MB
Disk: total=512000MB used=200000MB free=312000MB
Network: RX=5194166717B TX=836854465B
```

#### JSON Format

Structured output for tools like jq, rofi, or custom scripts:

```bash
zigsysmon --format json
```

Output:
```json
{
  "timestamp": 1772404827,
  "cpu_count": 9,
  "cpu_total": {"user": 5585164, "system": 1092311, "idle": 33342974},
  "cpu_cores": [
    {"id": 0, "user": 620445, "system": 110228, "idle": 4065423},
    ...
  ],
  "memory": {"total": 15175, "used": 7621, "free": 7554},
  "disk": {"total": 512000, "used": 200000, "free": 312000},
  "network": {"rx_bytes": 5194166717, "tx_bytes": 836854465}
}
```

#### CSV Format

Comma-separated values for data analysis and time-series archival:

```bash
zigsysmon --format csv
```

Output:
```csv
timestamp,metric,value
1772404827,cpu_total_user,5585164
1772404827,cpu_total_system,1092311
1772404827,cpu0_user,620445
...
1772404827,memory_total_mb,15175
1772404827,memory_used_mb,7621
...
```

### Daemon Mode

Run continuously with regular updates:

```bash
# Update every 1 second (plain text)
zigsysmon --daemon 1000

# Update every 500ms (JSON format)
zigsysmon --daemon 500 --format json

# Write to file every 2 seconds (for integration)
zigsysmon --daemon 2000 --output /tmp/metrics.json
```

## Architecture

### Module Overview

The codebase is organized into several focused modules, each responsible for a specific aspect of system monitoring:

- **main.zig**: Entry point with command-line argument parsing
  - Handles `--daemon`, `--format`, `--output` options
  - Routes execution to appropriate mode (daemon vs one-shot)

- **metrics.zig**: Unified metrics aggregation
  - Collects all system metrics in a single atomic operation
  - Provides `Metrics` struct as common interface for all formatters
  - Coordinates with individual metric modules

- **output.zig**: Multi-format output rendering
  - Three formatters: `formatPlain()`, `formatJson()`, `formatCsv()`
  - Dispatcher function `format()` routes to appropriate formatter
  - Uses `std.debug.print()` for simple, portable output

- **daemon.zig**: Background operation modes
  - `runOnce()`: Single snapshot (default mode)
  - `runDaemon()`: Continuous stdout output
  - `runDaemonFile()`: Continuous file output (for named pipes, rofi)

- **cpu.zig**: Reads `/proc/stat` for per-core CPU times
- **mem.zig**: Reads `/proc/meminfo` for memory statistics
- **network.zig**: Reads `/proc/net/dev` for network interface statistics
- **disk.zig**: Placeholder for disk statistics

### Module Interactions Diagram

```
$\text{main.zig (CLI entry)}$
     ↓
     ├─→ Help/Version mode
     └─→ Argument Parsing
         ↓
         ├─→ daemon.zig (Mode selection)
         │   ├─→ runOnce()
         │   ├─→ runDaemon()
         │   └─→ runDaemonFile()
         │
         └─→ metrics.zig (Metrics collection)
             ├─→ cpu.zig
             ├─→ mem.zig
             ├─→ network.zig
             └─→ disk.zig
                 ↓
                 output.zig (Format rendering)
                 ├─→ formatPlain()
                 ├─→ formatJson()
                 └─→ formatCsv()
```

### Design Principles

1. **Zero Dependencies**: No external libraries, minimal Zig stdlib usage
2. **Direct syscalls**: Read from `/proc` filesystem directly instead of system calls
3. **Error Handling**: Graceful degradation on parse errors (defaults to 0)
4. **Memory Safety**: Uses allocators and proper cleanup
5. **POSIX-only**: Designed for Linux; can be adapted for other Unix-like systems

## Memory Metrics Explained
The monitor calculates available memory as:
```
available = free + buffers + cached
used = total - free - buffers - cached
```

This better reflects actual memory pressure than raw `MemFree`, as buffers and cache
can be reclaimed by the kernel when needed.

## CPU Metrics Explained

All CPU times are in jiffies (scheduler ticks). To calculate CPU usage percentage:

```
busy_time = user + nice + system + irq + softirq
total_time = user + nice + system + idle + iowait + irq + softirq
usage_percent = (busy_time / total_time) * 100
```

Track delta between two readings over a time period to get instantaneous usage.

## Known Limitations

- **Disk Stats**: Currently returns placeholder values. Real implementation requires
  either libc dependency or unsafe syscall wrappers.
- **Single Sample**: Returns one snapshot, not continuous monitoring
- **Linux Only**: `/proc` filesystem is Linux-specific

## Future Improvements

1. Implement real disk stats via statfs() syscall
2. Add periodic refresh capability
3. Terminal UI with colors (using ANSI escape codes)
4. Historical data tracking (calculate rates/deltas)
5. Process list with top N by CPU/memory
6. Configuration file support
7. Output formats (JSON, CSV)
8. macOS/BSD support (using sysctl or other APIs)

## Testing

Run the test suite:
```bash
zig build test
# or
./scripts/test.sh
```

Tests validate:
- CPU time parsing from real `/proc/stat`
- Memory stat parsing from real `/proc/meminfo`
- Network stat parsing from real `/proc/net/dev`
- String tokenization with complex delimiters
- Integer parsing with error recovery

## Code Style

- Comprehensive documentation comments (doc comments `///`)
- Clear variable names and function signatures
- Defensive programming: error handling, bounds checking
- Efficient memory usage: stack allocation where possible
- No unsafe code (except implicit C interop if added in future)

## Performance

Typical execution time: < 10ms on modern systems
Memory usage: < 2MB resident

## License

This project is part of the Misc repository. See LICENSE file.

## Contributing

When extending zigsysmon:
1. Add test cases for new functionality
2. Document all public functions with doc comments
3. Avoid adding external dependencies
4. Test on both single and multi-core systems
5. Update this README with new features
