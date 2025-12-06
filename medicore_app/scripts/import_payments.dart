import 'dart:io';
import 'package:medicore_app/src/core/database/app_database.dart';
import 'package:medicore_app/src/features/comptabilite/data/payments_repository.dart';
import 'package:medicore_app/src/features/comptabilite/data/payments_xml_import_service.dart';
import 'package:drift/drift.dart';

/// Standalone script to import payments from XML
/// Run with: dart run scripts/import_payments.dart
Future<void> main() async {
  print('💰 Thaziri - Payments Import Tool');
  print('==================================\n');

  final xmlPath = '/Applications/eye/payments.xml';
  final file = File(xmlPath);

  if (!await file.exists()) {
    print('❌ Error: XML file not found at $xmlPath');
    print('   Please ensure payments.xml is in /Applications/eye/');
    exit(1);
  }

  print('📄 Found XML file: $xmlPath');
  
  // Get file size
  final fileSize = await file.length();
  final fileSizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
  print('   File size: $fileSizeMB MB');

  try {
    final db = AppDatabase();
    
    // First, ensure KARKOURI.N user exists
    print('\n👤 Checking for KARKOURI.N user...');
    final existingUser = await (db.select(db.users)
          ..where((u) => u.name.equals('KARKOURI.N')))
        .getSingleOrNull();
    
    if (existingUser == null) {
      print('   Creating KARKOURI.N user (Médecin role)...');
      await db.into(db.users).insert(
        UsersCompanion.insert(
          id: 'karkouri-n-${DateTime.now().millisecondsSinceEpoch}',
          name: 'KARKOURI.N',
          role: 'Médecin',
          passwordHash: '1234', // Default password
          isTemplateUser: const Value(false),
          needsSync: const Value(false),
        ),
      );
      print('   ✅ User KARKOURI.N created');
    } else {
      print('   ✅ User KARKOURI.N already exists (ID: ${existingUser.id})');
    }

    final repository = PaymentsRepository(db);
    final importService = PaymentsXmlImportService(repository, db);

    print('\n🔄 Starting payment import...');
    print('   This may take several minutes for large files...\n');
    
    final startTime = DateTime.now();

    final result = await importService.importFromXml(
      xmlPath,
      onProgress: (current, total) {
        // Progress is printed inside the service
      },
    );

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    print('\n✅ Import Complete!');
    print('   Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s');
    print('   Success: ${result.successCount} payments imported');
    print('   Errors: ${result.errorCount}');
    print('   Skipped (no patient): ${result.skippedNoPatient}');
    print('   Skipped (no user): ${result.skippedNoUser}');
    
    if (result.uniqueUserNames.isNotEmpty) {
      print('\n👥 Unique doctors found in data:');
      for (final name in result.uniqueUserNames) {
        print('   - $name');
      }
    }

    if (result.errors.isNotEmpty && result.errors.length <= 20) {
      print('\n⚠️  Errors encountered:');
      for (final error in result.errors) {
        print('   - $error');
      }
    } else if (result.errors.isNotEmpty) {
      print('\n⚠️  ${result.errors.length} errors encountered (showing first 10):');
      for (final error in result.errors.take(10)) {
        print('   - $error');
      }
    }

    // Verify import
    print('\n🔍 Verifying import...');
    final maxId = await repository.getMaxPaymentId();
    print('   Maximum payment ID in database: $maxId');
    
    // Count total payments
    final totalPayments = await db.customSelect(
      'SELECT COUNT(*) as count FROM payments WHERE is_active = 1',
    ).getSingle();
    print('   Total active payments: ${totalPayments.read<int>('count')}');

    // Sample a specific date to verify
    print('\n📅 Sample verification (06/10/2016):');
    final samplePayments = await db.customSelect(
      '''
      SELECT * FROM payments 
      WHERE payment_time >= ? AND payment_time < ?
      AND is_active = 1
      ORDER BY payment_time
      ''',
      variables: [
        Variable.withInt(DateTime(2016, 10, 6).millisecondsSinceEpoch ~/ 1000),
        Variable.withInt(DateTime(2016, 10, 7).millisecondsSinceEpoch ~/ 1000),
      ],
    ).get();
    print('   Payments on 06/10/2016: ${samplePayments.length}');
    if (samplePayments.isNotEmpty) {
      final first = samplePayments.first;
      print('   First payment: ID=${first.read<int>('id')}, Act=${first.read<String>('medical_act_name')}, Amount=${first.read<int>('amount')} DA');
    }

    await db.close();
    
    print('\n🎉 Import finished successfully!');
    print('   The doctor KARKOURI.N can now log in and see all payments.');
    
    exit(0);
  } catch (e, stackTrace) {
    print('\n❌ Fatal error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
