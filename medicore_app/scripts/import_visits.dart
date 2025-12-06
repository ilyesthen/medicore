import 'dart:io';
import 'package:medicore_app/src/core/database/app_database.dart';
import 'package:medicore_app/src/features/visits/data/visits_repository.dart';
import 'package:medicore_app/src/features/visits/data/visits_xml_import_service.dart';

/// Standalone script to import visits from XML
/// Run with: dart run scripts/import_visits.dart
Future<void> main() async {
  print('MediCore - Visits Import Tool');
  print('================================\n');

  final xmlPath = '/Applications/eye/visits.xml';
  final file = File(xmlPath);

  if (!await file.exists()) {
    print('Error: XML file not found at $xmlPath');
    print('   Please ensure visits.xml is in /Applications/eye/');
    exit(1);
  }

  // Get file size for progress indication
  final fileSize = await file.length();
  final fileSizeMB = (fileSize / 1024 / 1024).toStringAsFixed(2);
  print('Found XML file: $xmlPath ($fileSizeMB MB)');
  print('Starting import...\n');

  try {
    final db = AppDatabase();
    final repository = VisitsRepository(db);
    final importService = VisitsXmlImportService(repository);

    // Clear existing visits if needed
    print('Clearing existing visits data...');
    await repository.clearAllVisits();

    print('Parsing and importing visits...');
    final result = await importService.importFromXml(xmlPath);

    print('\nImport Complete!');
    print('   Success: ${result.successCount} visits');
    print('   Errors: ${result.errorCount}');

    if (result.errors.isNotEmpty) {
      print('\nErrors encountered:');
      for (final error in result.errors.take(10)) {
        print('   - $error');
      }
      if (result.errors.length > 10) {
        print('   ... and ${result.errors.length - 10} more errors');
      }
    }

    await db.close();
    
    if (result.isSuccess) {
      print('\nXML file has been deleted after successful import.');
      exit(0);
    } else {
      exit(1);
    }
  } catch (e, stack) {
    print('\nFatal error: $e');
    print(stack);
    exit(1);
  }
}
