#!/bin/bash

SINGLE_FILE_MODIFIERS=2000
NUM_FILES=100
MULTI_FILE_MODIFIERS=20

if [[ $# -ge 1 ]]; then
    SINGLE_FILE_MODIFIERS=$1
fi

if [[ $# -ge 2 ]]; then
    NUM_FILES=$2
fi

if [[ $# -ge 3 ]]; then
    MULTI_FILE_MODIFIERS=$3
fi

rm -rf benchmark/large_macro/*.swift
rm -rf benchmark/multi_file/*.swift
rm -rf benchmark/multi_file_macro/*.swift
rm -rf benchmark/large_default/*.swift

 
mkdir -p benchmark/large_macro
mkdir -p benchmark/multi_file
mkdir -p benchmark/multi_file_macro
mkdir -p benchmark/large_default

python3 generate_large_files.py $SINGLE_FILE_MODIFIERS $NUM_FILES $MULTI_FILE_MODIFIERS

swift build -c release --target ModifierMacro

export CORES=8
export ARCH_PATH=.build/arm64-apple-macosx/release
export MOD_PATH=$ARCH_PATH/Modules
export PLUGIN_PATH=$ARCH_PATH/ModifierMacroMacros-tool#ModifierMacroMacros

generate_swiftc_cmd() {
    local input_files="$1"
    local output_name="$2"
    echo "swiftc -load-plugin-executable \"$PLUGIN_PATH\" -I \"$MOD_PATH\" -O -num-threads $CORES $input_files -o .build/$output_name"
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

hyperfine_args=()
for i in "${!test_names[@]}"; do
    name="${test_names[$i]}"
    display_name="${display_names[$i]}"
    input_files="${test_inputs[$i]}"
    output_name="${name}_test"
    command=$(generate_swiftc_cmd "$input_files" "$output_name")
    
    hyperfine_args+=("-n" "$display_name" "$command")
done

hyperfine -w 1 -r 2 --show-output --export-json results.json "${hyperfine_args[@]}"