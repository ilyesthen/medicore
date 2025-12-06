import 'package:drift/drift.dart' hide Value;
import 'package:grpc/grpc.dart';
import '../database/app_database.dart';
import '../generated/medicore.pbgrpc.dart' as pb;
import '../api/grpc_client.dart';
import 'data_repository.dart';

/// Remote repository implementation - uses gRPC to communicate with admin
/// Used when app is in CLIENT mode
class RemoteRepository implements DataRepository {
  late pb.MediCoreServiceClient _client;
  
  RemoteRepository() {
    final channel = GrpcClientConfig.getChannel();
    _client = pb.MediCoreServiceClient(channel);
  }
  
  // ==================== USERS ====================
  
  @override
  Future<List<User>> getAllUsers() async {
    final response = await _client.getAllUsers(pb.Empty());
    return response.users.map(_userFromProto).toList();
  }
  
  @override
  Future<User?> getUserById(int id) async {
    try {
      final response = await _client.getUserById(pb.IntId()..id = id);
      return _userFromProto(response);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) return null;
      rethrow;
    }
  }
  
  @override
  Future<User?> getUserByUsername(String username) async {
    try {
      final response = await _client.getUserByUsername(pb.UsernameRequest()..username = username);
      return _userFromProto(response);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) return null;
      rethrow;
    }
  }
  
  @override
  Future<int> createUser(UsersCompanion user) async {
    final request = pb.CreateUserRequest()
      ..username = user.username.value
      ..passwordHash = user.passwordHash.value
      ..fullName = user.fullName.value
      ..role = user.role.value;
    if (user.roomId.present && user.roomId.value != null) {
      request.roomId = user.roomId.value!;
    }
    final response = await _client.createUser(request);
    return response.id;
  }
  
  @override
  Future<void> updateUser(User user) async {
    final proto = _userToProto(user);
    await _client.updateUser(proto);
  }
  
  @override
  Future<void> deleteUser(int id) async {
    await _client.deleteUser(pb.IntId()..id = id);
  }
  
  // ==================== ROOMS ====================
  
  @override
  Future<List<Room>> getAllRooms() async {
    final response = await _client.getAllRooms(pb.Empty());
    return response.rooms.map(_roomFromProto).toList();
  }
  
  @override
  Future<Room?> getRoomById(int id) async {
    try {
      final response = await _client.getRoomById(pb.IntId()..id = id);
      return _roomFromProto(response);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) return null;
      rethrow;
    }
  }
  
  @override
  Future<int> createRoom(RoomsCompanion room) async {
    final request = pb.CreateRoomRequest()
      ..name = room.name.value
      ..type = room.type.value;
    if (room.doctorId.present && room.doctorId.value != null) {
      request.doctorId = room.doctorId.value!;
    }
    final response = await _client.createRoom(request);
    return response.id;
  }
  
  @override
  Future<void> updateRoom(Room room) async {
    final proto = _roomToProto(room);
    await _client.updateRoom(proto);
  }
  
  @override
  Future<void> deleteRoom(int id) async {
    await _client.deleteRoom(pb.IntId()..id = id);
  }
  
  // ==================== PATIENTS ====================
  
  @override
  Future<List<Patient>> getAllPatients() async {
    final response = await _client.getAllPatients(pb.Empty());
    return response.patients.map(_patientFromProto).toList();
  }
  
  @override
  Future<Patient?> getPatientByCode(int code) async {
    try {
      final response = await _client.getPatientByCode(pb.PatientCodeRequest()..patientCode = code);
      return _patientFromProto(response);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) return null;
      rethrow;
    }
  }
  
  @override
  Future<List<Patient>> searchPatients(String query) async {
    final response = await _client.searchPatients(pb.StringQuery()..query = query);
    return response.patients.map(_patientFromProto).toList();
  }
  
  @override
  Future<int> createPatient(PatientsCompanion patient) async {
    final request = pb.CreatePatientRequest()
      ..code = patient.code.value
      ..firstName = patient.firstName.value
      ..lastName = patient.lastName.value;
    if (patient.dateOfBirth.present && patient.dateOfBirth.value != null) {
      request.dateOfBirth = patient.dateOfBirth.value!.toIso8601String();
    }
    if (patient.phone.present) request.phone = patient.phone.value ?? '';
    if (patient.address.present) request.address = patient.address.value ?? '';
    if (patient.insurance.present) request.insurance = patient.insurance.value ?? '';
    if (patient.notes.present) request.notes = patient.notes.value ?? '';
    
    final response = await _client.createPatient(request);
    return response.id;
  }
  
  @override
  Future<void> updatePatient(Patient patient) async {
    final proto = _patientToProto(patient);
    await _client.updatePatient(proto);
  }
  
  @override
  Future<void> deletePatient(int code) async {
    await _client.deletePatient(pb.PatientCodeRequest()..patientCode = code);
  }
  
  // ==================== MESSAGES ====================
  
  @override
  Future<List<Message>> getMessagesByRecipient(int userId) async {
    final response = await _client.getMessagesByRecipient(pb.UserIdRequest()..userId = userId);
    return response.messages.map(_messageFromProto).toList();
  }
  
  @override
  Future<List<Message>> getUnreadMessages(int userId) async {
    final response = await _client.getUnreadMessages(pb.UserIdRequest()..userId = userId);
    return response.messages.map(_messageFromProto).toList();
  }
  
  @override
  Future<int> createMessage(MessagesCompanion message) async {
    final request = pb.CreateMessageRequest()
      ..senderId = message.senderId.value
      ..recipientId = message.recipientId.value
      ..content = message.content.value;
    if (message.patientCode.present && message.patientCode.value != null) {
      request.patientCode = message.patientCode.value!;
    }
    if (message.patientName.present && message.patientName.value != null) {
      request.patientName = message.patientName.value!;
    }
    final response = await _client.createMessage(request);
    return response.id;
  }
  
  @override
  Future<void> markMessageAsRead(int messageId) async {
    await _client.markMessageAsRead(pb.IntId()..id = messageId);
  }
  
  @override
  Future<void> deleteMessage(int messageId) async {
    await _client.deleteMessage(pb.IntId()..id = messageId);
  }
  
  // ==================== WAITING PATIENTS ====================
  
  @override
  Future<List<WaitingPatient>> getWaitingPatients() async {
    final response = await _client.getWaitingPatients(pb.Empty());
    return response.patients.map(_waitingPatientFromProto).toList();
  }
  
  @override
  Future<List<WaitingPatient>> getWaitingPatientsByRoom(int roomId) async {
    final response = await _client.getWaitingPatientsByRoom(pb.RoomIdRequest()..roomId = roomId);
    return response.patients.map(_waitingPatientFromProto).toList();
  }
  
  @override
  Future<int> addWaitingPatient(WaitingPatientsCompanion patient) async {
    final request = pb.CreateWaitingPatientRequest()
      ..patientCode = patient.patientCode.value
      ..patientName = patient.patientName.value
      ..isUrgent = patient.isUrgent.value
      ..isDilatation = patient.isDilatation.value;
    if (patient.roomId.present && patient.roomId.value != null) {
      request.roomId = patient.roomId.value!;
    }
    if (patient.patientAge.present && patient.patientAge.value != null) {
      request.patientAge = patient.patientAge.value!;
    }
    if (patient.dilatationType.present && patient.dilatationType.value != null) {
      request.dilatationType = patient.dilatationType.value!;
    }
    final response = await _client.addWaitingPatient(request);
    return response.id;
  }
  
  @override
  Future<void> updateWaitingPatient(WaitingPatient patient) async {
    final proto = _waitingPatientToProto(patient);
    await _client.updateWaitingPatient(proto);
  }
  
  @override
  Future<void> removeWaitingPatient(int id) async {
    await _client.removeWaitingPatient(pb.IntId()..id = id);
  }
  
  @override
  Future<void> clearWaitingRoom() async {
    await _client.clearWaitingRoom(pb.Empty());
  }
  
  // ==================== VISITS ====================
  
  @override
  Future<List<Visit>> getVisitsByPatient(int patientCode) async {
    final response = await _client.getVisitsByPatient(pb.PatientCodeRequest()..patientCode = patientCode);
    return response.visits.map(_visitFromProto).toList();
  }
  
  @override
  Future<List<Visit>> getVisitsByDoctor(int userId) async {
    final response = await _client.getVisitsByDoctor(pb.UserIdRequest()..userId = userId);
    return response.visits.map(_visitFromProto).toList();
  }
  
  @override
  Future<List<Visit>> getTodayVisits() async {
    final response = await _client.getTodayVisits(pb.Empty());
    return response.visits.map(_visitFromProto).toList();
  }
  
  @override
  Future<int> createVisit(VisitsCompanion visit) async {
    final request = pb.CreateVisitRequest()
      ..patientCode = visit.patientCode.value
      ..userId = visit.userId.value;
    if (visit.notes.present) request.notes = visit.notes.value ?? '';
    if (visit.diagnosis.present) request.diagnosis = visit.diagnosis.value ?? '';
    final response = await _client.createVisit(request);
    return response.id;
  }
  
  @override
  Future<void> updateVisit(Visit visit) async {
    final proto = _visitToProto(visit);
    await _client.updateVisit(proto);
  }
  
  // ==================== MEDICAL ACTS ====================
  
  @override
  Future<List<MedicalAct>> getAllMedicalActs() async {
    final response = await _client.getAllMedicalActs(pb.Empty());
    return response.acts.map(_medicalActFromProto).toList();
  }
  
  @override
  Future<MedicalAct?> getMedicalActById(int id) async {
    try {
      final response = await _client.getMedicalActById(pb.IntId()..id = id);
      return _medicalActFromProto(response);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) return null;
      rethrow;
    }
  }
  
  // ==================== ORDONNANCES ====================
  
  @override
  Future<List<Ordonnance>> getOrdonnancesByPatient(int patientCode) async {
    final response = await _client.getOrdonnancesByPatient(pb.PatientCodeRequest()..patientCode = patientCode);
    return response.ordonnances.map(_ordonnanceFromProto).toList();
  }
  
  @override
  Future<int> createOrdonnance(OrdonnancesCompanion ordonnance) async {
    final request = pb.CreateOrdonnanceRequest()
      ..patientCode = ordonnance.patientCode.value
      ..userId = ordonnance.userId.value;
    if (ordonnance.notes.present) request.notes = ordonnance.notes.value ?? '';
    final response = await _client.createOrdonnance(request);
    return response.id;
  }
  
  @override
  Future<void> updateOrdonnance(Ordonnance ordonnance) async {
    final proto = _ordonnanceToProto(ordonnance);
    await _client.updateOrdonnance(proto);
  }
  
  @override
  Future<void> deleteOrdonnance(int id) async {
    await _client.deleteOrdonnance(pb.IntId()..id = id);
  }
  
  // ==================== MEDICATIONS ====================
  
  @override
  Future<List<Medication>> getMedicationsByOrdonnance(int ordonnanceId) async {
    final response = await _client.getMedicationsByOrdonnance(pb.OrdonnanceIdRequest()..ordonnanceId = ordonnanceId);
    return response.medications.map(_medicationFromProto).toList();
  }
  
  @override
  Future<int> createMedication(MedicationsCompanion medication) async {
    final request = pb.CreateMedicationRequest()
      ..ordonnanceId = medication.ordonnanceId.value
      ..name = medication.name.value
      ..dosage = medication.dosage.value
      ..frequency = medication.frequency.value
      ..duration = medication.duration.value;
    final response = await _client.createMedication(request);
    return response.id;
  }
  
  @override
  Future<void> deleteMedication(int id) async {
    await _client.deleteMedication(pb.IntId()..id = id);
  }
  
  // ==================== PAYMENTS ====================
  
  @override
  Future<List<Payment>> getPaymentsByPatient(int patientCode) async {
    final response = await _client.getPaymentsByPatient(pb.PatientCodeRequest()..patientCode = patientCode);
    return response.payments.map(_paymentFromProto).toList();
  }
  
  @override
  Future<List<Payment>> getPaymentsByDateRange(DateTime start, DateTime end) async {
    final request = pb.DateRange()
      ..start = start.toIso8601String()
      ..end = end.toIso8601String();
    final response = await _client.getPaymentsByDateRange(request);
    return response.payments.map(_paymentFromProto).toList();
  }
  
  @override
  Future<int> createPayment(PaymentsCompanion payment) async {
    final request = pb.CreatePaymentRequest()
      ..patientCode = payment.patientCode.value
      ..amount = payment.amount.value
      ..paymentMethod = payment.paymentMethod.value;
    if (payment.notes.present) request.notes = payment.notes.value ?? '';
    final response = await _client.createPayment(request);
    return response.id;
  }
  
  @override
  Future<void> updatePayment(Payment payment) async {
    final proto = _paymentToProto(payment);
    await _client.updatePayment(proto);
  }
  
  // ==================== TEMPLATES ====================
  
  @override
  Future<List<Template>> getAllTemplates() async {
    final response = await _client.getAllTemplates(pb.Empty());
    return response.templates.map(_templateFromProto).toList();
  }
  
  @override
  Future<Template?> getTemplateById(int id) async {
    try {
      final response = await _client.getTemplateById(pb.IntId()..id = id);
      return _templateFromProto(response);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) return null;
      rethrow;
    }
  }
  
  @override
  Future<int> createTemplate(TemplatesCompanion template) async {
    final request = pb.CreateTemplateRequest()
      ..name = template.name.value
      ..content = template.content.value
      ..type = template.type.value;
    final response = await _client.createTemplate(request);
    return response.id;
  }
  
  @override
  Future<void> updateTemplate(Template template) async {
    final proto = _templateToProto(template);
    await _client.updateTemplate(proto);
  }
  
  @override
  Future<void> deleteTemplate(int id) async {
    await _client.deleteTemplate(pb.IntId()..id = id);
  }
  
  // ==================== MESSAGE TEMPLATES ====================
  
  @override
  Future<List<MessageTemplate>> getAllMessageTemplates() async {
    final response = await _client.getAllMessageTemplates(pb.Empty());
    return response.templates.map(_messageTemplateFromProto).toList();
  }
  
  @override
  Future<MessageTemplate?> getMessageTemplateById(int id) async {
    try {
      final response = await _client.getMessageTemplateById(pb.IntId()..id = id);
      return _messageTemplateFromProto(response);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) return null;
      rethrow;
    }
  }
  
  // ==================== CONVERSION HELPERS ====================
  
  User _userFromProto(pb.User proto) {
    return User(
      id: proto.id,
      username: proto.username,
      passwordHash: proto.passwordHash,
      fullName: proto.fullName,
      role: proto.role,
      roomId: proto.hasRoomId() ? proto.roomId : null,
    );
  }
  
  pb.User _userToProto(User user) {
    final proto = pb.User()
      ..id = user.id
      ..username = user.username
      ..passwordHash = user.passwordHash
      ..fullName = user.fullName
      ..role = user.role;
    if (user.roomId != null) proto.roomId = user.roomId!;
    return proto;
  }
  
  Room _roomFromProto(pb.Room proto) {
    return Room(
      id: proto.id,
      name: proto.name,
      type: proto.type,
      doctorId: proto.hasDoctorId() ? proto.doctorId : null,
    );
  }
  
  pb.Room _roomToProto(Room room) {
    final proto = pb.Room()
      ..id = room.id
      ..name = room.name
      ..type = room.type;
    if (room.doctorId != null) proto.doctorId = room.doctorId!;
    return proto;
  }
  
  Patient _patientFromProto(pb.Patient proto) {
    return Patient(
      code: proto.code,
      firstName: proto.firstName,
      lastName: proto.lastName,
      dateOfBirth: proto.hasDateOfBirth() ? DateTime.parse(proto.dateOfBirth) : null,
      phone: proto.hasPhone() ? proto.phone : null,
      address: proto.hasAddress() ? proto.address : null,
      insurance: proto.hasInsurance() ? proto.insurance : null,
      notes: proto.hasNotes() ? proto.notes : null,
    );
  }
  
  pb.Patient _patientToProto(Patient patient) {
    final proto = pb.Patient()
      ..code = patient.code
      ..firstName = patient.firstName
      ..lastName = patient.lastName;
    if (patient.dateOfBirth != null) proto.dateOfBirth = patient.dateOfBirth!.toIso8601String();
    if (patient.phone != null) proto.phone = patient.phone!;
    if (patient.address != null) proto.address = patient.address!;
    if (patient.insurance != null) proto.insurance = patient.insurance!;
    if (patient.notes != null) proto.notes = patient.notes!;
    return proto;
  }
  
  Message _messageFromProto(pb.Message proto) {
    return Message(
      id: proto.id,
      senderId: proto.senderId,
      recipientId: proto.recipientId,
      content: proto.content,
      createdAt: DateTime.parse(proto.createdAt),
      isRead: proto.isRead,
      patientCode: proto.hasPatientCode() ? proto.patientCode : null,
      patientName: proto.hasPatientName() ? proto.patientName : null,
    );
  }
  
  WaitingPatient _waitingPatientFromProto(pb.WaitingPatient proto) {
    return WaitingPatient(
      id: proto.id,
      patientCode: proto.patientCode,
      patientName: proto.patientName,
      arrivalTime: DateTime.parse(proto.arrivalTime),
      roomId: proto.hasRoomId() ? proto.roomId : null,
      patientAge: proto.hasPatientAge() ? proto.patientAge : null,
      isUrgent: proto.isUrgent,
      isDilatation: proto.isDilatation,
      dilatationType: proto.hasDilatationType() ? proto.dilatationType : null,
    );
  }
  
  pb.WaitingPatient _waitingPatientToProto(WaitingPatient patient) {
    final proto = pb.WaitingPatient()
      ..id = patient.id
      ..patientCode = patient.patientCode
      ..patientName = patient.patientName
      ..arrivalTime = patient.arrivalTime.toIso8601String()
      ..isUrgent = patient.isUrgent
      ..isDilatation = patient.isDilatation;
    if (patient.roomId != null) proto.roomId = patient.roomId!;
    if (patient.patientAge != null) proto.patientAge = patient.patientAge!;
    if (patient.dilatationType != null) proto.dilatationType = patient.dilatationType!;
    return proto;
  }
  
  Visit _visitFromProto(pb.Visit proto) {
    return Visit(
      id: proto.id,
      patientCode: proto.patientCode,
      userId: proto.userId,
      visitDate: DateTime.parse(proto.visitDate),
      notes: proto.hasNotes() ? proto.notes : null,
      diagnosis: proto.hasDiagnosis() ? proto.diagnosis : null,
    );
  }
  
  pb.Visit _visitToProto(Visit visit) {
    final proto = pb.Visit()
      ..id = visit.id
      ..patientCode = visit.patientCode
      ..userId = visit.userId
      ..visitDate = visit.visitDate.toIso8601String();
    if (visit.notes != null) proto.notes = visit.notes!;
    if (visit.diagnosis != null) proto.diagnosis = visit.diagnosis!;
    return proto;
  }
  
  MedicalAct _medicalActFromProto(pb.MedicalAct proto) {
    return MedicalAct(
      id: proto.id,
      code: proto.code,
      name: proto.name,
      price: proto.price,
    );
  }
  
  Ordonnance _ordonnanceFromProto(pb.Ordonnance proto) {
    return Ordonnance(
      id: proto.id,
      patientCode: proto.patientCode,
      userId: proto.userId,
      date: DateTime.parse(proto.date),
      notes: proto.hasNotes() ? proto.notes : null,
    );
  }
  
  pb.Ordonnance _ordonnanceToProto(Ordonnance ordonnance) {
    final proto = pb.Ordonnance()
      ..id = ordonnance.id
      ..patientCode = ordonnance.patientCode
      ..userId = ordonnance.userId
      ..date = ordonnance.date.toIso8601String();
    if (ordonnance.notes != null) proto.notes = ordonnance.notes!;
    return proto;
  }
  
  Medication _medicationFromProto(pb.Medication proto) {
    return Medication(
      id: proto.id,
      ordonnanceId: proto.ordonnanceId,
      name: proto.name,
      dosage: proto.dosage,
      frequency: proto.frequency,
      duration: proto.duration,
    );
  }
  
  Payment _paymentFromProto(pb.Payment proto) {
    return Payment(
      id: proto.id,
      patientCode: proto.patientCode,
      amount: proto.amount,
      date: DateTime.parse(proto.date),
      paymentMethod: proto.paymentMethod,
      notes: proto.hasNotes() ? proto.notes : null,
    );
  }
  
  pb.Payment _paymentToProto(Payment payment) {
    final proto = pb.Payment()
      ..id = payment.id
      ..patientCode = payment.patientCode
      ..amount = payment.amount
      ..date = payment.date.toIso8601String()
      ..paymentMethod = payment.paymentMethod;
    if (payment.notes != null) proto.notes = payment.notes!;
    return proto;
  }
  
  Template _templateFromProto(pb.Template proto) {
    return Template(
      id: proto.id,
      name: proto.name,
      content: proto.content,
      type: proto.type,
    );
  }
  
  pb.Template _templateToProto(Template template) {
    return pb.Template()
      ..id = template.id
      ..name = template.name
      ..content = template.content
      ..type = template.type;
  }
  
  MessageTemplate _messageTemplateFromProto(pb.MessageTemplate proto) {
    return MessageTemplate(
      id: proto.id,
      name: proto.name,
      content: proto.content,
    );
  }
}
