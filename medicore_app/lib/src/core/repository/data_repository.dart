import '../database/app_database.dart';

/// Abstract repository for all data operations
/// Implemented by LocalRepository (admin) and RemoteRepository (client via gRPC)
abstract class DataRepository {
  // ==================== USERS ====================
  Future<List<User>> getAllUsers();
  Future<User?> getUserById(int id);
  Future<User?> getUserByUsername(String username);
  Future<int> createUser(UsersCompanion user);
  Future<void> updateUser(User user);
  Future<void> deleteUser(int id);
  
  // ==================== ROOMS ====================
  Future<List<Room>> getAllRooms();
  Future<Room?> getRoomById(int id);
  Future<int> createRoom(RoomsCompanion room);
  Future<void> updateRoom(Room room);
  Future<void> deleteRoom(int id);
  
  // ==================== PATIENTS ====================
  Future<List<Patient>> getAllPatients();
  Future<Patient?> getPatientByCode(int code);
  Future<List<Patient>> searchPatients(String query);
  Future<int> createPatient(PatientsCompanion patient);
  Future<void> updatePatient(Patient patient);
  Future<void> deletePatient(int code);
  
  // ==================== MESSAGES ====================
  Future<List<Message>> getMessagesByRecipient(int userId);
  Future<List<Message>> getUnreadMessages(int userId);
  Future<int> createMessage(MessagesCompanion message);
  Future<void> markMessageAsRead(int messageId);
  Future<void> deleteMessage(int messageId);
  
  // ==================== WAITING PATIENTS ====================
  Future<List<WaitingPatient>> getWaitingPatients();
  Future<List<WaitingPatient>> getWaitingPatientsByRoom(int roomId);
  Future<int> addWaitingPatient(WaitingPatientsCompanion patient);
  Future<void> updateWaitingPatient(WaitingPatient patient);
  Future<void> removeWaitingPatient(int id);
  Future<void> clearWaitingRoom();
  
  // ==================== VISITS ====================
  Future<List<Visit>> getVisitsByPatient(int patientCode);
  Future<List<Visit>> getVisitsByDoctor(int userId);
  Future<List<Visit>> getTodayVisits();
  Future<int> createVisit(VisitsCompanion visit);
  Future<void> updateVisit(Visit visit);
  
  // ==================== MEDICAL ACTS ====================
  Future<List<MedicalAct>> getAllMedicalActs();
  Future<MedicalAct?> getMedicalActById(int id);
  
  // ==================== ORDONNANCES ====================
  Future<List<Ordonnance>> getOrdonnancesByPatient(int patientCode);
  Future<int> createOrdonnance(OrdonnancesCompanion ordonnance);
  Future<void> updateOrdonnance(Ordonnance ordonnance);
  Future<void> deleteOrdonnance(int id);
  
  // ==================== MEDICATIONS ====================
  Future<List<Medication>> getMedicationsByOrdonnance(int ordonnanceId);
  Future<int> createMedication(MedicationsCompanion medication);
  Future<void> deleteMedication(int id);
  
  // ==================== PAYMENTS ====================
  Future<List<Payment>> getPaymentsByPatient(int patientCode);
  Future<List<Payment>> getPaymentsByDateRange(DateTime start, DateTime end);
  Future<int> createPayment(PaymentsCompanion payment);
  Future<void> updatePayment(Payment payment);
  
  // ==================== TEMPLATES ====================
  Future<List<Template>> getAllTemplates();
  Future<Template?> getTemplateById(int id);
  Future<int> createTemplate(TemplatesCompanion template);
  Future<void> updateTemplate(Template template);
  Future<void> deleteTemplate(int id);
  
  // ==================== MESSAGE TEMPLATES ====================
  Future<List<MessageTemplate>> getAllMessageTemplates();
  Future<MessageTemplate?> getMessageTemplateById(int id);
}
