import 'dart:async';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';

/// Repository for managing payments (Comptabilité)
/// Handles all database operations for payment records
class PaymentsRepository {
  final AppDatabase _database;

  PaymentsRepository(this._database);

  /// Watch all payments for a specific user on a specific date with time filter
  /// timeFilter: 'all' | 'morning' | 'afternoon'
  /// - Morning: before 13:00 (1 PM)
  /// - Afternoon: 13:00 and later
  Stream<List<Payment>> watchPaymentsByUserAndDate({
    required String userName,
    required DateTime date,
    required String timeFilter,
  }) {
    // Use date string for reliable comparison (avoids timezone issues)
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    // Client mode: use REST API with polling
    if (!GrpcClientConfig.isServer) {
      return _watchPaymentsRemote(userName, dateStr, timeFilter);
    }
    
    // Use raw SQL query for reliable date filtering
    // Handle both ISO string dates (new) and integer timestamps (legacy imported data)
    final query = _database.customSelect(
      '''
      SELECT * FROM payments 
      WHERE user_name = ? 
        AND (
          date(payment_time) = ?
          OR date(payment_time / 1000, 'unixepoch', 'localtime') = ?
        )
        AND is_active = 1
      ORDER BY payment_time ASC
      ''',
      variables: [
        Variable.withString(userName), 
        Variable.withString(dateStr),
        Variable.withString(dateStr),
      ],
      readsFrom: {_database.payments},
    );
    
    return query.watch().map((rows) {
      final payments = rows.map((row) {
        // Handle both ISO string and integer timestamp formats
        DateTime parseDateTime(String columnName) {
          final data = row.data;
          final raw = data[columnName];
          if (raw is int) {
            return DateTime.fromMillisecondsSinceEpoch(raw);
          } else if (raw is String) {
            // Parse and convert to local time
            final parsed = DateTime.parse(raw);
            return parsed.toLocal();
          }
          return DateTime.now();
        }
        
        return Payment(
          id: row.read<int>('id'),
          medicalActId: row.read<int>('medical_act_id'),
          medicalActName: row.read<String>('medical_act_name'),
          amount: row.read<int>('amount'),
          userId: row.read<String>('user_id'),
          userName: row.read<String>('user_name'),
          patientCode: row.read<int>('patient_code'),
          patientFirstName: row.read<String>('patient_first_name'),
          patientLastName: row.read<String>('patient_last_name'),
          paymentTime: parseDateTime('payment_time'),
          createdAt: parseDateTime('created_at'),
          updatedAt: parseDateTime('updated_at'),
          needsSync: row.read<bool>('needs_sync'),
          isActive: row.read<bool>('is_active'),
        );
      }).toList();
      
      if (timeFilter == 'morning') {
        // Filter for morning: before 13:00
        return payments.where((p) => p.paymentTime.hour < 13).toList();
      } else if (timeFilter == 'afternoon') {
        // Filter for afternoon: 13:00 and later
        return payments.where((p) => p.paymentTime.hour >= 13).toList();
      }
      // 'all' or default: return all payments
      return payments;
    });
  }

  /// Create a new payment record
  Future<int> createPayment({
    required int medicalActId,
    required String medicalActName,
    required int amount,
    required String userId,
    required String userName,
    required int patientCode,
    required String patientFirstName,
    required String patientLastName,
    DateTime? paymentTime,
  }) async {
    final now = DateTime.now();
    final effectivePaymentTime = paymentTime ?? now;
    
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.createPayment({
          'medical_act_id': medicalActId,
          'medical_act_name': medicalActName,
          'amount': amount,
          'user_id': userId,
          'user_name': userName,
          'patient_code': patientCode,
          'patient_first_name': patientFirstName,
          'patient_last_name': patientLastName,
          'payment_time': effectivePaymentTime.toIso8601String(),
        });
      } catch (e) {
        print('❌ [PaymentsRepository] Remote create failed: $e');
        return -1;
      }
    }
    
    return await _database.into(_database.payments).insert(
      PaymentsCompanion.insert(
        medicalActId: medicalActId,
        medicalActName: medicalActName,
        amount: amount,
        userId: userId,
        userName: userName,
        patientCode: patientCode,
        patientFirstName: patientFirstName,
        patientLastName: patientLastName,
        paymentTime: effectivePaymentTime,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Update an existing payment
  Future<bool> updatePayment({
    required int id,
    required int medicalActId,
    required String medicalActName,
    required int amount,
    required int patientCode,
    required String patientFirstName,
    required String patientLastName,
    DateTime? paymentTime,
  }) async {
    final now = DateTime.now();
    
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.updatePayment({
          'id': id,
          'medical_act_id': medicalActId,
          'medical_act_name': medicalActName,
          'amount': amount,
          'patient_code': patientCode,
          'patient_first_name': patientFirstName,
          'patient_last_name': patientLastName,
          'payment_time': (paymentTime ?? now).toIso8601String(),
        });
        return true;
      } catch (e) {
        print('❌ [PaymentsRepository] Remote updatePayment failed: $e');
        return false;
      }
    }
    
    return await _database.update(_database.payments).replace(
      Payment(
        id: id,
        medicalActId: medicalActId,
        medicalActName: medicalActName,
        amount: amount,
        userId: '', // Will be filled from current record
        userName: '', // Will be filled from current record
        patientCode: patientCode,
        patientFirstName: patientFirstName,
        patientLastName: patientLastName,
        paymentTime: paymentTime ?? now,
        createdAt: now, // Will be filled from current record
        updatedAt: now,
        needsSync: true,
        isActive: true,
      ),
    );
  }

  /// Soft delete a payment (set isActive to false)
  Future<int> deletePayment(int id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.deletePayment(id);
        return 1;
      } catch (e) {
        print('❌ [PaymentsRepository] Remote delete failed: $e');
        return 0;
      }
    }
    return await (_database.update(_database.payments)
          ..where((p) => p.id.equals(id)))
        .write(
      PaymentsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
        needsSync: const Value(true),
      ),
    );
  }

  /// Delete all payments for a patient on a specific date
  /// Returns the count of deleted payments
  Future<int> deletePaymentsByPatientAndDate({
    required int patientCode,
    required DateTime date,
  }) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.deletePaymentsByPatientAndDate(patientCode, dateStr);
      } catch (e) {
        print('❌ [PaymentsRepository] Remote deletePaymentsByPatientAndDate failed: $e');
        return 0;
      }
    }
    
    // Find and soft-delete payments for this patient today
    // Handle both ISO string dates (new) and integer timestamps (legacy)
    final result = await _database.customUpdate(
      '''
      UPDATE payments 
      SET is_active = 0, updated_at = ?, needs_sync = 1
      WHERE patient_code = ? 
        AND is_active = 1
        AND (
          date(payment_time) = ?
          OR date(payment_time / 1000, 'unixepoch', 'localtime') = ?
        )
      ''',
      variables: [
        Variable.withString(DateTime.now().toIso8601String()),
        Variable.withInt(patientCode),
        Variable.withString(dateStr),
        Variable.withString(dateStr),
      ],
      updates: {_database.payments},
    );
    
    return result;
  }

  /// Count payments for a patient on a specific date
  Future<int> countPaymentsByPatientAndDate({
    required int patientCode,
    required DateTime date,
  }) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.countPaymentsByPatientAndDate(patientCode, dateStr);
      } catch (e) {
        print('❌ [PaymentsRepository] Remote countPaymentsByPatientAndDate failed: $e');
        return 0;
      }
    }
    
    final result = await _database.customSelect(
      '''
      SELECT COUNT(*) as count FROM payments 
      WHERE patient_code = ? 
        AND is_active = 1
        AND (
          date(payment_time) = ?
          OR date(payment_time / 1000, 'unixepoch', 'localtime') = ?
        )
      ''',
      variables: [
        Variable.withInt(patientCode),
        Variable.withString(dateStr),
        Variable.withString(dateStr),
      ],
    ).getSingle();
    
    return result.read<int>('count');
  }

  /// Get payment by ID
  Future<Payment?> getPaymentById(int id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getPaymentById(id);
        if (response.isEmpty) return null;
        return Payment(
          id: (response['id'] as num).toInt(),
          medicalActId: (response['medical_act_id'] as num).toInt(),
          medicalActName: response['medical_act_name'] as String,
          amount: (response['amount'] as num).toInt(),
          userId: response['user_id'] as String,
          userName: response['user_name'] as String,
          patientCode: (response['patient_code'] as num).toInt(),
          patientFirstName: response['patient_first_name'] as String,
          patientLastName: response['patient_last_name'] as String,
          paymentTime: DateTime.tryParse(response['payment_time'] as String) ?? DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          needsSync: false,
          isActive: true,
        );
      } catch (e) {
        print('❌ [PaymentsRepository] Remote getPaymentById failed: $e');
        return null;
      }
    }
    return await (_database.select(_database.payments)
          ..where((p) => p.id.equals(id))
          ..where((p) => p.isActive.equals(true)))
        .getSingleOrNull();
  }

  /// Get all payments for a user (for reporting)
  Future<List<Payment>> getAllPaymentsByUser(String userId) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getAllPaymentsByUser(userId);
        final payments = (response['payments'] as List<dynamic>?) ?? [];
        return payments.map((p) {
          final json = p as Map<String, dynamic>;
          return Payment(
            id: (json['id'] as num).toInt(),
            medicalActId: (json['medical_act_id'] as num).toInt(),
            medicalActName: json['medical_act_name'] as String,
            amount: (json['amount'] as num).toInt(),
            userId: userId,
            userName: userId,
            patientCode: (json['patient_code'] as num).toInt(),
            patientFirstName: json['patient_first_name'] as String,
            patientLastName: json['patient_last_name'] as String,
            paymentTime: DateTime.tryParse(json['payment_time'] as String) ?? DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            needsSync: false,
            isActive: true,
          );
        }).toList();
      } catch (e) {
        print('❌ [PaymentsRepository] Remote getAllPaymentsByUser failed: $e');
        return [];
      }
    }
    return await (_database.select(_database.payments)
          ..where((p) => p.userId.equals(userId))
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm(expression: p.paymentTime, mode: OrderingMode.desc)]))
        .get();
  }

  /// Calculate total amount for a list of payments
  int calculateTotalAmount(List<Payment> payments) {
    return payments.fold(0, (sum, payment) => sum + payment.amount);
  }

  /// Count total patients for a list of payments
  int countUniquePatients(List<Payment> payments) {
    final uniquePatientCodes = <int>{};
    for (var payment in payments) {
      uniquePatientCodes.add(payment.patientCode);
    }
    return uniquePatientCodes.length;
  }

  /// Group payments by medical act and calculate summary
  /// Returns Map<actName, {count: int, totalAmount: int}>
  Map<String, Map<String, int>> groupPaymentsByAct(List<Payment> payments) {
    final Map<String, Map<String, int>> grouped = {};
    
    for (var payment in payments) {
      if (!grouped.containsKey(payment.medicalActName)) {
        grouped[payment.medicalActName] = {
          'count': 0,
          'totalAmount': 0,
        };
      }
      grouped[payment.medicalActName]!['count'] = 
          (grouped[payment.medicalActName]!['count'] ?? 0) + 1;
      grouped[payment.medicalActName]!['totalAmount'] = 
          (grouped[payment.medicalActName]!['totalAmount'] ?? 0) + payment.amount;
    }
    
    return grouped;
  }

  /// Import payment from XML data (used for migration)
  /// Inserts with specific ID for data integrity
  Future<void> importPayment({
    required int id,
    required int medicalActId,
    required String medicalActName,
    required int amount,
    required String userId,
    required String userName,
    required int patientCode,
    required String patientFirstName,
    required String patientLastName,
    required DateTime paymentTime,
  }) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.importPayment({
          'id': id,
          'medical_act_id': medicalActId,
          'medical_act_name': medicalActName,
          'amount': amount,
          'user_id': userId,
          'user_name': userName,
          'patient_code': patientCode,
          'patient_first_name': patientFirstName,
          'patient_last_name': patientLastName,
          'payment_time': paymentTime.toIso8601String(),
        });
        return;
      } catch (e) {
        print('❌ [PaymentsRepository] Remote importPayment failed: $e');
        rethrow;
      }
    }
    
    // Drift expects milliseconds since epoch
    final timeMs = paymentTime.millisecondsSinceEpoch;
    // Use raw SQL to insert with specific ID
    await _database.customStatement(
      '''
      INSERT OR REPLACE INTO payments (
        id, medical_act_id, medical_act_name, amount, user_id, user_name,
        patient_code, patient_first_name, patient_last_name, payment_time,
        created_at, updated_at, needs_sync, is_active
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        id,
        medicalActId,
        medicalActName,
        amount,
        userId,
        userName,
        patientCode,
        patientFirstName,
        patientLastName,
        timeMs,
        timeMs,
        timeMs,
        0, // needsSync = false for imported data
        1, // isActive = true
      ],
    );
  }

  /// Get the maximum payment ID (for continuing after import)
  Future<int> getMaxPaymentId() async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.getMaxPaymentId();
      } catch (e) {
        print('❌ [PaymentsRepository] Remote getMaxPaymentId failed: $e');
        return 0;
      }
    }
    final result = await _database.customSelect(
      'SELECT MAX(id) as max_id FROM payments',
    ).getSingleOrNull();
    return result?.read<int?>('max_id') ?? 0;
  }

  /// Get user by name (for import)
  Future<UserEntity?> getUserByName(String name) async {
    // Client mode: use remote (returns null as import is admin-only)
    if (!GrpcClientConfig.isServer) {
      // XML import is admin-only, but return null gracefully
      return null;
    }
    return await (_database.select(_database.users)
          ..where((u) => u.name.equals(name))
          ..where((u) => u.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Get patient by code (for import)
  Future<Patient?> getPatientByCode(int code) async {
    // Client mode: use remote (returns null as import is admin-only)
    if (!GrpcClientConfig.isServer) {
      // XML import is admin-only, but return null gracefully
      return null;
    }
    return await (_database.select(_database.patients)
          ..where((p) => p.code.equals(code)))
        .getSingleOrNull();
  }

  /// Batch import payments for efficiency using a transaction
  Future<void> batchImportPayments(List<Map<String, dynamic>> paymentDataList) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final paymentsData = paymentDataList.map((data) => {
          'id': data['id'],
          'medical_act_id': data['medicalActId'],
          'medical_act_name': data['medicalActName'],
          'amount': data['amount'],
          'user_id': data['userId'],
          'user_name': data['userName'],
          'patient_code': data['patientCode'],
          'patient_first_name': data['patientFirstName'],
          'patient_last_name': data['patientLastName'],
          'payment_time': (data['paymentTime'] as DateTime).toIso8601String(),
        }).toList();
        await MediCoreClient.instance.batchImportPayments(paymentsData);
        return;
      } catch (e) {
        print('❌ [PaymentsRepository] Remote batchImportPayments failed: $e');
        rethrow;
      }
    }
    
    await _database.transaction(() async {
      for (final data in paymentDataList) {
        // Drift expects milliseconds since epoch (not seconds)
        final paymentTime = (data['paymentTime'] as DateTime).millisecondsSinceEpoch;
        await _database.customStatement(
          '''
          INSERT OR REPLACE INTO payments (
            id, medical_act_id, medical_act_name, amount, user_id, user_name,
            patient_code, patient_first_name, patient_last_name, payment_time,
            created_at, updated_at, needs_sync, is_active
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            data['id'],
            data['medicalActId'],
            data['medicalActName'],
            data['amount'],
            data['userId'],
            data['userName'],
            data['patientCode'],
            data['patientFirstName'],
            data['patientLastName'],
            paymentTime,
            paymentTime,
            paymentTime,
            0, // needsSync = false
            1, // isActive = true
          ],
        );
      }
    });
  }
  
  // ==================== REMOTE API HELPERS ====================
  
  /// Watch payments from remote server with polling
  Stream<List<Payment>> _watchPaymentsRemote(String userName, String dateStr, String timeFilter) async* {
    // Fetch immediately
    yield await _fetchPaymentsRemote(userName, dateStr, timeFilter);
    
    // Then poll every 3 seconds
    await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
      yield await _fetchPaymentsRemote(userName, dateStr, timeFilter);
    }
  }
  
  /// Fetch payments from remote server
  Future<List<Payment>> _fetchPaymentsRemote(String userName, String dateStr, String timeFilter) async {
    try {
      print('📤 [PaymentsRepository] Fetching payments: user=$userName, date=$dateStr, filter=$timeFilter');
      final response = await MediCoreClient.instance.getPaymentsByUserAndDate(userName, dateStr);
      final paymentsJson = (response['payments'] as List<dynamic>?) ?? [];
      print('📥 [PaymentsRepository] Received ${paymentsJson.length} payments');
      
      var payments = paymentsJson.map((json) => _mapJsonToPayment(json as Map<String, dynamic>)).toList();
      
      // Apply time filter
      if (timeFilter == 'morning') {
        payments = payments.where((p) => p.paymentTime.hour < 13).toList();
      } else if (timeFilter == 'afternoon') {
        payments = payments.where((p) => p.paymentTime.hour >= 13).toList();
      }
      
      print('✅ [PaymentsRepository] Returning ${payments.length} payments after filter');
      return payments;
    } catch (e, stackTrace) {
      print('❌ [PaymentsRepository] Remote fetch failed: $e');
      print('📍 Stack trace: $stackTrace');
      return [];
    }
  }
  
  /// Map JSON to Payment object
  Payment _mapJsonToPayment(Map<String, dynamic> json) {
    DateTime parseTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
      return DateTime.now();
    }
    
    return Payment(
      id: (json['id'] as num).toInt(),
      medicalActId: (json['medical_act_id'] as num?)?.toInt() ?? 0,
      medicalActName: json['medical_act_name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
      patientCode: (json['patient_code'] as num?)?.toInt() ?? 0,
      patientFirstName: json['patient_first_name'] as String? ?? '',
      patientLastName: json['patient_last_name'] as String? ?? '',
      paymentTime: parseTime(json['payment_time']),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      needsSync: false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
