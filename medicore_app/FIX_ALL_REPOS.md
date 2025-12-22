# COMPREHENSIVE FIX LIST

## Problem Summary
Files reference DELETED repository classes that don't exist anymore.
All repos are now REMOTE ONLY - no local database repos exist.

## Files to Fix

### 1. rooms_provider.dart
- Remove `RoomsRepository` class references (line 17, 61)
- Remove `LocalRoomsAdapter` class (uses deleted RoomsRepository)
- Use ONLY RemoteRoomsRepository

### 2. patients_provider.dart  
- Remove `PatientsRepository` class references (line 47, 175)
- Remove `LocalPatientsAdapter` class (uses deleted PatientsRepository)
- Use ONLY RemotePatientsRepository

### 3. users_provider.dart
- Remove `UsersRepository` class references (line 30, 107, 182, 187)
- Use ONLY RemoteUsersRepository

### 4. messages_provider.dart
- Remove `MessagesRepository` class references (line 32, 160)
- Remove `MessageTemplatesRepository` class references (line 170)
- Use ONLY RemoteMessagesRepository

### 5. waiting_queue_provider.dart
- Remove `WaitingQueueRepository` class references (line 50, 263)
- Use ONLY RemoteWaitingQueueRepository

### 6. All files using deleted repo methods
- Replace all `RepositoryFactory().getXXXRepository()` calls
- Use providers instead

### 7. Files using AppDatabase
- age_calculator_service.dart - remove AppDatabase references
- ordonnance_page.dart - remove AppDatabase.instance
- patient_context_service.dart - remove AppDatabase constructor calls
- ai_action_handler.dart - remove Drift Value() calls and OrdonnancesCompanion

### 8. Files using Drift syntax
- new_visit_page.dart - remove VisitsCompanion, Value() calls
- ai_action_handler.dart - remove OrdonnancesCompanion, Value() calls

## Solution
Create stub/placeholder files for each deleted repo file that just throw errors,
OR better: directly use Remote repos everywhere and delete adapter classes.
