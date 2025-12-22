/// Type aliases for protobuf types - makes code cleaner
export '../generated/medicore.pb.dart';

// Convenient type aliases for types that EXIST in protobuf
import '../generated/medicore.pb.dart' as pb;

typedef Patient = pb.GrpcPatient;
typedef Room = pb.GrpcRoom;
typedef Message = pb.GrpcMessage;
typedef WaitingPatient = pb.GrpcWaitingPatient;
// User typedef removed - use local User model from user_model.dart instead
// typedef User = pb.GrpcUser;
typedef MedicalAct = pb.GrpcMedicalAct;

// Stub classes for types NOT YET in protobuf
// TODO: Add these to medicore.proto when ready
class Visit {
  final String id;
  final int patientCode;
  final DateTime? visitDate;
  final DateTime? createdAt;
  final String? motif;
  final String? diagnostique;
  final String? traitement;
  final String? conduct;
  final String? diagnosis;
  // OD fields (Right Eye)
  final String? odSv;
  final String? odAv;
  final String? odSphere;
  final String? odCylinder;
  final String? odAxis;
  final String? odK1;
  final String? odK2;
  final String? odR1;
  final String? odR2;
  final String? odR0;
  final String? odPachy;
  final String? odToc;
  final String? odTo;
  final String? odGonio;
  final String? odLaf;
  final String? odFo;
  final String? odNotes;
  // OG fields (Left Eye)
  final String? ogSv;
  final String? ogAv;
  final String? ogSphere;
  final String? ogCylinder;
  final String? ogAxis;
  final String? ogK1;
  final String? ogK2;
  final String? ogR1;
  final String? ogR2;
  final String? ogR0;
  final String? ogPachy;
  final String? ogToc;
  final String? ogTo;
  final String? ogGonio;
  final String? ogLaf;
  final String? ogFo;
  final String? ogNotes;
  final String? addition;
  final String? dip;
  
  Visit({
    required this.id,
    required this.patientCode,
    this.visitDate,
    this.createdAt,
    this.motif,
    this.diagnostique,
    this.traitement,
    this.conduct,
    this.diagnosis,
    this.odSv, this.odAv, this.odSphere, this.odCylinder, this.odAxis,
    this.odK1, this.odK2, this.odR1, this.odR2, this.odR0,
    this.odPachy, this.odToc, this.odTo, this.odGonio, this.odLaf, this.odFo, this.odNotes,
    this.ogSv, this.ogAv, this.ogSphere, this.ogCylinder, this.ogAxis,
    this.ogK1, this.ogK2, this.ogR1, this.ogR2, this.ogR0,
    this.ogPachy, this.ogToc, this.ogTo, this.ogGonio, this.ogLaf, this.ogFo, this.ogNotes,
    this.addition, this.dip,
  });
}

class Appointment {
  final String id;
  final int patientCode;
  final String? existingPatientCode;
  final String? firstName;
  final String? lastName;
  final DateTime? appointmentDate;
  final String? motif;
  final String? notes;
  
  Appointment({
    required this.id,
    required this.patientCode,
    this.existingPatientCode,
    this.firstName,
    this.lastName,
    this.appointmentDate,
    this.motif,
    this.notes,
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
  final String? code;
  final String? name;
  final String? dosage;
  final String? prescription;
  final int? usageCount;
  
  Medication({
    required this.id,
    this.code,
    this.name,
    this.dosage,
    this.prescription,
    this.usageCount,
  });
}

class OrdonnanceDocument {
  final String id;
  final int patientCode;
  final DateTime? createdAt;
  final DateTime? documentDate;
  final String? content;
  final String? type;
  final String? displayTitle;
  final String? formattedDate;
  final String? doctorName;
  final String? reportTitle;
  final String? referredBy;
  final String? medications;
  
  OrdonnanceDocument({
    required this.id,
    required this.patientCode,
    this.createdAt,
    this.documentDate,
    this.content,
    this.type,
    this.displayTitle,
    this.formattedDate,
    this.doctorName,
    this.reportTitle,
    this.referredBy,
    this.medications,
  });
}

class Payment {
  final String id;
  final int patientCode;
  final String? patientFirstName;
  final String? patientLastName;
  final String? medicalActName;
  final double? amount;
  final DateTime? paymentDate;
  final DateTime? paymentTime;
  final String? userName;
  final String? notes;
  
  Payment({
    required this.id,
    required this.patientCode,
    this.patientFirstName,
    this.patientLastName,
    this.medicalActName,
    this.amount,
    this.paymentDate,
    this.paymentTime,
    this.userName,
    this.notes,
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
