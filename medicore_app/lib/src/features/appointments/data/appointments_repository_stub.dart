// Stub repository for appointments - to be implemented
class AppointmentsRepository {
  Future<List<dynamic>> getAllAppointments() async => [];
  Future<void> addAppointment({required dynamic appointmentDate, required String firstName, required String lastName, int? age, String? dateOfBirth, String? phoneNumber, String? address, int? existingPatientCode, String? createdBy}) async {}
  Future<void> markAsAdded(int id) async {}
  Future<void> updateAppointment(dynamic appointment) async {}
  Future<void> deleteAppointment(int id) async {}
}
