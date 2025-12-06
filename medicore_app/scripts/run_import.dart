// Quick import script for ordonnances XML
// Run with: dart run scripts/run_import.dart

import 'dart:io';
import 'package:xml/xml.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

void main() async {
  print('🚀 Starting ordonnances import...');
  
  final xmlPath = '/Applications/eye/ordononce.xml';
  final xmlFile = File(xmlPath);
  
  if (!await xmlFile.exists()) {
    print('❌ XML file not found: $xmlPath');
    exit(1);
  }
  
  // Get database path (sandboxed app location)
  final home = Platform.environment['HOME'] ?? '/tmp';
  final dbPath = p.join(home, 'Library', 'Containers', 'com.example.medicoreApp', 'Data', 'Documents', 'medicore.db');
  print('📂 Database: $dbPath');
  
  // Open database directly
  final db = sqlite3.open(dbPath);
  
  // Create table if not exists
  db.execute('''
    CREATE TABLE IF NOT EXISTS ordonnances (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      original_id INTEGER,
      patient_code INTEGER NOT NULL,
      document_date TEXT,
      patient_age INTEGER,
      sequence INTEGER DEFAULT 1,
      seq_pat TEXT,
      doctor_name TEXT,
      amount REAL DEFAULT 0,
      content1 TEXT,
      type1 TEXT DEFAULT 'ORDONNANCE',
      content2 TEXT,
      type2 TEXT,
      content3 TEXT,
      type3 TEXT,
      additional_notes TEXT,
      report_title TEXT,
      referred_by TEXT,
      rdv_flag INTEGER DEFAULT 0,
      rdv_date TEXT,
      rdv_day TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  ''');
  
  print('📖 Reading XML file (79MB)...');
  final xmlContent = await xmlFile.readAsString();
  
  print('🔍 Parsing XML...');
  final document = XmlDocument.parse(xmlContent);
  final records = document.findAllElements('Table_Contenu').toList();
  print('📊 Found ${records.length} records');
  
  int success = 0;
  int errors = 0;
  final startTime = DateTime.now();
  
  // Prepare statement for faster inserts
  final stmt = db.prepare('''
    INSERT INTO ordonnances (
      original_id, patient_code, document_date, patient_age, sequence, seq_pat,
      doctor_name, amount, content1, type1, content2, type2, content3, type3,
      additional_notes, report_title, referred_by, rdv_flag, rdv_date, rdv_day
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''');
  
  // Process in batches
  const batchSize = 1000;
  
  for (int i = 0; i < records.length; i += batchSize) {
    final batch = records.skip(i).take(batchSize).toList();
    
    db.execute('BEGIN TRANSACTION');
    
    for (final record in batch) {
      try {
        final originalId = _getInt(record, 'N__Enr.');
        final patientCode = _getInt(record, 'CDEP');
        if (patientCode == null) { errors++; continue; }
        
        final dateOrd = _getText(record, 'DATEORD');
        final age = _getInt(record, 'AG2');
        final seq = _getInt(record, 'SEQ') ?? 1;
        final seqPat = _getText(record, 'SEQPAT');
        final doctorName = _getText(record, 'MEDCIN');
        final amount = _getDouble(record, 'SMONT') ?? 0;
        
        final content1 = _getTextPreserve(record, 'STRAIT');
        final type1 = _getText(record, 'ACTEX') ?? 'ORDONNANCE';
        final content2 = _getTextPreserve(record, 'strait1');
        final type2 = _getText(record, 'ACTEX1');
        final content3 = _getTextPreserve(record, 'strait2');
        final type3 = _getText(record, 'ACTEX2');
        final additionalNotes = _getTextPreserve(record, 'strait3');
        final reportTitle = _getText(record, 'titre_cr');
        final referredBy = _getText(record, 'ADressé_par');
        final rdvFlag = _getInt(record, 'rdvle') ?? 0;
        final rdvDate = _getText(record, 'datele');
        final rdvDay = _getText(record, 'jourle');
        
        String? documentDate;
        if (dateOrd != null && dateOrd.contains('/')) {
          final parts = dateOrd.split('/');
          if (parts.length == 3) {
            documentDate = '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
          }
        }
        
        stmt.execute([
          originalId, patientCode, documentDate, age, seq, seqPat,
          doctorName, amount, content1, type1, content2, type2, content3, type3,
          additionalNotes, reportTitle, referredBy, rdvFlag, rdvDate, rdvDay
        ]);
        
        success++;
      } catch (e) {
        errors++;
      }
    }
    
    db.execute('COMMIT');
    
    final progress = ((i + batch.length) / records.length * 100).toStringAsFixed(1);
    stdout.write('\r  ⏳ $progress% ($success imported)');
  }
  
  stmt.dispose();
  
  final elapsed = DateTime.now().difference(startTime);
  
  print('\n');
  print('✅ Import complete!');
  print('   Success: $success');
  print('   Errors: $errors');
  print('   Time: ${elapsed.inSeconds}s');
  
  db.dispose();
}

String? _getText(XmlElement parent, String name) {
  final elements = parent.findElements(name);
  if (elements.isEmpty) return null;
  final text = elements.first.innerText.trim();
  return text.isEmpty ? null : text;
}

String? _getTextPreserve(XmlElement parent, String name) {
  final elements = parent.findElements(name);
  if (elements.isEmpty) return null;
  String text = elements.first.innerText;
  text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  return text.isEmpty ? null : text;
}

int? _getInt(XmlElement parent, String name) {
  final text = _getText(parent, name);
  return text == null ? null : int.tryParse(text);
}

double? _getDouble(XmlElement parent, String name) {
  final text = _getText(parent, name);
  return text == null ? null : double.tryParse(text);
}
