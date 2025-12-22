/// Type aliases for protobuf types - makes code cleaner
export '../generated/medicore.pb.dart';

// Convenient type aliases for types that EXIST in protobuf
import '../generated/medicore.pb.dart' as pb;

typedef Patient = pb.GrpcPatient;
typedef Room = pb.GrpcRoom;
typedef Message = pb.GrpcMessage;
typedef WaitingPatient = pb.GrpcWaitingPatient;
typedef User = pb.GrpcUser;
typedef MedicalAct = pb.GrpcMedicalAct;

// Stub classes for types NOT YET in protobuf
// TODO: Add these to medicore.proto when ready
class Visit {
  final String id;
  final int patientCode;
  final DateTime? visitDate;
  final String? motif;
  final String? diagnostique;
  final String? traitement;
  
  Visit({
    required this.id,
    required this.patientCode,
    this.visitDate,
    this.motif,
    this.diagnostique,
    this.traitement,
  });
}

class Appointment {
  final String id;
  final int patientCode;
  final DateTime? appointmentDate;
  final String? motif;
  
  Appointment({
    required this.id,
    required this.patientCode,
    this.appointmentDate,
    this.motif,
  });
}

class SurgeryPlan {
  final String id;
  final int patientCode;
  final DateTime? surgeryDate;
  final String? surgeryType;
  final String? surgeryStatus;
  
  SurgeryPlan({
    required this.id,
    required this.patientCode,
    this.surgeryDate,
    this.surgeryType,
    this.surgeryStatus,
  });
}

class Medication {
  final String id;
  final String? name;
  final String? dosage;
  
  Medication({
    required this.id,
    this.name,
    this.dosage,
  });
}

class OrdonnanceDocument {
  final String id;
  final int patientCode;
  final DateTime? createdAt;
  final String? content;
  
  OrdonnanceDocument({
    required this.id,
    required this.patientCode,
    this.createdAt,
    this.content,
  });
}

class Payment {
  final String id;
  final int patientCode;
  final double? amount;
  final DateTime? paymentDate;
  
  Payment({
    required this.id,
    required this.patientCode,
    this.amount,
    this.paymentDate,
  });
}

class MessageTemplate {
  final String id;
  final String? title;
  final String? content;
  
  MessageTemplate({
    required this.id,
    this.title,
    this.content,
  });
}
