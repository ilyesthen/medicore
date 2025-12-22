import 'dart:io';
import 'package:xml/xml.dart' as xml;
import 'package:intl/intl.dart';
import 'payments_repository.dart';
import '../../../core/generated/medicore.pb.dart';

/// Service for importing payments from XML file
/// Handles the migration from the legacy WINDEV system
class PaymentsXmlImportService {
  final PaymentsRepository _repository;
  final AppDatabase _database;

  // Cache for patients and users to avoid repeated lookups
  final Map<int, Patient> _patientCache = {};
  final Map<String, UserEntity> _userCache = {};

  PaymentsXmlImportService(this._repository, this._database);

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

  /// Parse time string from XML (format: HH:mm)
  /// Returns hour and minute as a pair
  (int hour, int minute)? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return (hour, minute);
      }
    } catch (e) {
      // Ignore parse errors
    }
    return null;
  }

  /// Get text content from an XML element safely
  String? _getElementText(xml.XmlElement element, String tagName) {
    final found = element.findElements(tagName).firstOrNull;
    return found?.innerText.trim();
  }

  /// Get patient from cache or database
  Future<Patient?> _getPatient(int code) async {
    if (_patientCache.containsKey(code)) {
      return _patientCache[code];
    }
    
    final patient = await _repository.getPatientByCode(code);
    if (patient != null) {
      _patientCache[code] = patient;
    }
    return patient;
  }

  /// Get user from cache or database
  Future<UserEntity?> _getUser(String name) async {
    if (_userCache.containsKey(name)) {
      return _userCache[name];
    }
    
    final user = await _repository.getUserByName(name);
    if (user != null) {
      _userCache[name] = user;
    }
    return user;
  }

  /// Preload all patients into cache for faster import
  Future<void> _preloadPatients() async {
    final patients = await _database.select(_database.patients).get();
    for (final patient in patients) {
      _patientCache[patient.code] = patient;
    }
  }

  /// Preload all users into cache for faster import
  Future<void> _preloadUsers() async {
    final users = await (_database.select(_database.users)
          ..where((u) => u.deletedAt.isNull()))
        .get();
    for (final user in users) {
      _userCache[user.name] = user;
    }
  }

  /// Import payments from XML file
  /// Uses streaming for large files to avoid memory issues
  Future<PaymentsImportResult> importFromXml(String filePath, {
    Function(int current, int total)? onProgress,
  }) async {
    int successCount = 0;
    int errorCount = 0;
    int skippedNoPatient = 0;
    int skippedNoUser = 0;
    final errors = <String>[];
    final Set<String> uniqueUserNames = {};
    final Set<int> missingPatientCodes = {};

    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return PaymentsImportResult(
          successCount: 0,
          errorCount: 1,
          skippedNoPatient: 0,
          skippedNoUser: 0,
          errors: ['Fichier non trouvé: $filePath'],
        );
      }

      print('📂 Préchargement des patients et utilisateurs...');
      await _preloadPatients();
      await _preloadUsers();
      print('   Patients en cache: ${_patientCache.length}');
      print('   Utilisateurs en cache: ${_userCache.length}');

      print('📄 Lecture du fichier XML...');
      
      // Read and parse XML
      final xmlString = await file.readAsString();
      final document = xml.XmlDocument.parse(xmlString);

      // Find all payment records
      final payments = document.findAllElements('Table_Contenu').toList();
      final totalPayments = payments.length;
      print('   Paiements trouvés: $totalPayments');

      // Process in batches for efficiency
      const batchSize = 1000;
      List<Map<String, dynamic>> batch = [];
      int processedCount = 0;

      for (final paymentElement in payments) {
        try {
          // Extract payment data
          final idStr = _getElementText(paymentElement, 'N__Enr.');
          final id = int.tryParse(idStr ?? '');
          
          if (id == null) {
            errorCount++;
            errors.add('ID manquant pour un paiement');
            continue;
          }

          final medicalActIdStr = _getElementText(paymentElement, 'IDHONORAIRE');
          final medicalActId = int.tryParse(medicalActIdStr ?? '') ?? 0;

          // ACTE has priority over IDHONORAIRE for the act name
          final acteName = _getElementText(paymentElement, 'ACTE') ?? '';
          
          // MONATNT (amount) - if filled, it has priority
          final montantStr = _getElementText(paymentElement, 'MONATNT');
          final amount = int.tryParse(montantStr ?? '') ?? 0;

          // MEDCIN - the doctor who will see this payment
          final medcinName = _getElementText(paymentElement, 'MEDCIN') ?? '';
          uniqueUserNames.add(medcinName);
          
          // Look up user - if not found, skip but keep track
          final user = await _getUser(medcinName);
          if (user == null) {
            skippedNoUser++;
            // We still import it, but with userName only (userId empty)
            // The user can create the account later and see the data
          }

          // CDEP - patient code
          final cdepStr = _getElementText(paymentElement, 'CDEP');
          final patientCode = int.tryParse(cdepStr ?? '');
          
          if (patientCode == null) {
            errorCount++;
            errors.add('Code patient manquant pour paiement #$id');
            continue;
          }

          // Look up patient
          final patient = await _getPatient(patientCode);
          String patientFirstName = '';
          String patientLastName = '';
          
          if (patient != null) {
            patientFirstName = patient.firstName;
            patientLastName = patient.lastName;
          } else {
            missingPatientCodes.add(patientCode);
            skippedNoPatient++;
            // Still import with empty patient names - can be updated later
          }

          // Parse date and time
          final dateStr = _getElementText(paymentElement, 'DATE');
          final timeStr = _getElementText(paymentElement, 'HORAIR');
          
          DateTime paymentTime;
          final date = _parseDate(dateStr);
          if (date != null) {
            final time = _parseTime(timeStr);
            if (time != null) {
              paymentTime = DateTime(date.year, date.month, date.day, time.$1, time.$2);
            } else {
              paymentTime = date;
            }
          } else {
            paymentTime = DateTime.now();
          }

          // Add to batch
          batch.add({
            'id': id,
            'medicalActId': medicalActId,
            'medicalActName': acteName,
            'amount': amount,
            'userId': user?.id ?? '',
            'userName': medcinName,
            'patientCode': patientCode,
            'patientFirstName': patientFirstName,
            'patientLastName': patientLastName,
            'paymentTime': paymentTime,
          });

          successCount++;
          processedCount++;

          // Process batch when full
          if (batch.length >= batchSize) {
            await _repository.batchImportPayments(batch);
            batch.clear();
            
            if (onProgress != null) {
              onProgress(processedCount, totalPayments);
            }
            
            // Print progress
            final percent = (processedCount / totalPayments * 100).toStringAsFixed(1);
            print('   Progression: $processedCount / $totalPayments ($percent%)');
          }
        } catch (e) {
          errorCount++;
          if (errors.length < 100) {
            errors.add('Erreur lors de l\'import: $e');
          }
        }
      }

      // Process remaining batch
      if (batch.isNotEmpty) {
        await _repository.batchImportPayments(batch);
        batch.clear();
      }

      print('\n📊 Statistiques d\'import:');
      print('   Utilisateurs uniques trouvés: ${uniqueUserNames.length}');
      print('   Utilisateurs: $uniqueUserNames');
      if (missingPatientCodes.isNotEmpty && missingPatientCodes.length <= 20) {
        print('   Patients manquants (codes): $missingPatientCodes');
      } else if (missingPatientCodes.isNotEmpty) {
        print('   Patients manquants: ${missingPatientCodes.length} codes');
      }

      return PaymentsImportResult(
        successCount: successCount,
        errorCount: errorCount,
        skippedNoPatient: skippedNoPatient,
        skippedNoUser: skippedNoUser,
        errors: errors,
        uniqueUserNames: uniqueUserNames.toList(),
      );
    } catch (e) {
      return PaymentsImportResult(
        successCount: successCount,
        errorCount: errorCount + 1,
        skippedNoPatient: skippedNoPatient,
        skippedNoUser: skippedNoUser,
        errors: [...errors, 'Erreur générale: $e'],
      );
    }
  }
}

/// Result of payments XML import operation
class PaymentsImportResult {
  final int successCount;
  final int errorCount;
  final int skippedNoPatient;
  final int skippedNoUser;
  final List<String> errors;
  final List<String> uniqueUserNames;

  PaymentsImportResult({
    required this.successCount,
    required this.errorCount,
    required this.skippedNoPatient,
    required this.skippedNoUser,
    required this.errors,
    this.uniqueUserNames = const [],
  });

  bool get hasErrors => errorCount > 0;
  bool get isSuccess => successCount > 0;
}
