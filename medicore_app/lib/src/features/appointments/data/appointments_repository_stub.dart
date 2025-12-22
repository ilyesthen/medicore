import '../../../core/types/proto_types.dart';

// Stub repository for appointments - to be implemented with gRPC
class AppointmentsRepository {
  Future<List<Appointment>> getAllAppointments() async => [];
  
  Future<List<Appointment>> getAppointmentsForDate(DateTime date) async => [];
  
  Future<void> addAppointment({
    required dynamic appointmentDate, 
    required String firstName, 
    required String lastName, 
    int? age, 
    String? dateOfBirth, 
    String? phoneNumber, 
    String? address, 
    int? existingPatientCode, 
    String? createdBy,
    String? notes,
  }) async {
    throw UnimplementedError('Appointments not implemented in gRPC mode');
  }
  
  Future<void> markAsAdded(int id) async {
    throw UnimplementedError('Appointments not implemented in gRPC mode');
  }
  
  Future<void> updateAppointment(Appointment appointment) async {
    throw UnimplementedError('Appointments not implemented in gRPC mode');
  }
  
  Future<void> updateAppointmentDate(int id, DateTime newDate) async {
    throw UnimplementedError('Appointments not implemented in gRPC mode');
  }
  
  Future<void> deleteAppointment(int id) async {
    throw UnimplementedError('Appointments not implemented in gRPC mode');
  }
  
  Future<void> cleanupPastAppointments() async {
    throw UnimplementedError('Appointments not implemented in gRPC mode');
  }
}
