#!/usr/bin/env python3
"""
Auto-fix all import statements to use protobuf types instead of deleted database types
"""

import os
import re
from pathlib import Path

# The import we need to add
PROTOBUF_IMPORT = "import '../../../core/generated/medicore.pb.dart';"

# Files to process
lib_dir = Path("lib")

# Types that come from protobuf
PROTO_TYPES = [
    'Patient', 'Visit', 'Room', 'Message', 'WaitingPatient',
    'Appointment', 'SurgeryPlan', 'MedicalAct', 'Medication',
    'OrdonnanceDocument', 'Payment', 'MessageTemplate', 'User'
]

def count_back_dirs(file_path):
    """Count how many '../' needed to reach lib/src/core/generated/"""
    parts = file_path.relative_to(lib_dir).parts
    # Remove filename
    depth = len(parts) - 1
    # We need to go back to lib/src/core/generated
    if parts[0] == 'src':
        depth -= 1  # Already in src
    return depth

def get_correct_import(file_path):
    """Get the correct relative import path"""
    depth = count_back_dirs(file_path)
    back = '../' * depth
    return f"import '{back}core/generated/medicore.pb.dart';"

def needs_protobuf_import(content):
    """Check if file uses protobuf types but doesn't import them"""
    # Check if already has the import
    if 'medicore.pb.dart' in content:
        return False
    
    # Check if uses any proto types
    for ptype in PROTO_TYPES:
        # Look for type declarations, not just the word
        if re.search(rf'\b{ptype}\b', content):
            return True
    
    return False

def add_import_to_file(file_path):
    """Add protobuf import to file if needed"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if not needs_protobuf_import(content):
        return False
    
    # Find the last import statement
    import_lines = []
    other_lines = []
    in_imports = True
    
    for line in content.split('\n'):
        if in_imports and line.strip().startswith('import '):
            import_lines.append(line)
        else:
            if in_imports and line.strip() and not line.strip().startswith('import '):
                in_imports = False
            other_lines.append(line)
    
    # Add our import
    correct_import = get_correct_import(file_path)
    if correct_import not in import_lines:
        import_lines.append(correct_import)
    
    # Reconstruct file
    new_content = '\n'.join(import_lines) + '\n' + '\n'.join(other_lines)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    return True

def main():
    """Process all Dart files"""
    fixed_count = 0
    
    for dart_file in lib_dir.rglob('*.dart'):
        # Skip generated files
        if '.g.dart' in str(dart_file) or '.pb.dart' in str(dart_file):
            continue
        
        try:
            if add_import_to_file(dart_file):
                print(f"✓ Fixed: {dart_file}")
                fixed_count += 1
        except Exception as e:
            print(f"✗ Error in {dart_file}: {e}")
    
    print(f"\n✅ Fixed {fixed_count} files")

if __name__ == '__main__':
    main()
