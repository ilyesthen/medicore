import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'package:intl/intl.dart';
import 'patients_repository.dart';

/// Service for importing patients from XML file
class XmlImportService {
  final PatientsRepository _repository;

  XmlImportService(this._repository);

  /// Parse date string from XML (format: dd/MM/yyyy)
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    
    try {
      final format = DateFormat('dd/MM/yyyy');
      return format.parse(dateStr.trim());
    } catch (e) {
      return null;
    }
  }

  /// Import patients from XML file
  Future<ImportResult> importFromXml(String filePath) async {
    int successCount = 0;
    int errorCount = 0;
    final errors = <String>[];

    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return ImportResult(
          successCount: 0,
          errorCount: 1,
          errors: ['Fichier non trouvé: $filePath'],
        );
      }

      // Read and parse XML
      final xmlString = await file.readAsString();
      final document = xml.XmlDocument.parse(xmlString);

      // Find all patient records
      final patients = document.findAllElements('Table_Contenu');

      for (final patientElement in patients) {
        try {
          // Extract patient data
          final code = int.tryParse(
            patientElement.findElements('CDEP').firstOrNull?.innerText ?? '',
          );
          
          if (code == null) {
            errorCount++;
            errors.add('Code patient manquant pour un enregistrement');
            continue;
          }

          final barcode = patientElement
              .findElements('CODE_B')
              .firstOrNull
              ?.innerText
              .trim();
              
          if (barcode == null || barcode.isEmpty) {
            errorCount++;
            errors.add('Code-barres manquant pour patient #$code');
            continue;
          }

          final firstName = patientElement
              .findElements('PRP')
              .firstOrNull
              ?.innerText
              .trim();
              
          if (firstName == null || firstName.isEmpty) {
            errorCount++;
            errors.add('Prénom manquant pour patient #$code');
            continue;
          }

          final lastName = patientElement
              .findElements('NOMP')
              .firstOrNull
              ?.innerText
              .trim();
              
          if (lastName == null || lastName.isEmpty) {
            errorCount++;
            errors.add('Nom manquant pour patient #$code');
            continue;
          }

          final createdAtStr = patientElement
              .findElements('crée_le')
              .firstOrNull
              ?.innerText
              .trim();
          final createdAt = _parseDate(createdAtStr) ?? DateTime.now();

          final ageStr = patientElement
              .findElements('AGE')
              .firstOrNull
              ?.innerText
              .trim();
          final age = ageStr != null && ageStr.isNotEmpty 
              ? int.tryParse(ageStr) 
              : null;

          final dateOfBirthStr = patientElement
              .findElements('DATEN')
              .firstOrNull
              ?.innerText
              .trim();
          final dateOfBirth = _parseDate(dateOfBirthStr);

          final address = patientElement
              .findElements('ADP')
              .firstOrNull
              ?.innerText
              .trim();

          final phoneNumber = patientElement
              .findElements('TEL')
              .firstOrNull
              ?.innerText
              .trim();

          final otherInfo = patientElement
              .findElements('INFOR_UTILES')
              .firstOrNull
              ?.innerText
              .trim();

          // Import patient
          await _repository.importPatient(
            code: code,
            barcode: barcode,
            createdAt: createdAt,
            firstName: firstName,
            lastName: lastName,
            age: age,
            dateOfBirth: dateOfBirth,
            address: address?.isEmpty ?? true ? null : address,
            phoneNumber: phoneNumber?.isEmpty ?? true ? null : phoneNumber,
            otherInfo: otherInfo?.isEmpty ?? true ? null : otherInfo,
          );

          successCount++;
        } catch (e) {
          errorCount++;
          errors.add('Erreur lors de l\'import: $e');
        }
      }

      // Delete XML file after successful import
      if (successCount > 0) {
        try {
          await file.delete();
        } catch (e) {
          errors.add('Impossible de supprimer le fichier XML: $e');
        }
      }

      return ImportResult(
        successCount: successCount,
        errorCount: errorCount,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        successCount: successCount,
        errorCount: errorCount + 1,
        errors: [...errors, 'Erreur générale: $e'],
      );
    }
  }
}

/// Result of XML import operation
class ImportResult {
  final int successCount;
  final int errorCount;
  final List<String> errors;

  ImportResult({
    required this.successCount,
    required this.errorCount,
    required this.errors,
  });

  bool get hasErrors => errorCount > 0;
  bool get isSuccess => successCount > 0 && errorCount == 0;
}
