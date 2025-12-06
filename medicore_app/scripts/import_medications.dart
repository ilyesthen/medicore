// Import medications from 39.xml
// Run with: dart run scripts/import_medications.dart

import 'dart:io';
import 'package:xml/xml.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

void main() async {
  print('🚀 Starting medications import...');
  
  final xmlPath = '/Applications/eye/39.xml';
  final xmlFile = File(xmlPath);
  
  if (!await xmlFile.exists()) {
    print('❌ XML file not found: $xmlPath');
    exit(1);
  }
  
  // Get database path (sandboxed app location)
  final home = Platform.environment['HOME'] ?? '/tmp';
  final dbPath = p.join(home, 'Library', 'Containers', 'com.example.medicoreApp', 'Data', 'Documents', 'medicore.db');
  print('📂 Database: $dbPath');
  
  final db = sqlite3.open(dbPath);
  
  // Create table if not exists
  db.execute('''
    CREATE TABLE IF NOT EXISTS medications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      original_id INTEGER,
      code TEXT NOT NULL,
      prescription TEXT NOT NULL,
      usage_count INTEGER DEFAULT 0,
      nature TEXT DEFAULT 'O',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  ''');
  
  // Clear existing data
  db.execute('DELETE FROM medications');
  print('🗑️ Cleared existing medications');
  
  print('📖 Reading XML file...');
  final xmlContent = await xmlFile.readAsString();
  
  print('🔍 Parsing XML...');
  final document = XmlDocument.parse(xmlContent);
  final records = document.findAllElements('Table_Contenu').toList();
  print('📊 Found ${records.length} records');
  
  final stmt = db.prepare('''
    INSERT INTO medications (original_id, code, prescription, usage_count, nature)
    VALUES (?, ?, ?, ?, ?)
  ''');
  
  int success = 0;
  int errors = 0;
  
  db.execute('BEGIN TRANSACTION');
  
  for (final record in records) {
    try {
      final originalId = _getInt(record, 'IDPREPA');
      final code = _getText(record, 'CODELIB') ?? '';
      final prescription = _getTextPreserve(record, 'LIBPREP') ?? '';
      final usageCount = _getInt(record, 'NBPRES') ?? 0;
      final nature = _getText(record, 'NATURE') ?? 'O';
      
      if (code.isEmpty) { errors++; continue; }
      
      stmt.execute([originalId, code, prescription, usageCount, nature]);
      success++;
    } catch (e) {
      errors++;
      print('  ⚠️ Error: $e');
    }
  }
  
  db.execute('COMMIT');
  stmt.dispose();
  
  print('');
  print('✅ Import complete!');
  print('   Success: $success');
  print('   Errors: $errors');
  
  // Show top 10 by usage
  print('');
  print('📊 Top 10 most used:');
  final top = db.select('SELECT code, usage_count FROM medications ORDER BY usage_count DESC LIMIT 10');
  for (final row in top) {
    print('   ${row['usage_count']} - ${row['code']}');
  }
  
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
  text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').replaceAll('&#13;', '\n');
  // Keep formatting but trim edges
  text = text.trim();
  return text.isEmpty ? null : text;
}

int? _getInt(XmlElement parent, String name) {
  final text = _getText(parent, name);
  return text == null ? null : int.tryParse(text);
}
