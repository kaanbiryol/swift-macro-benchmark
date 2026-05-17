#!/bin/bash

set -euo pipefail

SINGLE_FILE_MODIFIERS=2000
NUM_FILES=100
MULTI_FILE_MODIFIERS=20
WARMUPS=${WARMUPS:-1}
RUNS=${RUNS:-3}
MODE=typecheck

usage() {
    cat <<EOF
Usage: ./benchmark.sh [--typecheck|--compile|--all] [single_file_modifiers] [num_files] [multi_file_modifiers]

Modes:
  --typecheck  Run expansion-focused typecheck benchmark (default)
  --compile    Run full optimized compile benchmark
  --all        Run both benchmark suites

Environment:
  WARMUPS      hyperfine warmup runs (default: 1)
  RUNS         hyperfine measured runs (default: 3)
  CORES        swiftc -num-threads value (default: 8)
EOF
}

positionals=()
for arg in "$@"; do
    case "$arg" in
        --typecheck)
            MODE=typecheck
            ;;
        --compile)
            MODE=compile
            ;;
        --all)
            MODE=all
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --*)
            echo "Unknown option: $arg" >&2
            usage >&2
            exit 1
            ;;
        *)
            positionals+=("$arg")
            ;;
    esac
done

if [[ ${#positionals[@]} -gt 3 ]]; then
    echo "Too many positional arguments." >&2
    usage >&2
    exit 1
fi

if [[ ${#positionals[@]} -ge 1 ]]; then
    SINGLE_FILE_MODIFIERS=${positionals[0]}
fi

if [[ ${#positionals[@]} -ge 2 ]]; then
    NUM_FILES=${positionals[1]}
fi

if [[ ${#positionals[@]} -ge 3 ]]; then
    MULTI_FILE_MODIFIERS=${positionals[2]}
fi

rm -rf benchmark/large_macro/*.swift
rm -rf benchmark/multi_file/*.swift
rm -rf benchmark/multi_file_macro/*.swift
rm -rf benchmark/large_default/*.swift

mkdir -p benchmark/large_macro
mkdir -p benchmark/multi_file
mkdir -p benchmark/multi_file_macro
mkdir -p benchmark/large_default

python3 generate_large_files.py "$SINGLE_FILE_MODIFIERS" "$NUM_FILES" "$MULTI_FILE_MODIFIERS"

swift build -c release --target ModifierMacro

export CORES=${CORES:-8}
export ARCH_PATH
ARCH_PATH=$(swift build -c release --show-bin-path)
export MOD_PATH=$ARCH_PATH/Modules
export PLUGIN_PATH=$ARCH_PATH/ModifierMacroMacros-tool#ModifierMacroMacros

generate_typecheck_cmd() {
    local input_files="$1"
    local uses_macro="$2"

    if [[ "$uses_macro" == "true" ]]; then
        echo "swiftc -load-plugin-executable \"$PLUGIN_PATH\" -I \"$MOD_PATH\" -typecheck -num-threads $CORES $input_files"
    else
        echo "swiftc -typecheck -num-threads $CORES $input_files"
    fi
}

generate_compile_cmd() {
    local input_files="$1"
    local output_name="$2"
    local uses_macro="$3"

    if [[ "$uses_macro" == "true" ]]; then
        echo "swiftc -load-plugin-executable \"$PLUGIN_PATH\" -I \"$MOD_PATH\" -O -num-threads $CORES $input_files -o .build/$output_name"
    else
        echo "swiftc -O -num-threads $CORES $input_files -o .build/$output_name"
    fi
}

test_names=(
    "default"
    "macro"
    "large_default"
    "large_macro"
    "multi_file"
    "multi_file_macro"
)

display_names=(
    "Default (1 file, 1 function definition)"
    "Macro (1 file, 1 macro usage)"
    "Large Default (1 file, $SINGLE_FILE_MODIFIERS function definitions)"
    "Large Macro (1 file, $SINGLE_FILE_MODIFIERS macro usages)"
    "Multi-file Default ($NUM_FILES files, $MULTI_FILE_MODIFIERS function definitions each)"
    "Multi-file Macro ($NUM_FILES files, $MULTI_FILE_MODIFIERS macro usages each)"
)

test_inputs=(
    "benchmark/default/main.swift"
    "benchmark/macro/main.swift"
    "benchmark/large_default/main.swift"
    "benchmark/large_macro/*.swift"
    "benchmark/multi_file/*.swift"
    "benchmark/multi_file_macro/*.swift"
)

uses_macros=(
    "false"
    "true"
    "false"
    "true"
    "false"
    "true"
)

typecheck_args=()
compile_args=()

for i in "${!test_names[@]}"; do
    name="${test_names[$i]}"
    display_name="${display_names[$i]}"
    input_files="${test_inputs[$i]}"
    uses_macro="${uses_macros[$i]}"

    typecheck_command=$(generate_typecheck_cmd "$input_files" "$uses_macro")
    compile_command=$(generate_compile_cmd "$input_files" "${name}_test" "$uses_macro")

    typecheck_args+=("-n" "$display_name" "$typecheck_command")
    compile_args+=("-n" "$display_name" "$compile_command")
done

run_typecheck_benchmark() {
    echo "Running expansion-focused typecheck benchmark..."
    hyperfine -w "$WARMUPS" -r "$RUNS" --export-json results-typecheck.json "${typecheck_args[@]}"
}

run_compile_benchmark() {
    echo "Running full optimized compile benchmark..."
    hyperfine -w "$WARMUPS" -r "$RUNS" --show-output --export-json results-compile.json "${compile_args[@]}"
}

case "$MODE" in
    typecheck)
        run_typecheck_benchmark
        cp results-typecheck.json results.json
        ;;
    compile)
        run_compile_benchmark
        cp results-compile.json results.json
        ;;
    all)
        run_typecheck_benchmark
        run_compile_benchmark
        cp results-compile.json results.json
        ;;
esac
