// Import Comptes Rendus templates from 18.xml
// Run with: dart run scripts/import_templates.dart

import 'dart:io';
import 'package:xml/xml.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

void main() async {
  print('🚀 Starting templates import...');
  
  final xmlPath = '/Applications/eye/18.xml';
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
  
  // Create templates_cr table if not exists
  db.execute('''
    CREATE TABLE IF NOT EXISTS templates_cr (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      original_id INTEGER,
      code TEXT NOT NULL,
      content TEXT NOT NULL,
      usage_count INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
  ''');
  
  // Clear existing data
  db.execute('DELETE FROM templates_cr');
  print('🗑️ Cleared existing templates');
  
  print('📖 Reading XML file...');
  final xmlContent = await xmlFile.readAsString();
  
  print('🔍 Parsing XML...');
  final document = XmlDocument.parse(xmlContent);
  final records = document.findAllElements('Table_Contenu').toList();
  print('📊 Found ${records.length} records');
  
  final stmt = db.prepare('''
    INSERT INTO templates_cr (original_id, code, content)
    VALUES (?, ?, ?)
  ''');
  
  int success = 0;
  int errors = 0;
  
  for (final record in records) {
    try {
      final originalId = _getInt(record, 'IDCOMPTES');
      final code = _getText(record, 'CODE_COMPTE') ?? '';
      final content = _getTextPreserve(record, 'CONTENU') ?? '';
      
      if (code.isEmpty) { errors++; continue; }
      
      stmt.execute([originalId, code, content]);
      success++;
      print('  ✓ $code');
    } catch (e) {
      errors++;
      print('  ⚠️ Error: $e');
    }
  }
  
  stmt.dispose();
  
  print('');
  print('✅ Import complete!');
  print('   Success: $success');
  print('   Errors: $errors');
  
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
  text = text.trim();
  return text.isEmpty ? null : text;
}

int? _getInt(XmlElement parent, String name) {
  final text = _getText(parent, name);
  return text == null ? null : int.tryParse(text);
}
