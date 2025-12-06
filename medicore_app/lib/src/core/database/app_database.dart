import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;

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

part 'app_database.g.dart';

/// MediCore Application Database
/// Uses Drift for compile-time safe SQL queries
@DriftDatabase(tables: [Users, Templates, Rooms, Patients, MessageTemplates, Messages, MedicalActs, Payments, Visits, WaitingPatients, Ordonnances, Medications])
class AppDatabase extends _$AppDatabase {
  /// Singleton instance
  static AppDatabase? _instance;
  
  /// Get the singleton instance
  static AppDatabase get instance {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }
  
  /// Private constructor for singleton
  AppDatabase._internal() : super(_openConnection());
  
  /// Public constructor - returns singleton
  factory AppDatabase() => instance;

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // Insert admin user on first run
        await into(users).insert(
          UsersCompanion.insert(
            id: 'admin',
            name: 'Administrateur',
            role: 'Administrateur',
            passwordHash: '1234', // TODO: Hash in production
            isTemplateUser: const Value(false),
            needsSync: const Value(false), // Admin doesn't sync
          ),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
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

/// Opens database connection
/// Desktop: Uses SQLite file in app documents directory
/// Web: Not supported (uses in-memory fallback)
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (kIsWeb) {
      // Web doesn't support persistent SQLite
      // This shouldn't be reached in production as we're desktop-focused
      return NativeDatabase.memory();
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'medicore.db'));
    
    return NativeDatabase.createInBackground(file);
  });
}
