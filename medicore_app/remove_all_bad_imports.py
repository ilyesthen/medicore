#!/usr/bin/env python3
"""
Remove ALL imports to deleted database and repository files
"""

import os
import re
from pathlib import Path

lib_dir = Path("lib")

def should_remove_import(line):
    """Check if this import line should be removed"""
    if not line.strip().startswith('import '):
        return False
    
    # Remove any import containing these patterns (deleted repos)
    bad_patterns = [
        '/data/users_repository.dart',
        '/data/patients_repository.dart',
        '/data/rooms_repository.dart',
        '/data/messages_repository.dart',
        '/data/message_templates_repository.dart',
        '/data/waiting_queue_repository.dart',
        '/data/appointments_repository.dart',
        '/data/surgery_plans_repository.dart',
        '/data/visits_repository.dart',
        '/data/ordonnances_repository.dart',
        '/data/medications_repository.dart',
        '/data/medical_acts_repository.dart',
        '/data/payments_repository.dart',
        '/data/nurse_preferences_repository.dart',
        'app_database.dart',
        'package:drift/drift.dart',
    ]
    
    for pattern in bad_patterns:
        if pattern in line:
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
                print(f"✓ {dart_file.name} ({removed} removed)")
                files_fixed += 1
                total_removed += removed
        except Exception as e:
            print(f"✗ Error in {dart_file}: {e}")
    
    print(f"\n✅ Fixed {files_fixed} files, removed {total_removed} imports total")

if __name__ == '__main__':
    main()
