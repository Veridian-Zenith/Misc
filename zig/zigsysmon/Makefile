# Build configuration
# Standard LLVM/Clang toolchain variables (from config.fish)
CC ?= clang
CXX ?= clang++
LD ?= ld.lld
AR ?= llvm-ar
NM ?= llvm-nm
STRIP ?= llvm-strip
OBJCOPY ?= llvm-objcopy
OBJDUMP ?= llvm-objdump
READELF ?= llvm-readelf
AS ?= clang
HOSTCC ?= clang
HOSTCXX ?= clang++

# Compiler flags with optimization and hardening
CFLAGS ?= -march=native -O3 -pipe -fno-plt \
	-Wno-unused-variable -Wno-unused-parameter -Wno-unused-function \
	-Wno-unused-but-set-variable -Wno-missing-field-initializers \
	-Wno-sign-compare -Wno-unused-result
CXXFLAGS ?= $(CFLAGS)
LDFLAGS ?= -fuse-ld=mold -Wl,-O1,--as-needed,-z,relro,-z,now
CPPFLAGS ?= -D_FORTIFY_SOURCE=3
LTOFLAGS ?= -flto=thin

# Build system flags
MAKEFLAGS ?= -s
NINJA_STATUS ?=

# Zig-specific options
ZIG ?= zig
ZIG_BUILD_MODE ?= Debug
ZIG_OPTIMIZE ?=
ZIG_STRIP ?= false

# Internal variables
.PHONY: build debug release test run check clean help

help:
	@echo "zigsysmon - Lightweight system monitor"
	@echo ""
	@echo "Available targets:"
	@echo "  make build        Build in Debug mode (default)"
	@echo "  make debug        Same as build"
	@echo "  make release      Build optimized ReleaseFast binary"
	@echo "  make test         Run unit and integration tests"
	@echo "  make run          Build (Debug) and execute"
	@echo "  make check        Quick syntax/type check (Debug)"
	@echo "  make clean        Remove build artifacts"
	@echo ""
	@echo "LLVM/Clang Toolchain Variables:"
	@echo "  CC                C compiler (default: clang)"
	@echo "  CXX               C++ compiler (default: clang++)"
	@echo "  LD                Linker (default: ld.lld)"
	@echo "  AR                Archiver (default: llvm-ar)"
	@echo "  NM                Symbol lister (default: llvm-nm)"
	@echo "  STRIP             Strip utility (default: llvm-strip)"
	@echo "  OBJCOPY           Object copier (default: llvm-objcopy)"
	@echo "  OBJDUMP           Object dumper (default: llvm-objdump)"
	@echo "  READELF           ELF reader (default: llvm-readelf)"
	@echo "  AS                Assembler (default: clang)"
	@echo "  HOSTCC            Host C compiler (default: clang)"
	@echo "  HOSTCXX           Host C++ compiler (default: clang++)"
	@echo ""
	@echo "Compiler Flags:"
	@echo "  CFLAGS            C flags (-march=native -O3 -pipe -fno-plt + warnings)"
	@echo "  CXXFLAGS          C++ flags (same as CFLAGS)"
	@echo "  LDFLAGS           Linker flags (-fuse-ld=mold -Wl,-O1,--as-needed,-z,relro,-z,now)"
	@echo "  CPPFLAGS          Preprocessor flags (-D_FORTIFY_SOURCE=3)"
	@echo "  LTOFLAGS          LTO flags (-flto=thin)"
	@echo ""
	@echo "Zig-specific Options:"
	@echo "  ZIG               Zig compiler path (default: zig)"
	@echo "  ZIG_OPTIMIZE      Optimize mode: Debug, ReleaseSafe, ReleaseFast, ReleaseSmall"
	@echo "  ZIG_STRIP         Strip binary: true/false (default: false)"
	@echo ""
	@echo "Build System Flags:"
	@echo "  MAKEFLAGS         Make flags (default: -s for silent)"
	@echo "  NINJA_STATUS      Ninja status format (default: empty)"
	@echo ""
	@echo "Examples:"
	@echo "  make run          # Quick test run"
	@echo "  make release      # Production build with optimizations"
	@echo "  make test         # Run full test suite"
	@echo "  make clean && make release  # Clean build, optimized"
	@echo ""
	@echo "Config from ~/.config/fish/config.fish is automatically used."
	@echo "Override with: make CC=gcc CFLAGS='-O2' build"
	@echo ""

build debug:
	$(ZIG) build

release:
	$(ZIG) build -Doptimize=ReleaseFast

test:
	$(ZIG) build test

run: build
	./zig-out/bin/zigsysmon

check:
	$(ZIG) build check

clean:
	rm -rf zig-cache zig-out
