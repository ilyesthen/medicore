#!/usr/bin/env python3
"""
Comprehensive fix for all repository and type issues
"""

import re
from pathlib import Path

def fix_rooms_provider():
    """Fix rooms_provider.dart - remove RoomsRepository, use only Remote"""
    file = Path("lib/src/features/rooms/presentation/rooms_provider.dart")
    content = file.read_text()
    
    # Remove LocalRoomsAdapter class entirely (lines 15-35)
    content = re.sub(
        r'/// Local rooms adapter\nclass LocalRoomsAdapter implements IRoomsRepository \{[\s\S]*?\n\}',
        '',
        content
    )
    
    # Fix the provider to use RemoteRoomsRepository directly
    content = re.sub(
        r'final roomsRepositoryProvider = Provider<IRoomsRepository>\(\(ref\) \{[\s\S]*?\}\);',
        '''final roomsRepositoryProvider = Provider<RemoteRoomsRepository>((ref) {
  return RemoteRoomsRepository(ref.read(grpcClientProvider));
});''',
        content
    )
    
    file.write_text(content)
    print("✓ Fixed rooms_provider.dart")

def fix_patients_provider():
    """Fix patients_provider.dart - remove PatientsRepository, use only Remote"""
    file = Path("lib/src/features/patients/presentation/patients_provider.dart")
    content = file.read_text()
    
    # Remove LocalPatientsAdapter class
    content = re.sub(
        r'/// Local patients adapter[\s\S]*?class LocalPatientsAdapter implements IPatientsRepository \{[\s\S]*?\n\}',
        '',
        content
    )
    
    # Fix the provider
    content = re.sub(
        r'final patientsRepositoryProvider = Provider<IPatientsRepository>\(\(ref\) \{[\s\S]*?\}\);',
        '''final patientsRepositoryProvider = Provider<RemotePatientsRepository>((ref) {
  return RemotePatientsRepository(ref.read(grpcClientProvider));
});''',
        content
    )
    
    file.write_text(content)
    print("✓ Fixed patients_provider.dart")

def fix_users_provider():
    """Fix users_provider.dart - remove UsersRepository"""
    file = Path("lib/src/features/users/presentation/users_provider.dart")
    content = file.read_text()
    
    # Replace UsersRepository references with RemoteUsersRepository
    content = content.replace('UsersRepository', 'RemoteUsersRepository')
    
    file.write_text(content)
    print("✓ Fixed users_provider.dart")

def fix_messages_provider():
    """Fix messages_provider.dart"""
    file = Path("lib/src/features/messages/presentation/messages_provider.dart")
    content = file.read_text()
    
    # Replace MessagesRepository with RemoteMessagesRepository
    content = content.replace('MessagesRepository', 'RemoteMessagesRepository')
    content = content.replace('MessageTemplatesRepository', 'RemoteMessageTemplatesRepository')
    
    file.write_text(content)
    print("✓ Fixed messages_provider.dart")

def fix_waiting_queue_provider():
    """Fix waiting_queue_provider.dart"""
    file = Path("lib/src/features/waiting_queue/presentation/waiting_queue_provider.dart")
    content = file.read_text()
    
    # Replace WaitingQueueRepository with RemoteWaitingQueueRepository
    content = content.replace('WaitingQueueRepository', 'RemoteWaitingQueueRepository')
    
    file.write_text(content)
    print("✓ Fixed waiting_queue_provider.dart")

def main():
    print("🔧 Starting comprehensive fixes...\n")
    
    fix_rooms_provider()
    fix_patients_provider()
    fix_users_provider()
    fix_messages_provider()
    fix_waiting_queue_provider()
    
    print("\n✅ All provider fixes complete!")
    print("Next: Fix files using AppDatabase and Drift syntax")

if __name__ == '__main__':
    main()
