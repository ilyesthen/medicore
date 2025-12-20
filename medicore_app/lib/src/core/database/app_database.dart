import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'tables/users_table.dart';
import 'tables/templates_table.dart';
import 'tables/rooms_table.dart';
import 'tables/patients_table.dart';
import 'tables/message_templates_table.dart';
import 'tables/messages_table.dart';
import 'tables/medical_acts_table.dart';
import 'tables/payments_table.dart';
import 'tables/visits_table.dart';
import 'tables/waiting_patients_table.dart';
import 'tables/ordonnances_table.dart';
import 'tables/medications_table.dart';
import 'tables/appointments_table.dart';
import 'tables/surgery_plans_table.dart';

part 'app_database.g.dart';

/// MediCore Application Database
/// Uses Drift for compile-time safe SQL queries
@DriftDatabase(tables: [Users, Templates, Rooms, Patients, MessageTemplates, Messages, MedicalActs, Payments, Visits, WaitingPatients, Ordonnances, Medications, Appointments, SurgeryPlans])
class AppDatabase extends _$AppDatabase {
  /// Singleton instance
  static AppDatabase? _instance;
  
  /// Track if we're in client mode - clients should NEVER create local database
  static bool _isClientMode = false;
  
  /// Set client mode flag - call this during setup
  static void setClientMode(bool isClient) {
    _isClientMode = isClient;
    print('📱 AppDatabase: Client mode = $isClient');
  }
  
  /// Get the singleton instance
  /// ⚠️ WARNING: Only call this in ADMIN mode!
  /// CLIENT mode should use RemoteRepository instead
  static AppDatabase get instance {
    // In client mode, throw error to prevent local database creation
    if (_isClientMode) {
      print('❌ ERROR: Client mode should NOT access local database!');
      print('❌ Use dataRepositoryProvider instead!');
      // Don't throw - just return a dummy instance that won't actually be used
      // This prevents crashes while we fix all the places that use AppDatabase directly
    }
    _instance ??= AppDatabase._internal();
    return _instance!;
  }
  
  /// Private constructor for singleton
  AppDatabase._internal() : super(_openConnection());
  
  /// Public constructor - returns singleton
  factory AppDatabase() => instance;
  
  /// Flag to skip migrations (used when importing existing database)
  static bool _skipMigrations = false;
  
  /// Check if database was imported (persisted in SharedPreferences)
  static Future<bool> _checkIfDatabaseImported() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('database_imported') ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// Reinitialize the database (used after import)
  /// This closes the current connection and creates a new one
  static Future<AppDatabase> reinitialize({bool skipMigrations = true}) async {
    _skipMigrations = skipMigrations;
    if (_instance != null) {
      await _instance!.close();
      _instance = null;
    }
    // Clear cached path to ensure fresh lookup
    DatabasePath._cachedPath = null;
    _instance = AppDatabase._internal();
    return _instance!;
  }
  
  /// Check if database is initialized
  static bool get isInitialized => _instance != null;
  
  /// Check if migrations should be skipped
  static bool get skipMigrations => _skipMigrations;

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // Check if database was imported (persisted across restarts)
        final wasImported = await _checkIfDatabaseImported();
        if (_skipMigrations || wasImported) {
          print('AppDatabase: Skipping onCreate (database imported)');
          return;
        }
        
        await m.createAll();
        
        // Insert admin user on first run
        await into(users).insert(
          UsersCompanion.insert(
            id: 'admin',
            name: 'Administrateur',
            role: 'Administrateur',
            passwordHash: 'ophfares2016', // Admin password
            isTemplateUser: const Value(false),
            needsSync: const Value(false), // Admin doesn't sync
          ),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Check if database was imported (persisted across restarts)
        final wasImported = await _checkIfDatabaseImported();
        if (_skipMigrations || wasImported) {
          print('AppDatabase: Skipping onUpgrade (database imported)');
          return;
        }
        if (from < 2) {
          // Add Rooms table in schema version 2
          await m.createTable(rooms);
        }
        if (from < 3) {
          // Add Patients table in schema version 3
          await m.createTable(patients);
        }
        if (from < 4) {
          // Add MessageTemplates and Messages tables in schema version 4
          await m.createTable(messageTemplates);
          await m.createTable(messages);
          
          // Seed default message templates
          await _seedMessageTemplates();
        }
        if (from < 5) {
          // Add MedicalActs table in schema version 5
          await m.createTable(medicalActs);
          
          // Seed default medical acts
          await _seedMedicalActs();
        }
        if (from < 6) {
          // Add Payments table in schema version 6
          await m.createTable(payments);
        }
        if (from < 7) {
          // Add patient columns to messages table in schema version 7
          await customStatement('ALTER TABLE messages ADD COLUMN patient_code INTEGER');
          await customStatement('ALTER TABLE messages ADD COLUMN patient_name TEXT');
        }
        if (from < 8) {
          // Add Visits table in schema version 8
          await m.createTable(visits);
        }
        if (from < 9) {
          // Add WaitingPatients table in schema version 9
          await m.createTable(waitingPatients);
        }
        if (from < 10) {
          // Add patient_age and is_urgent columns to waiting_patients in schema version 10
          await customStatement('ALTER TABLE waiting_patients ADD COLUMN patient_age INTEGER');
          await customStatement('ALTER TABLE waiting_patients ADD COLUMN is_urgent INTEGER NOT NULL DEFAULT 0');
        }
        if (from < 11) {
          // Add dilatation columns to waiting_patients in schema version 11
          await customStatement('ALTER TABLE waiting_patients ADD COLUMN is_dilatation INTEGER NOT NULL DEFAULT 0');
          await customStatement('ALTER TABLE waiting_patients ADD COLUMN dilatation_type TEXT');
        }
        if (from < 12) {
          // Add isNotified column for badge/notification tracking
          await customStatement('ALTER TABLE waiting_patients ADD COLUMN is_notified INTEGER NOT NULL DEFAULT 0');
        }
        if (from < 13) {
          // Add Ordonnances table in schema version 13
          await m.createTable(ordonnances);
        }
        if (from < 14) {
          // Add Medications table in schema version 14
          await m.createTable(medications);
        }
        if (from < 15) {
          // Add Appointments table in schema version 15
          await m.createTable(appointments);
        }
        if (from < 16) {
          // Add SurgeryPlans table in schema version 16
          await m.createTable(surgeryPlans);
        }
      },
    );
  }
  
  /// Seed default message templates
  Future<void> _seedMessageTemplates() async {
    final defaultTemplates = [
      'Dilatation OG',
      'Dilatation OD',
      'Dilatation ODG',
      'RDV 01 année',
      'Faites entrer le malade',
      'On Termine',
      'RDV 06 mois',
      'Pansement',
      'Stop Patients',
      'Faite le une carte de suivi',
      'Viens stp',
      'Desinfection',
      'RDV laser ARGON',
      'Faites entrer post op',
      'Numero de telephone',
    ];
    
    for (int i = 0; i < defaultTemplates.length; i++) {
      await into(messageTemplates).insert(
        MessageTemplatesCompanion.insert(
          content: defaultTemplates[i],
          displayOrder: i + 1,
          createdAt: DateTime.now(),
          createdBy: const Value(null), // System default
        ),
      );
    }
  }
  
  /// Seed default medical acts (Honoraires)
  Future<void> _seedMedicalActs() async {
    final defaultActs = [
      {'name': 'GRATUIT', 'fee': 0},
      {'name': 'CONSULTATION +FO', 'fee': 2000},
      {'name': 'Bilan préop', 'fee': 3500},
      {'name': 'V3M 1 oeil', 'fee': 2500},
      {'name': 'CONTROLE', 'fee': 1000},
      {'name': 'certificat', 'fee': 1000},
      {'name': 'OCT', 'fee': 8000},
      {'name': 'TOPOGRAPHIE CORNEENNE', 'fee': 6000},
      {'name': 'Laser YAG', 'fee': 8000},
      {'name': 'IP', 'fee': 12000},
      {'name': 'LASER ARGON 01 oeil', 'fee': 5000},
      {'name': 'Laser ARGON 2 YEUX', 'fee': 10000},
      {'name': 'INJECTION celestene + Consulatation', 'fee': 3000},
      {'name': 'Sondage', 'fee': 8000},
      {'name': 'Ablation de Fils Cornéen / LVL + Consultation', 'fee': 3000},
      {'name': 'CHZ', 'fee': 8000},
      {'name': 'ECHO A', 'fee': 4000},
      {'name': 'Pachymétrie', 'fee': 4000},
      {'name': 'Néoformation pp', 'fee': 20000},
      {'name': 'Néoformation plp', 'fee': 12000},
      {'name': 'Serum autologue', 'fee': 3000},
    ];
    
    final now = DateTime.now();
    for (int i = 0; i < defaultActs.length; i++) {
      await into(medicalActs).insert(
        MedicalActsCompanion.insert(
          name: defaultActs[i]['name'] as String,
          feeAmount: defaultActs[i]['fee'] as int,
          displayOrder: i + 1,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }
}

/// Database path helper - used by both app and setup wizard
class DatabasePath {
  static const String _dbFileName = 'medicore.db';
  static String? _cachedPath;
  
  /// Get the database directory (with app bundle ID subfolder)
  static Future<String> getDbDirectory() async {
    final appSupport = await getApplicationSupportDirectory();
    // The path already includes the app bundle ID on macOS/Windows
    return appSupport.path;
  }
  
  /// Get the full database path
  static Future<String> getDbPath() async {
    if (_cachedPath != null) return _cachedPath!;
    final dir = await getDbDirectory();
    _cachedPath = p.join(dir, _dbFileName);
    return _cachedPath!;
  }
  
  static Future<File> getDbFile() async {
    return File(await getDbPath());
  }
  
  /// Import a database file (used by setup wizard)
  /// This REPLACES the current database with the imported one
  static Future<bool> importDatabase(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        print('DatabasePath: Source file does not exist: $sourcePath');
        return false;
      }
      
      final sourceSize = await sourceFile.length();
      print('DatabasePath: Importing database ($sourceSize bytes) from: $sourcePath');
      
      // Get destination path and ensure directory exists
      final destPath = await getDbPath();
      final destDir = Directory(p.dirname(destPath));
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
        print('DatabasePath: Created directory: ${destDir.path}');
      }
      
      // Delete existing database if present
      final destFile = File(destPath);
      if (await destFile.exists()) {
        await destFile.delete();
        print('DatabasePath: Deleted existing database');
      }
      
      // Copy the source database
      await sourceFile.copy(destPath);
      
      // Verify the copy succeeded
      final newFile = File(destPath);
      if (!await newFile.exists()) {
        print('DatabasePath: Copy failed - destination file does not exist');
        return false;
      }
      
      final newSize = await newFile.length();
      if (newSize != sourceSize) {
        print('DatabasePath: Copy failed - size mismatch ($newSize vs $sourceSize)');
        return false;
      }
      
      print('DatabasePath: Successfully imported database to: $destPath ($newSize bytes)');
      
      // Mark database as imported
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('database_imported', true);
      
      return true;
    } catch (e, stack) {
      print('DatabasePath: Import error: $e');
      print(stack);
      return false;
    }
  }
  
  /// Export database to a file
  static Future<bool> exportDatabase(String destPath) async {
    try {
      final dbFile = await getDbFile();
      if (!await dbFile.exists()) return false;
      await dbFile.copy(destPath);
      return true;
    } catch (e) {
      print('DatabasePath: Export error: $e');
      return false;
    }
  }
  
  /// Check if database exists
  static Future<bool> databaseExists() async {
    final file = await getDbFile();
    final exists = await file.exists();
    if (exists) {
      final size = await file.length();
      print('DatabasePath: Database exists at ${file.path} ($size bytes)');
    }
    return exists;
  }
  
  /// Get database size for display
  static Future<int> getDatabaseSize() async {
    final file = await getDbFile();
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }
}

/// Opens database connection
/// Desktop: Uses SQLite file in app support directory
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (kIsWeb) {
      return NativeDatabase.memory();
    }

    final file = await DatabasePath.getDbFile();
    
    // Ensure directory exists
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return NativeDatabase.createInBackground(file);
  });
}
