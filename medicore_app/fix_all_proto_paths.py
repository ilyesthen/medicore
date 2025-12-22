#!/usr/bin/env python3
"""
Fix ALL proto_types.dart import paths to use correct relative paths
"""

import re
from pathlib import Path

def get_correct_import_path(dart_file_path):
    """Calculate correct relative path from dart file to proto_types.dart"""
    # proto_types.dart is at: lib/src/core/types/proto_types.dart
    # Calculate depth from lib/src/
    
    parts = dart_file_path.parts
    
    # Find position of 'src' in path
    try:
        src_idx = parts.index('src')
    except ValueError:
        # File not in src/ - shouldn't happen
        return None
    
    # Count directories from current file back to src/
    depth = len(parts) - src_idx - 2  # -2 for 'src' and filename
    
    if depth < 0:
        depth = 0
    
    # Build relative path
    back = '../' * depth
    return f"{back}core/types/proto_types.dart"

def fix_file(filepath):
    """Fix import in a single file"""
    content = filepath.read_text()
    original = content
    
    # Get correct import path for this file
    correct_path = get_correct_import_path(filepath)
    if not correct_path:
        return False
    
    # Replace ANY import that mentions proto_types.dart
    content = re.sub(
        r"import '[^']*core/types/proto_types\.dart';",
        f"import '{correct_path}';",
        content
    )
    
    if content != original:
        filepath.write_text(content)
        print(f"✓ {filepath.relative_to(Path('lib'))}: {correct_path}")
        return True
    return False

def main():
    lib_dir = Path("lib")
    fixed = 0
    
    for dart_file in lib_dir.rglob("*.dart"):
        if '.g.dart' in str(dart_file) or '.pb.dart' in str(dart_file):
            continue
        
        if fix_file(dart_file):
            fixed += 1
    
    print(f"\n✅ Fixed {fixed} files")

if __name__ == '__main__':
    main()
