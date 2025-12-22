import '../../../core/types/proto_types.dart';

// Stub repository for surgery planning - to be implemented with gRPC
class SurgeryPlansRepository {
  // Surgery type options
  static const List<String> surgeryTypes = [
    'Cataracte',
    'Ptérygion',
    'Chalazion',
    'Greffe de cornée',
    'Vitrectomie',
    'Décollement de rétine',
    'Glaucome',
    'Autre',
  ];
  
  // Eye options
  static const List<String> eyeOptions = ['OD', 'OG', 'ODG'];
  
  Future<List<SurgeryPlan>> getAllSurgeryPlans() async => [];
  
  Future<List<SurgeryPlan>> getSurgeryPlansForDate(DateTime date) async => [];
  
  Future<void> addSurgeryPlan({
    required dynamic surgeryDate, 
    String? surgeryHour, 
    required int patientCode, 
    required String patientFirstName, 
    required String patientLastName, 
    int? patientAge, 
    String? patientPhone, 
    required String surgeryType, 
    required String eyeToOperate, 
    String? implantPower, 
    int? tarif, 
    String? notes, 
    String? createdBy,
    String? paymentStatus,
  }) async {
    throw UnimplementedError('Surgery planning not implemented in gRPC mode');
  }
  
  Future<void> updateSurgeryPlan(
    dynamic id, {
    String? paymentStatus,
    double? amountRemaining,
    String? surgeryHour,
    String? surgeryType,
    String? eyeToOperate,
    String? implantPower,
    int? tarif,
    String? notes,
  }) async {
    throw UnimplementedError('Surgery planning not implemented in gRPC mode');
  }
  
  Future<void> deleteSurgeryPlan(int id) async {
    throw UnimplementedError('Surgery planning not implemented in gRPC mode');
  }
  
  Future<void> markAsDone(dynamic id) async {
    throw UnimplementedError('Surgery planning not implemented in gRPC mode');
  }
  
  Future<void> cancelSurgery(dynamic id) async {
    throw UnimplementedError('Surgery planning not implemented in gRPC mode');
  }
  
  Future<void> rescheduleSurgery(dynamic id, DateTime newDate, {String? newHour}) async {
    throw UnimplementedError('Surgery planning not implemented in gRPC mode');
  }
}
