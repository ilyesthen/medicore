#!/usr/bin/env python3
"""
Replace all medicore.pb.dart imports with proto_types.dart
"""

import re
from pathlib import Path

def fix_file(filepath):
    """Fix imports in a single file"""
    content = filepath.read_text()
    original = content
    
    # Replace medicore.pb.dart with proto_types.dart (keeping same path depth)
    content = re.sub(
        r"import '(\.\./)*(core/generated/medicore\.pb\.dart)';",
        lambda m: f"import '{m.group(1) or ''}core/types/proto_types.dart';",
        content
    )
    
    if content != original:
        filepath.write_text(content)
        return True
    return False

def main():
    lib_dir = Path("lib")
    fixed = 0
    
    for dart_file in lib_dir.rglob("*.dart"):
        if '.g.dart' in str(dart_file) or '.pb.dart' in str(dart_file):
            continue
        
        if fix_file(dart_file):
            print(f"✓ {dart_file.relative_to(lib_dir)}")
            fixed += 1
    
    print(f"\n✅ Fixed {fixed} files")

if __name__ == '__main__':
    main()
