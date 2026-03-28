#!/usr/bin/env python3
import sys
import os

NUM_MODIFIERS = 2000
NUM_FILES = 100
MULTI_FILE_MODIFIERS = 20

def generate_large_default():
    content = """struct Button {
    private var title: String
"""
    
    # Generate properties
    for i in range(NUM_MODIFIERS):
        content += f"    private var modifier{i}: Double = 0.0\n"
    
    content += """
    public init(title: String) {
        self.title = title
    }
    
    // Manual modifier methods
"""
    
    # Generate modifier methods
    for i in range(NUM_MODIFIERS):
        content += f"""    public func modifier{i}(_ modifier{i}: Double) -> Self {{
        var copy = self
        copy.modifier{i} = modifier{i}
        return copy
    }}
    
"""
    
    content += """}
"""
    
    with open("benchmark/large_default/main.swift", "w") as f:
        f.write(content)

def generate_large_macro():
    content = """import ModifierMacro

struct Button {
    private var title: String
"""
    
    for i in range(NUM_MODIFIERS):
        content += f"    @Modifier private var modifier{i}: Double = 0.0\n"
    
    content += """    
    public init(title: String) {
        self.title = title
    }
}
"""
    
    with open("benchmark/large_macro/main.swift", "w") as f:
        f.write(content)

def generate_multi_file():
    """Generate N Swift files in multi_file directory, each with X manual modifier methods"""
    os.makedirs("benchmark/multi_file", exist_ok=True)
    
    for file_num in range(NUM_FILES):
        content = f"""struct Button{file_num} {{
    private var title: String
"""
        
        # Generate properties
        for i in range(MULTI_FILE_MODIFIERS):
            content += f"    private var modifier{i}: Double = 0.0\n"
        
        content += f"""
    public init(title: String) {{
        self.title = title
    }}
    
    // Manual modifier methods
"""
        
        # Generate modifier methods
        for i in range(MULTI_FILE_MODIFIERS):
            content += f"""    public func modifier{i}(_ modifier{i}: Double) -> Self {{
        var copy = self
        copy.modifier{i} = modifier{i}
        return copy
    }}
    
"""
        
        content += """}
"""
        
        # Name the first file main.swift for entry point
        filename = "main.swift" if file_num == 0 else f"Button{file_num}.swift"
        with open(f"benchmark/multi_file/{filename}", "w") as f:
            f.write(content)

def generate_multi_file_macro():
    """Generate N Swift files in multi_file_macro directory, each with X @Modifier properties"""
    os.makedirs("benchmark/multi_file_macro", exist_ok=True)
    
    for file_num in range(NUM_FILES):
        content = f"""import ModifierMacro

struct Button{file_num} {{
    private var title: String
"""
        
        for i in range(MULTI_FILE_MODIFIERS):
            content += f"    @Modifier private var modifier{i}: Double = 0.0\n"
        
        content += f"""    
    public init(title: String) {{
        self.title = title
    }}
}}
"""
        
        # Name the first file main.swift for entry point
        filename = "main.swift" if file_num == 0 else f"Button{file_num}.swift"
        with open(f"benchmark/multi_file_macro/{filename}", "w") as f:
            f.write(content)

if __name__ == "__main__":
    # Parse command line arguments
    if len(sys.argv) > 1:
        try:
            NUM_MODIFIERS = int(sys.argv[1])
        except ValueError:
            print("Error: Please provide a valid integer for the number of modifiers.")
            print("Usage: python3 generate_large_files.py [single_file_modifiers] [number_of_files] [multi_file_modifiers]")
            sys.exit(1)
    
    if len(sys.argv) > 2:
        try:
            NUM_FILES = int(sys.argv[2])
        except ValueError:
            print("Error: Please provide a valid integer for the number of files.")
            print("Usage: python3 generate_large_files.py [single_file_modifiers] [number_of_files] [multi_file_modifiers]")
            sys.exit(1)
    
    if len(sys.argv) > 3:
        try:
            MULTI_FILE_MODIFIERS = int(sys.argv[3])
        except ValueError:
            print("Error: Please provide a valid integer for the number of multi-file modifiers.")
            print("Usage: python3 generate_large_files.py [single_file_modifiers] [number_of_files] [multi_file_modifiers]")
            sys.exit(1)
    
    print(f"Generating large_default with {NUM_MODIFIERS} properties and manual methods...")
    generate_large_default()
    print(f"Generating large_macro with {NUM_MODIFIERS} @Modifier properties...")
    generate_large_macro()
    print(f"Generating {NUM_FILES} files in multi_file with {MULTI_FILE_MODIFIERS} manual methods each...")
    generate_multi_file()
    print(f"Generating {NUM_FILES} files in multi_file_macro with {MULTI_FILE_MODIFIERS} @Modifier properties each...")
    generate_multi_file_macro()
    print("Done! All files generated successfully.") 
