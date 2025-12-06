import 'dart:io';
import 'package:medicore_app/src/core/database/app_database.dart';
import 'package:medicore_app/src/features/patients/data/patients_repository.dart';
import 'package:medicore_app/src/features/patients/data/xml_import_service.dart';

/// Standalone script to import patients from XML
/// Run with: dart run scripts/import_patients.dart
Future<void> main() async {
  print('🏥 Thaziri - Patient Import Tool');
  print('=================================\n');

  final xmlPath = '/Applications/eye/patients.xml';
  final file = File(xmlPath);

  if (!await file.exists()) {
    print('❌ Error: XML file not found at $xmlPath');
    print('   Please ensure patients.xml is in /Applications/eye/');
    exit(1);
  }

  print('📄 Found XML file: $xmlPath');
  print('🔄 Starting import...\n');

  try {
    final db = AppDatabase();
    final repository = PatientsRepository(db);
    final importService = XmlImportService(repository);

    final result = await importService.importFromXml(xmlPath);

    print('\n✅ Import Complete!');
    print('   Success: ${result.successCount} patients');
    print('   Errors: ${result.errorCount}');

    if (result.errors.isNotEmpty) {
      print('\n⚠️  Errors encountered:');
      for (final error in result.errors) {
        print('   - $error');
      }
    }

    await db.close();
    
    if (result.isSuccess) {
      print('\n🗑️  XML file has been deleted.');
      exit(0);
    } else {
      exit(1);
    }
  } catch (e) {
    print('\n❌ Fatal error: $e');
    exit(1);
  }
}
