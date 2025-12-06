import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'data_repository.dart';

/// Local repository implementation - uses Drift database directly
/// Used when app is in ADMIN mode
class LocalRepository implements DataRepository {
  final AppDatabase _db;
  
  LocalRepository(this._db);
  
  // ==================== USERS ====================
  
  @override
  Future<List<User>> getAllUsers() async {
    return await _db.select(_db.users).get();
  }
  
  @override
  Future<User?> getUserById(int id) async {
    return await (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingleOrNull();
  }
  
  @override
  Future<User?> getUserByUsername(String username) async {
    return await (_db.select(_db.users)..where((u) => u.username.equals(username))).getSingleOrNull();
  }
  
  @override
  Future<int> createUser(UsersCompanion user) async {
    return await _db.into(_db.users).insert(user);
  }
  
  @override
  Future<void> updateUser(User user) async {
    await _db.update(_db.users).replace(user);
  }
  
  @override
  Future<void> deleteUser(int id) async {
    await (_db.delete(_db.users)..where((u) => u.id.equals(id))).go();
  }
  
  // ==================== ROOMS ====================
  
  @override
  Future<List<Room>> getAllRooms() async {
    return await _db.select(_db.rooms).get();
  }
  
  @override
  Future<Room?> getRoomById(int id) async {
    return await (_db.select(_db.rooms)..where((r) => r.id.equals(id))).getSingleOrNull();
  }
  
  @override
  Future<int> createRoom(RoomsCompanion room) async {
    return await _db.into(_db.rooms).insert(room);
  }
  
  @override
  Future<void> updateRoom(Room room) async {
    await _db.update(_db.rooms).replace(room);
  }
  
  @override
  Future<void> deleteRoom(int id) async {
    await (_db.delete(_db.rooms)..where((r) => r.id.equals(id))).go();
  }
  
  // ==================== PATIENTS ====================
  
  @override
  Future<List<Patient>> getAllPatients() async {
    return await _db.select(_db.patients).get();
  }
  
  @override
  Future<Patient?> getPatientByCode(int code) async {
    return await (_db.select(_db.patients)..where((p) => p.code.equals(code))).getSingleOrNull();
  }
  
  @override
  Future<List<Patient>> searchPatients(String query) async {
    final q = query.toLowerCase();
    return await (_db.select(_db.patients)
      ..where((p) => 
        p.firstName.lower().like('%$q%') | 
        p.lastName.lower().like('%$q%') |
        p.code.cast<String>().like('%$q%')
      )).get();
  }
  
  @override
  Future<int> createPatient(PatientsCompanion patient) async {
    return await _db.into(_db.patients).insert(patient);
  }
  
  @override
  Future<void> updatePatient(Patient patient) async {
    await _db.update(_db.patients).replace(patient);
  }
  
  @override
  Future<void> deletePatient(int code) async {
    await (_db.delete(_db.patients)..where((p) => p.code.equals(code))).go();
  }
  
  // ==================== MESSAGES ====================
  
  @override
  Future<List<Message>> getMessagesByRecipient(int userId) async {
    return await (_db.select(_db.messages)
      ..where((m) => m.recipientId.equals(userId))
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])).get();
  }
  
  @override
  Future<List<Message>> getUnreadMessages(int userId) async {
    return await (_db.select(_db.messages)
      ..where((m) => m.recipientId.equals(userId) & m.isRead.equals(false))
      ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])).get();
  }
  
  @override
  Future<int> createMessage(MessagesCompanion message) async {
    return await _db.into(_db.messages).insert(message);
  }
  
  @override
  Future<void> markMessageAsRead(int messageId) async {
    await (_db.update(_db.messages)..where((m) => m.id.equals(messageId)))
      .write(const MessagesCompanion(isRead: Value(true)));
  }
  
  @override
  Future<void> deleteMessage(int messageId) async {
    await (_db.delete(_db.messages)..where((m) => m.id.equals(messageId))).go();
  }
  
  // ==================== WAITING PATIENTS ====================
  
  @override
  Future<List<WaitingPatient>> getWaitingPatients() async {
    return await (_db.select(_db.waitingPatients)
      ..orderBy([(w) => OrderingTerm.asc(w.arrivalTime)])).get();
  }
  
  @override
  Future<List<WaitingPatient>> getWaitingPatientsByRoom(int roomId) async {
    return await (_db.select(_db.waitingPatients)
      ..where((w) => w.roomId.equals(roomId))
      ..orderBy([(w) => OrderingTerm.asc(w.arrivalTime)])).get();
  }
  
  @override
  Future<int> addWaitingPatient(WaitingPatientsCompanion patient) async {
    return await _db.into(_db.waitingPatients).insert(patient);
  }
  
  @override
  Future<void> updateWaitingPatient(WaitingPatient patient) async {
    await _db.update(_db.waitingPatients).replace(patient);
  }
  
  @override
  Future<void> removeWaitingPatient(int id) async {
    await (_db.delete(_db.waitingPatients)..where((w) => w.id.equals(id))).go();
  }
  
  @override
  Future<void> clearWaitingRoom() async {
    await _db.delete(_db.waitingPatients).go();
  }
  
  // ==================== VISITS ====================
  
  @override
  Future<List<Visit>> getVisitsByPatient(int patientCode) async {
    return await (_db.select(_db.visits)
      ..where((v) => v.patientCode.equals(patientCode))
      ..orderBy([(v) => OrderingTerm.desc(v.visitDate)])).get();
  }
  
  @override
  Future<List<Visit>> getVisitsByDoctor(int userId) async {
    return await (_db.select(_db.visits)
      ..where((v) => v.userId.equals(userId))
      ..orderBy([(v) => OrderingTerm.desc(v.visitDate)])).get();
  }
  
  @override
  Future<List<Visit>> getTodayVisits() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return await (_db.select(_db.visits)
      ..where((v) => v.visitDate.isBiggerOrEqualValue(startOfDay) & 
                     v.visitDate.isSmallerThanValue(endOfDay))
      ..orderBy([(v) => OrderingTerm.desc(v.visitDate)])).get();
  }
  
  @override
  Future<int> createVisit(VisitsCompanion visit) async {
    return await _db.into(_db.visits).insert(visit);
  }
  
  @override
  Future<void> updateVisit(Visit visit) async {
    await _db.update(_db.visits).replace(visit);
  }
  
  // ==================== MEDICAL ACTS ====================
  
  @override
  Future<List<MedicalAct>> getAllMedicalActs() async {
    return await _db.select(_db.medicalActs).get();
  }
  
  @override
  Future<MedicalAct?> getMedicalActById(int id) async {
    return await (_db.select(_db.medicalActs)..where((m) => m.id.equals(id))).getSingleOrNull();
  }
  
  // ==================== ORDONNANCES ====================
  
  @override
  Future<List<Ordonnance>> getOrdonnancesByPatient(int patientCode) async {
    return await (_db.select(_db.ordonnances)
      ..where((o) => o.patientCode.equals(patientCode))
      ..orderBy([(o) => OrderingTerm.desc(o.date)])).get();
  }
  
  @override
  Future<int> createOrdonnance(OrdonnancesCompanion ordonnance) async {
    return await _db.into(_db.ordonnances).insert(ordonnance);
  }
  
  @override
  Future<void> updateOrdonnance(Ordonnance ordonnance) async {
    await _db.update(_db.ordonnances).replace(ordonnance);
  }
  
  @override
  Future<void> deleteOrdonnance(int id) async {
    await (_db.delete(_db.ordonnances)..where((o) => o.id.equals(id))).go();
  }
  
  // ==================== MEDICATIONS ====================
  
  @override
  Future<List<Medication>> getMedicationsByOrdonnance(int ordonnanceId) async {
    return await (_db.select(_db.medications)
      ..where((m) => m.ordonnanceId.equals(ordonnanceId))).get();
  }
  
  @override
  Future<int> createMedication(MedicationsCompanion medication) async {
    return await _db.into(_db.medications).insert(medication);
  }
  
  @override
  Future<void> deleteMedication(int id) async {
    await (_db.delete(_db.medications)..where((m) => m.id.equals(id))).go();
  }
  
  // ==================== PAYMENTS ====================
  
  @override
  Future<List<Payment>> getPaymentsByPatient(int patientCode) async {
    return await (_db.select(_db.payments)
      ..where((p) => p.patientCode.equals(patientCode))
      ..orderBy([(p) => OrderingTerm.desc(p.date)])).get();
  }
  
  @override
  Future<List<Payment>> getPaymentsByDateRange(DateTime start, DateTime end) async {
    return await (_db.select(_db.payments)
      ..where((p) => p.date.isBiggerOrEqualValue(start) & p.date.isSmallerOrEqualValue(end))
      ..orderBy([(p) => OrderingTerm.desc(p.date)])).get();
  }
  
  @override
  Future<int> createPayment(PaymentsCompanion payment) async {
    return await _db.into(_db.payments).insert(payment);
  }
  
  @override
  Future<void> updatePayment(Payment payment) async {
    await _db.update(_db.payments).replace(payment);
  }
  
  // ==================== TEMPLATES ====================
  
  @override
  Future<List<Template>> getAllTemplates() async {
    return await _db.select(_db.templates).get();
  }
  
  @override
  Future<Template?> getTemplateById(int id) async {
    return await (_db.select(_db.templates)..where((t) => t.id.equals(id))).getSingleOrNull();
  }
  
  @override
  Future<int> createTemplate(TemplatesCompanion template) async {
    return await _db.into(_db.templates).insert(template);
  }
  
  @override
  Future<void> updateTemplate(Template template) async {
    await _db.update(_db.templates).replace(template);
  }
  
  @override
  Future<void> deleteTemplate(int id) async {
    await (_db.delete(_db.templates)..where((t) => t.id.equals(id))).go();
  }
  
  // ==================== MESSAGE TEMPLATES ====================
  
  @override
  Future<List<MessageTemplate>> getAllMessageTemplates() async {
    return await _db.select(_db.messageTemplates).get();
  }
  
  @override
  Future<MessageTemplate?> getMessageTemplateById(int id) async {
    return await (_db.select(_db.messageTemplates)..where((m) => m.id.equals(id))).getSingleOrNull();
  }
}
