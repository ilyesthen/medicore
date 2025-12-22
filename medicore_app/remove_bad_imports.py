#!/usr/bin/env python3
"""
Remove all imports to deleted database and repository files
"""

import os
import re
from pathlib import Path

lib_dir = Path("lib")

# Files that were deleted - any import to these should be removed
DELETED_FILES = [
    'core/database/app_database.dart',
    'features/users/data/nurse_preferences_repository.dart',
    'features/users/data/users_repository.dart',
    'features/patients/data/patients_repository.dart',
    'features/rooms/data/rooms_repository.dart',
    'features/messages/data/messages_repository.dart',
    'features/messages/data/message_templates_repository.dart',
    'features/waiting_queue/data/waiting_queue_repository.dart',
    'features/appointments/data/appointments_repository.dart',
    'features/surgery_planning/data/surgery_plans_repository.dart',
    'features/visits/data/visits_repository.dart',
    'features/ordonnance/data/ordonnances_repository.dart',
    'features/ordonnance/data/medications_repository.dart',
    'features/honoraires/data/medical_acts_repository.dart',
    'features/comptabilite/data/payments_repository.dart',
]

# Also remove package imports we don't use anymore
BAD_PACKAGES = [
    'package:drift/drift.dart',
]

def should_remove_import(line):
    """Check if this import line should be removed"""
    if not line.strip().startswith('import '):
        return False
    
    # Check if it imports a deleted file
    for deleted in DELETED_FILES:
        if deleted in line:
            return True
    
    # Check if it imports a bad package
    for bad_pkg in BAD_PACKAGES:
        if bad_pkg in line:
            return True
    
    return False

def clean_file(file_path):
    """Remove bad imports from file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    new_lines = []
    removed_count = 0
    
    for line in lines:
        if should_remove_import(line):
            print(f"  Removing: {line.strip()}")
            removed_count += 1
        else:
            new_lines.append(line)
    
    if removed_count > 0:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        return removed_count
    
    return 0

def main():
    """Process all Dart files"""
    total_removed = 0
    files_fixed = 0
    
    for dart_file in lib_dir.rglob('*.dart'):
        # Skip generated files
        if '.g.dart' in str(dart_file) or '.pb.dart' in str(dart_file):
            continue
        
        try:
            removed = clean_file(dart_file)
            if removed > 0:
                print(f"✓ Fixed: {dart_file} ({removed} imports removed)")
                files_fixed += 1
                total_removed += removed
        except Exception as e:
            print(f"✗ Error in {dart_file}: {e}")
    
    print(f"\n✅ Fixed {files_fixed} files, removed {total_removed} bad imports")

if __name__ == '__main__':
    main()
