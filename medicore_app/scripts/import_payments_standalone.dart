import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'package:intl/intl.dart';
import 'package:sqlite3/sqlite3.dart';

/// Standalone script to import payments from XML
/// This version uses sqlite3 directly without Flutter dependencies
/// 
/// Run with: dart run scripts/import_payments_standalone.dart
Future<void> main() async {
  print('💰 Thaziri - Payments Import Tool (Standalone)');
  print('==============================================\n');

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

  // Get database path - macOS app documents directory
  final homeDir = Platform.environment['HOME'] ?? '/Users';
  
  // Try different possible paths
  final possiblePaths = [
    '$homeDir/Library/Containers/com.thaziri.medicoreApp/Data/Documents/medicore.db',
    '$homeDir/Library/Containers/com.example.medicoreApp/Data/Documents/medicore.db',
    '$homeDir/Documents/medicore.db',
  ];
  
  String? actualDbPath;
  for (final path in possiblePaths) {
    if (File(path).existsSync()) {
      actualDbPath = path;
      print('📂 Found database at: $actualDbPath');
      break;
    }
  }
  
  if (actualDbPath == null) {
    print('❌ Error: Database not found at:');
    for (final path in possiblePaths) {
      print('   $path');
    }
    print('\n   Please run the app at least once to create the database.');
    exit(1);
  }

  try {
    final db = sqlite3.open(actualDbPath);
    
    // First, ensure KARKOURI.N user exists
    print('\n👤 Checking for KARKOURI.N user...');
    final existingUsers = db.select(
      "SELECT * FROM users WHERE name = 'KARKOURI.N' AND deleted_at IS NULL"
    );
    
    String karkouriUserId;
    if (existingUsers.isEmpty) {
      karkouriUserId = 'karkouri-n-${DateTime.now().millisecondsSinceEpoch}';
      print('   Creating KARKOURI.N user (Médecin role)...');
      db.execute('''
        INSERT INTO users (id, name, role, password_hash, is_template_user, needs_sync)
        VALUES (?, 'KARKOURI.N', 'Médecin', '1234', 0, 0)
      ''', [karkouriUserId]);
      print('   ✅ User KARKOURI.N created (ID: $karkouriUserId)');
    } else {
      karkouriUserId = existingUsers.first['id'] as String;
      print('   ✅ User KARKOURI.N already exists (ID: $karkouriUserId)');
    }

    // Preload patients
    print('\n📂 Préchargement des patients...');
    final patients = db.select('SELECT code, first_name, last_name FROM patients');
    final patientCache = <int, Map<String, String>>{};
    for (final row in patients) {
      patientCache[row['code'] as int] = {
        'firstName': row['first_name'] as String,
        'lastName': row['last_name'] as String,
      };
    }
    print('   Patients en cache: ${patientCache.length}');

    // Preload users
    print('📂 Préchargement des utilisateurs...');
    final users = db.select("SELECT id, name FROM users WHERE deleted_at IS NULL");
    final userCache = <String, String>{};
    for (final row in users) {
      userCache[row['name'] as String] = row['id'] as String;
    }
    print('   Utilisateurs en cache: ${userCache.length}');

    print('\n📄 Lecture du fichier XML...');
    final xmlString = await file.readAsString();
    final document = xml.XmlDocument.parse(xmlString);
    
    final paymentElements = document.findAllElements('Table_Contenu').toList();
    final totalPayments = paymentElements.length;
    print('   Paiements trouvés: $totalPayments');

    final dateFormat = DateFormat('dd/MM/yyyy');
    
    int successCount = 0;
    int errorCount = 0;
    int skippedNoPatient = 0;
    final Set<String> uniqueUserNames = {};
    final Set<int> missingPatientCodes = {};
    final startTime = DateTime.now();

    // Begin transaction for faster inserts
    db.execute('BEGIN TRANSACTION');
    
    // Prepare the insert statement
    final insertStmt = db.prepare('''
      INSERT OR REPLACE INTO payments (
        id, medical_act_id, medical_act_name, amount, user_id, user_name,
        patient_code, patient_first_name, patient_last_name, payment_time,
        created_at, updated_at, needs_sync, is_active
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''');

    print('\n🔄 Importing payments...');
    
    for (int i = 0; i < paymentElements.length; i++) {
      try {
        final el = paymentElements[i];
        
        // Parse fields
        final idStr = _getElementText(el, 'N__Enr.');
        final id = int.tryParse(idStr ?? '');
        if (id == null) {
          errorCount++;
          continue;
        }

        final medicalActIdStr = _getElementText(el, 'IDHONORAIRE');
        final medicalActId = int.tryParse(medicalActIdStr ?? '') ?? 0;

        final acteName = _getElementText(el, 'ACTE') ?? '';
        
        final montantStr = _getElementText(el, 'MONATNT');
        final amount = int.tryParse(montantStr ?? '') ?? 0;

        final medcinName = _getElementText(el, 'MEDCIN') ?? '';
        uniqueUserNames.add(medcinName);
        
        final userId = userCache[medcinName] ?? '';

        final cdepStr = _getElementText(el, 'CDEP');
        final patientCode = int.tryParse(cdepStr ?? '');
        if (patientCode == null) {
          errorCount++;
          continue;
        }

        String patientFirstName = '';
        String patientLastName = '';
        final patient = patientCache[patientCode];
        if (patient != null) {
          patientFirstName = patient['firstName'] ?? '';
          patientLastName = patient['lastName'] ?? '';
        } else {
          missingPatientCodes.add(patientCode);
          skippedNoPatient++;
        }

        // Parse date and time
        final dateStr = _getElementText(el, 'DATE');
        final timeStr = _getElementText(el, 'HORAIR');
        
        int paymentTime;
        try {
          final date = dateFormat.parse(dateStr ?? '01/01/2000');
          final timeParts = (timeStr ?? '00:00').split(':');
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
          final dateTime = DateTime(date.year, date.month, date.day, hour, minute);
          // Drift expects milliseconds since epoch
          paymentTime = dateTime.millisecondsSinceEpoch;
        } catch (e) {
          paymentTime = DateTime.now().millisecondsSinceEpoch;
        }

        // Insert payment
        insertStmt.execute([
          id,
          medicalActId,
          acteName,
          amount,
          userId,
          medcinName,
          patientCode,
          patientFirstName,
          patientLastName,
          paymentTime,
          paymentTime,
          paymentTime,
          0, // needsSync = false
          1, // isActive = true
        ]);

        successCount++;

        // Progress report
        if ((i + 1) % 10000 == 0) {
          final percent = ((i + 1) / totalPayments * 100).toStringAsFixed(1);
          print('   Progress: ${i + 1} / $totalPayments ($percent%)');
        }
      } catch (e) {
        errorCount++;
      }
    }

    insertStmt.dispose();
    
    // Commit transaction
    db.execute('COMMIT');

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    print('\n✅ Import Complete!');
    print('   Duration: ${duration.inMinutes}m ${duration.inSeconds % 60}s');
    print('   Success: $successCount payments imported');
    print('   Errors: $errorCount');
    print('   Skipped (no patient data): $skippedNoPatient');
    
    print('\n👥 Unique doctors found in data:');
    for (final name in uniqueUserNames) {
      final hasUser = userCache.containsKey(name);
      print('   - $name ${hasUser ? "✅" : "⚠️ (not in database)"}');
    }

    if (missingPatientCodes.isNotEmpty && missingPatientCodes.length <= 10) {
      print('\n⚠️  Missing patient codes (first 10): ${missingPatientCodes.take(10).toList()}');
    } else if (missingPatientCodes.isNotEmpty) {
      print('\n⚠️  ${missingPatientCodes.length} patient codes not found in database');
    }

    // Verify import
    print('\n🔍 Verifying import...');
    final maxIdResult = db.select('SELECT MAX(id) as max_id FROM payments');
    final maxId = maxIdResult.first['max_id'] ?? 0;
    print('   Maximum payment ID in database: $maxId');
    
    final countResult = db.select('SELECT COUNT(*) as count FROM payments WHERE is_active = 1');
    final totalInDb = countResult.first['count'] ?? 0;
    print('   Total active payments: $totalInDb');

    // Sample verification for 06/10/2016
    print('\n📅 Sample verification (06/10/2016):');
    final date1 = DateTime(2016, 10, 6).millisecondsSinceEpoch ~/ 1000;
    final date2 = DateTime(2016, 10, 7).millisecondsSinceEpoch ~/ 1000;
    final sampleResult = db.select('''
      SELECT * FROM payments 
      WHERE payment_time >= ? AND payment_time < ?
      AND is_active = 1
      ORDER BY payment_time
      LIMIT 5
    ''', [date1, date2]);
    print('   Payments on 06/10/2016: ${sampleResult.length} (showing first 5)');
    for (final row in sampleResult) {
      print('   - ID=${row['id']}, Act=${row['medical_act_name']}, Amount=${row['amount']} DA');
    }

    db.dispose();
    
    print('\n🎉 Import finished successfully!');
    print('   The doctor KARKOURI.N can now log in and see all payments.');
    
    exit(0);
  } catch (e, stackTrace) {
    print('\n❌ Fatal error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

String? _getElementText(xml.XmlElement element, String tagName) {
  final found = element.findElements(tagName).firstOrNull;
  return found?.innerText.trim();
}
