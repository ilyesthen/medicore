// Stub repository for surgery planning - to be implemented
class SurgeryPlansRepository {
  Future<List<dynamic>> getAllSurgeryPlans() async => [];
  Future<void> addSurgeryPlan({required dynamic surgeryDate, String? surgeryHour, required int patientCode, required String patientFirstName, required String patientLastName, int? patientAge, String? patientPhone, required String surgeryType, required String eyeToOperate, String? implantPower, int? tarif, String? notes, String? createdBy}) async {}
  Future<void> updateSurgeryPlan(dynamic plan) async {}
  Future<void> deleteSurgeryPlan(int id) async {}
}
