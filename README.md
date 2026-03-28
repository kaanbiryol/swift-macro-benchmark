# swift-macro-benchmark

Measures the compilation time overhead of Swift macros compared to hand-written code.

## Motivation

Swift macros expand at compile time. For a single usage the overhead is negligible, but in a large codebase with hundreds or thousands of macro invocations the cumulative cost can matter. This benchmark quantifies that cost across different scales.

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

The benchmark compiles six scenarios and compares wall-clock `swiftc` time using [hyperfine](https://github.com/sharkdp/hyperfine):

| Scenario | Description |
|---|---|
| Default | 1 file, 1 hand-written function |
| Macro | 1 file, 1 macro usage |
| Large Default | 1 file, N hand-written functions |
| Large Macro | 1 file, N macro usages |
| Multi-file Default | M files, K hand-written functions each |
| Multi-file Macro | M files, K macro usages each |

## Results

Measured on Apple M1 Pro, Swift 6.2, macOS. Default parameters: 2000 single-file modifiers, 100 files, 20 modifiers per file.

| Scenario | Mean | vs Hand-written |
|---|---|---|
| 1 file, 1 function (hand-written) | 181 ms | - |
| 1 file, 1 macro | 204 ms | +13% |
| 1 file, 2000 functions (hand-written) | 12.2 s | - |
| 1 file, 2000 macros | 21.6 s | +76% |
| 100 files x 20 functions (hand-written) | 9.9 s | - |
| 100 files x 20 macros | 14.1 s | +43% |

At small scale (single usage), macro overhead is minimal (~23 ms). At large scale, macros add 43-76% compilation time compared to equivalent hand-written code.

## Requirements

- macOS
- Swift 6.2+ toolchain
- [hyperfine](https://github.com/sharkdp/hyperfine) (`brew install hyperfine`)
- Python 3

## Usage

```bash
# Run with defaults (2000 single-file modifiers, 100 files, 20 modifiers per file)
./benchmark.sh

# Customize: ./benchmark.sh [single_file_modifiers] [num_files] [multi_file_modifiers]
./benchmark.sh 1000 50 10
```

The script:
1. Generates Swift source files via `generate_large_files.py`
2. Builds the macro plugin with `swift build -c release`
3. Runs `hyperfine` across all six scenarios
4. Exports results to `results.json`

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
