// ignore_for_file: avoid_print
import 'dart:io';
import 'package:xml/xml.dart';

/// Import ordonnances from XML file to SQL insert statements
/// Preserves exact formatting including line breaks and spaces
void main() async {
  final xmlFile = File('/Applications/eye/ordononce.xml');
  
  if (!await xmlFile.exists()) {
    print('❌ File not found: /Applications/eye/ordononce.xml');
    exit(1);
  }
  
  print('📖 Reading XML file...');
  final xmlContent = await xmlFile.readAsString();
  
  print('🔍 Parsing XML...');
  final document = XmlDocument.parse(xmlContent);
  final records = document.findAllElements('Table_Contenu');
  
  print('📊 Found ${records.length} records');
  
  // Output SQL file
  final sqlFile = File('/Applications/eye/medicore_app/scripts/ordonnances_import.sql');
  final sqlBuffer = StringBuffer();
  
  sqlBuffer.writeln('-- Ordonnances import from ordononce.xml');
  sqlBuffer.writeln('-- Generated: ${DateTime.now()}');
  sqlBuffer.writeln('-- Total records: ${records.length}');
  sqlBuffer.writeln();
  sqlBuffer.writeln('BEGIN TRANSACTION;');
  sqlBuffer.writeln();
  
  int count = 0;
  int errors = 0;
  
  for (final record in records) {
    try {
      final originalId = _getInt(record, 'N__Enr.');
      final patientCode = _getInt(record, 'CDEP');
      final dateOrd = _getText(record, 'DATEORD');
      final age = _getInt(record, 'AG2');
      final seq = _getInt(record, 'SEQ') ?? 1;
      final seqPat = _getText(record, 'SEQPAT');
      final doctorName = _getText(record, 'MEDCIN');
      final amount = _getDouble(record, 'SMONT') ?? 0;
      
      // Content fields - preserve exact formatting
      final content1 = _getTextPreserveFormat(record, 'STRAIT');
      final type1 = _getText(record, 'ACTEX') ?? 'ORDONNANCE';
      final content2 = _getTextPreserveFormat(record, 'strait1');
      final type2 = _getText(record, 'ACTEX1');
      final content3 = _getTextPreserveFormat(record, 'strait2');
      final type3 = _getText(record, 'ACTEX2');
      final additionalNotes = _getTextPreserveFormat(record, 'strait3');
      final reportTitle = _getText(record, 'titre_cr');
      final referredBy = _getText(record, 'ADressé_par');
      
      final rdvFlag = _getInt(record, 'rdvle') ?? 0;
      final rdvDate = _getText(record, 'datele');
      final rdvDay = _getText(record, 'jourle');
      
      // Parse date
      String? documentDate;
      if (dateOrd != null && dateOrd.isNotEmpty) {
        documentDate = _parseDate(dateOrd);
      }
      
      if (patientCode == null) {
        errors++;
        continue;
      }
      
      sqlBuffer.writeln('''INSERT INTO ordonnances (
  original_id, patient_code, document_date, patient_age, sequence, seq_pat,
  doctor_name, amount, content1, type1, content2, type2, content3, type3,
  additional_notes, report_title, referred_by, rdv_flag, rdv_date, rdv_day,
  created_at, updated_at
) VALUES (
  ${originalId ?? 'NULL'},
  $patientCode,
  ${documentDate != null ? "'$documentDate'" : 'NULL'},
  ${age ?? 'NULL'},
  $seq,
  ${_sqlString(seqPat)},
  ${_sqlString(doctorName)},
  $amount,
  ${_sqlString(content1)},
  ${_sqlString(type1)},
  ${_sqlString(content2)},
  ${_sqlString(type2)},
  ${_sqlString(content3)},
  ${_sqlString(type3)},
  ${_sqlString(additionalNotes)},
  ${_sqlString(reportTitle)},
  ${_sqlString(referredBy)},
  $rdvFlag,
  ${_sqlString(rdvDate)},
  ${_sqlString(rdvDay)},
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
);''');
      sqlBuffer.writeln();
      
      count++;
      if (count % 5000 == 0) {
        print('  Processed $count records...');
      }
    } catch (e) {
      errors++;
      print('  ⚠️ Error processing record: $e');
    }
  }
  
  sqlBuffer.writeln('COMMIT;');
  sqlBuffer.writeln();
  sqlBuffer.writeln('-- Import complete: $count records, $errors errors');
  
  await sqlFile.writeAsString(sqlBuffer.toString());
  
  print('');
  print('✅ SQL file generated: ${sqlFile.path}');
  print('   Records: $count');
  print('   Errors: $errors');
  print('');
  print('To import, run in SQLite:');
  print('   sqlite3 medicore.db < scripts/ordonnances_import.sql');
}

/// Get text content from element, returns null if empty
String? _getText(XmlElement parent, String name) {
  final elements = parent.findElements(name);
  if (elements.isEmpty) return null;
  final text = elements.first.innerText.trim();
  return text.isEmpty ? null : text;
}

/// Get text content preserving exact formatting (line breaks, spaces)
String? _getTextPreserveFormat(XmlElement parent, String name) {
  final elements = parent.findElements(name);
  if (elements.isEmpty) return null;
  
  // Get raw text, convert &#13; to newlines
  String text = elements.first.innerText;
  
  // Replace XML encoded CR with actual newline
  text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  
  // Trim only leading/trailing whitespace but preserve internal formatting
  text = text.trim();
  
  return text.isEmpty ? null : text;
}

/// Get integer value
int? _getInt(XmlElement parent, String name) {
  final text = _getText(parent, name);
  if (text == null) return null;
  return int.tryParse(text);
}

/// Get double value
double? _getDouble(XmlElement parent, String name) {
  final text = _getText(parent, name);
  if (text == null) return null;
  return double.tryParse(text);
}

/// Parse date from DD/MM/YYYY format
String? _parseDate(String dateStr) {
  try {
    final parts = dateStr.split('/');
    if (parts.length != 3) return null;
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    return '$year-$month-$day';
  } catch (e) {
    return null;
  }
}

/// Escape string for SQL, handling nulls
String _sqlString(String? value) {
  if (value == null || value.isEmpty) return 'NULL';
  // Escape single quotes by doubling them
  final escaped = value.replaceAll("'", "''");
  return "'$escaped'";
}
