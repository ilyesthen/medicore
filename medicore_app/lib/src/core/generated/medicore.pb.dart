///
///  Generated code - DO NOT MODIFY BY HAND
///  MediCore Protocol Buffer Messages
///

import 'dart:core' as $core;

// ==================== COMMON MESSAGES ====================

class Empty {
  Empty();
  factory Empty.fromJson($core.Map<$core.String, $core.dynamic> json) => Empty();
  $core.Map<$core.String, $core.dynamic> toJson() => {};
}

class IntId {
  $core.int id;
  IntId({this.id = 0});
  
  factory IntId.fromJson($core.Map<$core.String, $core.dynamic> json) => IntId(
    id: json['id'] as $core.int? ?? 0,
  );
  $core.Map<$core.String, $core.dynamic> toJson() => {'id': id};
}

class IntCode {
  $core.int code;
  IntCode({this.code = 0});
  
  factory IntCode.fromJson($core.Map<$core.String, $core.dynamic> json) => IntCode(
    code: json['code'] as $core.int? ?? 0,
  );
  $core.Map<$core.String, $core.dynamic> toJson() => {'code': code};
}

class StringQuery {
  $core.String query;
  StringQuery({this.query = ''});
  
  factory StringQuery.fromJson($core.Map<$core.String, $core.dynamic> json) => StringQuery(
    query: json['query'] as $core.String? ?? '',
  );
  $core.Map<$core.String, $core.dynamic> toJson() => {'query': query};
}

class DateRange {
  $core.String start;
  $core.String end;
  DateRange({this.start = '', this.end = ''});
  
  factory DateRange.fromJson($core.Map<$core.String, $core.dynamic> json) => DateRange(
    start: json['start'] as $core.String? ?? '',
    end: json['end'] as $core.String? ?? '',
  );
  $core.Map<$core.String, $core.dynamic> toJson() => {'start': start, 'end': end};
}

// ==================== USER MESSAGES ====================

class GrpcUser {
  $core.int id;
  $core.String stringId; // Local database uses string IDs
  $core.String username;
  $core.String passwordHash;
  $core.String fullName;
  $core.String role;
  $core.int? roomId;
  $core.double? percentage;
  
  GrpcUser({
    this.id = 0,
    this.stringId = '',
    this.username = '',
    this.passwordHash = '',
    this.fullName = '',
    this.role = '',
    this.roomId,
    this.percentage,
  });
  
  factory GrpcUser.fromJson($core.Map<$core.String, $core.dynamic> json) {
    // Handle both int and string IDs (local DB uses strings)
    $core.int intId = 0;
    $core.String strId = '';
    
    final rawId = json['id'];
    if (rawId is $core.int) {
      intId = rawId;
      strId = rawId.toString();
    } else if (rawId is $core.String) {
      strId = rawId;
      intId = $core.int.tryParse(rawId) ?? 0;
    }
    
    return GrpcUser(
      id: intId,
      stringId: strId,
      username: json['username'] as $core.String? ?? '',
      passwordHash: json['password_hash'] as $core.String? ?? json['passwordHash'] as $core.String? ?? '',
      fullName: json['full_name'] as $core.String? ?? json['fullName'] as $core.String? ?? '',
      role: json['role'] as $core.String? ?? '',
      roomId: json['room_id'] as $core.int? ?? json['roomId'] as $core.int?,
      percentage: (json['percentage'] as $core.num?)?.toDouble(),
    );
  }
  
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'id': stringId.isNotEmpty ? stringId : id.toString(),
    'username': username,
    'password_hash': passwordHash,
    'full_name': fullName,
    'role': role,
    if (roomId != null) 'room_id': roomId,
    if (percentage != null) 'percentage': percentage,
  };
}

class UserList {
  $core.List<GrpcUser> users;
  UserList({$core.List<GrpcUser>? users}) : users = users ?? [];
  
  factory UserList.fromJson($core.Map<$core.String, $core.dynamic> json) => UserList(
    users: (json['users'] as $core.List<$core.dynamic>?)
        ?.map((e) => GrpcUser.fromJson(e as $core.Map<$core.String, $core.dynamic>))
        .toList() ?? [],
  );
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'users': users.map((e) => e.toJson()).toList(),
  };
}

class CreateUserRequest {
  $core.String username;
  $core.String passwordHash;
  $core.String fullName;
  $core.String role;
  $core.int? roomId;
  $core.double? percentage;
  
  CreateUserRequest({
    this.username = '',
    this.passwordHash = '',
    this.fullName = '',
    this.role = '',
    this.roomId,
    this.percentage,
  });
  
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'username': username,
    'password_hash': passwordHash,
    'full_name': fullName,
    'role': role,
    if (roomId != null) 'room_id': roomId,
    if (percentage != null) 'percentage': percentage,
  };
}

class UsernameRequest {
  $core.String username;
  UsernameRequest({this.username = ''});
  $core.Map<$core.String, $core.dynamic> toJson() => {'username': username};
}

// ==================== ROOM MESSAGES ====================

class GrpcRoom {
  $core.int id;
  $core.String stringId; // Local database uses string IDs
  $core.String name;
  $core.String type;
  $core.int? doctorId;
  
  GrpcRoom({this.id = 0, this.stringId = '', this.name = '', this.type = '', this.doctorId});
  
  factory GrpcRoom.fromJson($core.Map<$core.String, $core.dynamic> json) {
    // Handle both int and string IDs (local DB uses strings)
    $core.int intId = 0;
    $core.String strId = '';
    
    final rawId = json['id'];
    if (rawId is $core.int) {
      intId = rawId;
      strId = rawId.toString();
    } else if (rawId is $core.String) {
      strId = rawId;
      intId = $core.int.tryParse(rawId) ?? 0;
    }
    
    return GrpcRoom(
      id: intId,
      stringId: strId,
      name: json['name'] as $core.String? ?? '',
      type: json['type'] as $core.String? ?? '',
      doctorId: json['doctor_id'] as $core.int? ?? json['doctorId'] as $core.int?,
    );
  }
  
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    if (doctorId != null) 'doctor_id': doctorId,
  };
}

class RoomList {
  $core.List<GrpcRoom> rooms;
  RoomList({$core.List<GrpcRoom>? rooms}) : rooms = rooms ?? [];
  
  factory RoomList.fromJson($core.Map<$core.String, $core.dynamic> json) => RoomList(
    rooms: (json['rooms'] as $core.List<$core.dynamic>?)
        ?.map((e) => GrpcRoom.fromJson(e as $core.Map<$core.String, $core.dynamic>))
        .toList() ?? [],
  );
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'rooms': rooms.map((e) => e.toJson()).toList(),
  };
}

class CreateRoomRequest {
  $core.String name;
  $core.String type;
  $core.int? doctorId;
  
  CreateRoomRequest({this.name = '', this.type = '', this.doctorId});
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'name': name,
    'type': type,
    if (doctorId != null) 'doctor_id': doctorId,
  };
}

// ==================== PATIENT MESSAGES ====================

class GrpcPatient {
  $core.int code;
  $core.String firstName;
  $core.String lastName;
  $core.String? dateOfBirth;
  $core.String? phone;
  $core.String? address;
  $core.String? insurance;
  $core.String? notes;
  $core.String? barcode;
  $core.int? age;
  
  GrpcPatient({
    this.code = 0,
    this.firstName = '',
    this.lastName = '',
    this.dateOfBirth,
    this.phone,
    this.address,
    this.insurance,
    this.notes,
    this.barcode,
    this.age,
  });
  
  factory GrpcPatient.fromJson($core.Map<$core.String, $core.dynamic> json) => GrpcPatient(
    code: json['code'] as $core.int? ?? 0,
    firstName: json['first_name'] as $core.String? ?? json['firstName'] as $core.String? ?? '',
    lastName: json['last_name'] as $core.String? ?? json['lastName'] as $core.String? ?? '',
    dateOfBirth: json['date_of_birth'] as $core.String? ?? json['dateOfBirth'] as $core.String?,
    phone: json['phone'] as $core.String?,
    address: json['address'] as $core.String?,
    insurance: json['insurance'] as $core.String?,
    notes: json['notes'] as $core.String?,
    barcode: json['barcode'] as $core.String?,
    age: json['age'] as $core.int?,
  );
  
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'code': code,
    'first_name': firstName,
    'last_name': lastName,
    if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
    if (phone != null) 'phone': phone,
    if (address != null) 'address': address,
    if (insurance != null) 'insurance': insurance,
    if (notes != null) 'notes': notes,
    if (barcode != null) 'barcode': barcode,
    if (age != null) 'age': age,
  };
}

class PatientList {
  $core.List<GrpcPatient> patients;
  PatientList({$core.List<GrpcPatient>? patients}) : patients = patients ?? [];
  
  factory PatientList.fromJson($core.Map<$core.String, $core.dynamic> json) => PatientList(
    patients: (json['patients'] as $core.List<$core.dynamic>?)
        ?.map((e) => GrpcPatient.fromJson(e as $core.Map<$core.String, $core.dynamic>))
        .toList() ?? [],
  );
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'patients': patients.map((e) => e.toJson()).toList(),
  };
}

class CreatePatientRequest {
  $core.int code;
  $core.String firstName;
  $core.String lastName;
  $core.String? dateOfBirth;
  $core.String? phone;
  $core.String? address;
  $core.String? barcode;
  $core.int? age;
  
  CreatePatientRequest({
    this.code = 0,
    this.firstName = '',
    this.lastName = '',
    this.dateOfBirth,
    this.phone,
    this.address,
    this.barcode,
    this.age,
  });
  
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'code': code,
    'first_name': firstName,
    'last_name': lastName,
    if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
    if (phone != null) 'phone': phone,
    if (address != null) 'address': address,
    if (barcode != null) 'barcode': barcode,
    if (age != null) 'age': age,
  };
}

class PatientCodeRequest {
  $core.int patientCode;
  PatientCodeRequest({this.patientCode = 0});
  $core.Map<$core.String, $core.dynamic> toJson() => {'patient_code': patientCode};
}

// ==================== MESSAGE MESSAGES ====================

class GrpcMessage {
  $core.int id;
  $core.String roomId;
  $core.String senderId;
  $core.String senderName;
  $core.String senderRole;
  $core.String content;
  $core.String direction;
  $core.String sentAt;
  $core.bool isRead;
  $core.int? patientCode;
  $core.String? patientName;
  
  GrpcMessage({
    this.id = 0,
    this.roomId = '',
    this.senderId = '',
    this.senderName = '',
    this.senderRole = '',
    this.content = '',
    this.direction = '',
    this.sentAt = '',
    this.isRead = false,
    this.patientCode,
    this.patientName,
  });
  
  factory GrpcMessage.fromJson($core.Map<$core.String, $core.dynamic> json) => GrpcMessage(
    id: json['id'] as $core.int? ?? 0,
    roomId: json['room_id'] as $core.String? ?? json['roomId'] as $core.String? ?? '',
    senderId: json['sender_id'] as $core.String? ?? json['senderId'] as $core.String? ?? '',
    senderName: json['sender_name'] as $core.String? ?? json['senderName'] as $core.String? ?? '',
    senderRole: json['sender_role'] as $core.String? ?? json['senderRole'] as $core.String? ?? '',
    content: json['content'] as $core.String? ?? '',
    direction: json['direction'] as $core.String? ?? '',
    sentAt: json['sent_at'] as $core.String? ?? json['sentAt'] as $core.String? ?? '',
    isRead: json['is_read'] as $core.bool? ?? json['isRead'] as $core.bool? ?? false,
    patientCode: json['patient_code'] as $core.int? ?? json['patientCode'] as $core.int?,
    patientName: json['patient_name'] as $core.String? ?? json['patientName'] as $core.String?,
  );
  
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'id': id,
    'room_id': roomId,
    'sender_id': senderId,
    'sender_name': senderName,
    'sender_role': senderRole,
    'content': content,
    'direction': direction,
    'sent_at': sentAt,
    'is_read': isRead,
    if (patientCode != null) 'patient_code': patientCode,
    if (patientName != null) 'patient_name': patientName,
  };
}

class MessageList {
  $core.List<GrpcMessage> messages;
  MessageList({$core.List<GrpcMessage>? messages}) : messages = messages ?? [];
  
  factory MessageList.fromJson($core.Map<$core.String, $core.dynamic> json) => MessageList(
    messages: (json['messages'] as $core.List<$core.dynamic>?)
        ?.map((e) => GrpcMessage.fromJson(e as $core.Map<$core.String, $core.dynamic>))
        .toList() ?? [],
  );
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'messages': messages.map((e) => e.toJson()).toList(),
  };
}

class CreateMessageRequest {
  $core.String roomId;
  $core.String senderId;
  $core.String senderName;
  $core.String senderRole;
  $core.String content;
  $core.String direction;
  $core.int? patientCode;
  $core.String? patientName;
  
  CreateMessageRequest({
    this.roomId = '',
    this.senderId = '',
    this.senderName = '',
    this.senderRole = '',
    this.content = '',
    this.direction = '',
    this.patientCode,
    this.patientName,
  });
  
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'room_id': roomId,
    'sender_id': senderId,
    'sender_name': senderName,
    'sender_role': senderRole,
    'content': content,
    'direction': direction,
    if (patientCode != null) 'patient_code': patientCode,
    if (patientName != null) 'patient_name': patientName,
  };
}

class RoomIdRequest {
  $core.String roomId;
  RoomIdRequest({this.roomId = ''});
  $core.Map<$core.String, $core.dynamic> toJson() => {'room_id': roomId};
}

// ==================== WAITING PATIENT MESSAGES ====================

class GrpcWaitingPatient {
  $core.int id;
  $core.int patientCode;
  $core.String patientFirstName;
  $core.String patientLastName;
  $core.String sentAt;
  $core.String roomId;
  $core.String roomName;
  $core.String motif;
  $core.String sentByUserId;
  $core.String sentByUserName;
  $core.int? patientAge;
  $core.bool isUrgent;
  $core.bool isDilatation;
  $core.String? dilatationType;
  $core.bool isChecked;
  $core.bool isActive;
  
  GrpcWaitingPatient({
    this.id = 0,
    this.patientCode = 0,
    this.patientFirstName = '',
    this.patientLastName = '',
    this.sentAt = '',
    this.roomId = '',
    this.roomName = '',
    this.motif = '',
    this.sentByUserId = '',
    this.sentByUserName = '',
    this.patientAge,
    this.isUrgent = false,
    this.isDilatation = false,
    this.dilatationType,
    this.isChecked = false,
    this.isActive = true,
  });
  
  factory GrpcWaitingPatient.fromJson($core.Map<$core.String, $core.dynamic> json) => GrpcWaitingPatient(
    id: json['id'] as $core.int? ?? 0,
    patientCode: json['patient_code'] as $core.int? ?? json['patientCode'] as $core.int? ?? 0,
    patientFirstName: json['patient_first_name'] as $core.String? ?? json['patientFirstName'] as $core.String? ?? '',
    patientLastName: json['patient_last_name'] as $core.String? ?? json['patientLastName'] as $core.String? ?? '',
    sentAt: json['sent_at'] as $core.String? ?? json['sentAt'] as $core.String? ?? '',
    roomId: json['room_id'] as $core.String? ?? json['roomId'] as $core.String? ?? '',
    roomName: json['room_name'] as $core.String? ?? json['roomName'] as $core.String? ?? '',
    motif: json['motif'] as $core.String? ?? '',
    sentByUserId: json['sent_by_user_id'] as $core.String? ?? json['sentByUserId'] as $core.String? ?? '',
    sentByUserName: json['sent_by_user_name'] as $core.String? ?? json['sentByUserName'] as $core.String? ?? '',
    patientAge: json['patient_age'] as $core.int? ?? json['patientAge'] as $core.int?,
    isUrgent: json['is_urgent'] as $core.bool? ?? json['isUrgent'] as $core.bool? ?? false,
    isDilatation: json['is_dilatation'] as $core.bool? ?? json['isDilatation'] as $core.bool? ?? false,
    dilatationType: json['dilatation_type'] as $core.String? ?? json['dilatationType'] as $core.String?,
    isChecked: json['is_checked'] as $core.bool? ?? json['isChecked'] as $core.bool? ?? false,
    isActive: json['is_active'] as $core.bool? ?? json['isActive'] as $core.bool? ?? true,
  );
  
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'id': id,
    'patient_code': patientCode,
    'patient_first_name': patientFirstName,
    'patient_last_name': patientLastName,
    'sent_at': sentAt,
    'room_id': roomId,
    'room_name': roomName,
    'motif': motif,
    'sent_by_user_id': sentByUserId,
    'sent_by_user_name': sentByUserName,
    if (patientAge != null) 'patient_age': patientAge,
    'is_urgent': isUrgent,
    'is_dilatation': isDilatation,
    if (dilatationType != null) 'dilatation_type': dilatationType,
    'is_checked': isChecked,
    'is_active': isActive,
  };
}

class WaitingPatientList {
  $core.List<GrpcWaitingPatient> patients;
  WaitingPatientList({$core.List<GrpcWaitingPatient>? patients}) : patients = patients ?? [];
  
  factory WaitingPatientList.fromJson($core.Map<$core.String, $core.dynamic> json) => WaitingPatientList(
    patients: (json['patients'] as $core.List<$core.dynamic>?)
        ?.map((e) => GrpcWaitingPatient.fromJson(e as $core.Map<$core.String, $core.dynamic>))
        .toList() ?? [],
  );
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'patients': patients.map((e) => e.toJson()).toList(),
  };
}

class CreateWaitingPatientRequest {
  $core.int patientCode;
  $core.String patientFirstName;
  $core.String patientLastName;
  $core.String roomId;
  $core.String roomName;
  $core.String motif;
  $core.String sentByUserId;
  $core.String sentByUserName;
  $core.int? patientAge;
  $core.bool isUrgent;
  $core.bool isDilatation;
  $core.String? dilatationType;
  
  CreateWaitingPatientRequest({
    this.patientCode = 0,
    this.patientFirstName = '',
    this.patientLastName = '',
    this.roomId = '',
    this.roomName = '',
    this.motif = '',
    this.sentByUserId = '',
    this.sentByUserName = '',
    this.patientAge,
    this.isUrgent = false,
    this.isDilatation = false,
    this.dilatationType,
  });
  
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'patient_code': patientCode,
    'patient_first_name': patientFirstName,
    'patient_last_name': patientLastName,
    'room_id': roomId,
    'room_name': roomName,
    'motif': motif,
    'sent_by_user_id': sentByUserId,
    'sent_by_user_name': sentByUserName,
    if (patientAge != null) 'patient_age': patientAge,
    'is_urgent': isUrgent,
    'is_dilatation': isDilatation,
    if (dilatationType != null) 'dilatation_type': dilatationType,
  };
}

// ==================== MEDICAL ACT MESSAGES ====================

class GrpcMedicalAct {
  $core.int id;
  $core.String name;
  $core.int feeAmount;
  $core.int displayOrder;
  
  GrpcMedicalAct({
    this.id = 0,
    this.name = '',
    this.feeAmount = 0,
    this.displayOrder = 0,
  });
  
  factory GrpcMedicalAct.fromJson($core.Map<$core.String, $core.dynamic> json) => GrpcMedicalAct(
    id: json['id'] as $core.int? ?? 0,
    name: json['name'] as $core.String? ?? '',
    feeAmount: json['fee_amount'] as $core.int? ?? json['feeAmount'] as $core.int? ?? 0,
    displayOrder: json['display_order'] as $core.int? ?? json['displayOrder'] as $core.int? ?? 0,
  );
  
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'id': id,
    'name': name,
    'fee_amount': feeAmount,
    'display_order': displayOrder,
  };
}

class MedicalActList {
  $core.List<GrpcMedicalAct> acts;
  MedicalActList({$core.List<GrpcMedicalAct>? acts}) : acts = acts ?? [];
  
  factory MedicalActList.fromJson($core.Map<$core.String, $core.dynamic> json) => MedicalActList(
    acts: (json['acts'] as $core.List<$core.dynamic>?)
        ?.map((e) => GrpcMedicalAct.fromJson(e as $core.Map<$core.String, $core.dynamic>))
        .toList() ?? [],
  );
  $core.Map<$core.String, $core.dynamic> toJson() => {
    'acts': acts.map((e) => e.toJson()).toList(),
  };
}
