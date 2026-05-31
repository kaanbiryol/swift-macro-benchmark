# swift-macro-benchmark

Measures Swift macro overhead compared to equivalent hand-written code.

## Motivation

Swift macros expand during compilation. For a single usage the overhead is negligible, but in a large codebase with hundreds or thousands of macro invocations the cumulative cost can matter. This benchmark quantifies that cost across different scales.

## What It Benchmarks

The project includes a `@Modifier` peer macro that generates builder-pattern setter functions from property declarations:

```swift
// With macro
@Modifier private var isOutlined: Bool = false

// Expands to the equivalent hand-written code
public func IsOutlined(_ isOutlined: Bool) -> Self {
    var copy = self
    copy.isOutlined = isOutlined
    return copy
}
```

The benchmark runs six scenarios using [hyperfine](https://github.com/sharkdp/hyperfine):

| Scenario | Description |
|---|---|
| Default | 1 file, 1 hand-written function |
| Macro | 1 file, 1 macro usage |
| Large Default | 1 file, N hand-written functions |
| Large Macro | 1 file, N macro usages |
| Multi-file Default | M files, K hand-written functions each |
| Multi-file Macro | M files, K macro usages each |

Each scenario can be measured in two ways:

| Suite | Command shape | What it measures |
|---|---|---|
| Typecheck | `swiftc -typecheck -num-threads ...` | Expansion-focused frontend overhead without optimization, codegen, or linking |
| Compile | `swiftc -O ... -o` | Full optimized compile impact |

The typecheck suite is the default because it is the cleaner proxy for macro expansion overhead. The compile suite is useful secondary context when you want to know how much the macro changes full optimized build time.

## Results

These results were measured on May 31, 2026 on MacBookPro18,3 (Apple M1 Pro, 32 GB), Swift 6.3 (swiftlang-6.3.0.123.5), macOS 26.5. Default parameters: 2000 single-file modifiers, 100 files, 20 modifiers per file, 1 warmup, 3 measured runs, 8 Swift compiler threads.

### Typecheck

| Scenario | Mean | vs Hand-written |
|---|---:|---:|
| 1 file, 1 function (hand-written) | 121 ms | - |
| 1 file, 1 macro | 154 ms | +28% |
| 1 file, 2000 functions (hand-written) | 378 ms | - |
| 1 file, 2000 macros | 9.48 s | +2409% |
| 100 files x 20 functions (hand-written) | 5.18 s | - |
| 100 files x 20 macros | 8.32 s | +61% |

### Compile

| Scenario | Mean | vs Hand-written |
|---|---:|---:|
| 1 file, 1 function (hand-written) | 185 ms | - |
| 1 file, 1 macro | 208 ms | +12% |
| 1 file, 2000 functions (hand-written) | 7.81 s | - |
| 1 file, 2000 macros | 16.8 s | +114% |
| 100 files x 20 functions (hand-written) | 10.2 s | - |
| 100 files x 20 macros | 13.3 s | +30% |

At small scale (single usage), macro overhead is minimal: about 34 ms for typecheck and 23 ms for optimized compile. At large scale, 2000 single-file macros are much more expensive in the typecheck suite, while the multi-file macro case adds 61% typecheck time and 30% optimized compile time compared to equivalent hand-written code.

Rerun `./benchmark.sh --all` before quoting current numbers. The script exports an expansion-focused typecheck suite and a full optimized compile suite while keeping macro plugin flags out of hand-written baseline commands.

## Requirements

- macOS
- Swift 6.2+ toolchain
- [hyperfine](https://github.com/sharkdp/hyperfine) (`brew install hyperfine`)
- Python 3

## Usage

```bash
# Run the default expansion-focused typecheck benchmark
# Defaults: 2000 single-file modifiers, 100 files, 20 modifiers per file
./benchmark.sh

# Customize: ./benchmark.sh [mode] [single_file_modifiers] [num_files] [multi_file_modifiers]
./benchmark.sh 1000 50 10

# Run the full optimized compile benchmark
./benchmark.sh --compile

# Run both suites
./benchmark.sh --all

# Reduce or increase hyperfine repetitions
WARMUPS=3 RUNS=10 ./benchmark.sh --all

# Optional: match the compile-suite parallelism to your machine
CORES=10 ./benchmark.sh
```

The script:
1. Generates Swift source files via `generate_large_files.py`
2. Builds the macro plugin with `swift build -c release`
3. Runs the selected benchmark suite

The default `--typecheck` mode exports `results-typecheck.json`. The `--compile` mode exports `results-compile.json`. The `--all` mode exports both. For compatibility with earlier versions of this repo, `results.json` is also updated with the last selected suite; in `--all` mode, it mirrors the compile results.

## Project Structure

```
Sources/
  ModifierMacro/              # Macro declaration (@Modifier)
  ModifierMacroMacros/        # Macro implementation (PeerMacro)
benchmark/
  default/main.swift          # Baseline: 1 hand-written modifier
  macro/main.swift            # Macro: 1 @Modifier usage
  large_default/              # Generated: N hand-written modifiers
  large_macro/                # Generated: N @Modifier usages
  multi_file/                 # Generated: M files x K hand-written
  multi_file_macro/           # Generated: M files x K @Modifier
benchmark.sh                  # Orchestrates generation + hyperfine
generate_large_files.py       # Generates scaled test cases
```
