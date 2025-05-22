# Package

version       = "0.0.0"
author        = "jasagiri"
description   = "Operational Transformation library for Nim"
license       = "MIT"
srcDir        = "src"
skipDirs      = @["tests", "vendor", "docs", "backups"]

# Dependencies

requires "nim >= 1.6.0"
requires "results >= 0.3.0"
requires "chronos >= 3.0.0"

# Tasks

task test, "Run tests":
  # Use nimcache in the current directory to avoid permission issues
  exec "nim c -r --nimcache:./nimcache tests/test_all"

task benchmark, "Run benchmarks":
  exec "nim c -d:release -r --nimcache:./nimcache benchmarks/bench_all"

task docs, "Generate documentation":
  exec "nim doc --project --index:on --outdir:htmldocs src/nim_lib_ot_core.nim"

# Add clean task
task clean, "Clean build artifacts":
  exec "rm -rf nimcache htmldocs"
  echo "Cleaned build artifacts"
