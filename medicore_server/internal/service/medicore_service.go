package service

import (
	"context"
	"database/sql"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"

	pb "medicore/proto"
)

// MediCoreService implements the complete gRPC service
type MediCoreService struct {
	pb.UnimplementedMediCoreServiceServer
	db *sql.DB
}

// NewMediCoreService creates a new service instance
func NewMediCoreService(db *sql.DB) *MediCoreService {
	return &MediCoreService{db: db}
}

// ==================== USERS ====================

func (s *MediCoreService) GetAllUsers(ctx context.Context, req *pb.Empty) (*pb.UserList, error) {
	rows, err := s.db.QueryContext(ctx, "SELECT id, username, password_hash, full_name, role, room_id FROM users")
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Database error: %v", err)
	}
	defer rows.Close()

	var users []*pb.User
	for rows.Next() {
		var u pb.User
		var roomId sql.NullInt64
		if err := rows.Scan(&u.Id, &u.Username, &u.PasswordHash, &u.FullName, &u.Role, &roomId); err != nil {
			return nil, status.Errorf(codes.Internal, "Scan error: %v", err)
		}
		if roomId.Valid {
			u.RoomId = ptrInt32(int32(roomId.Int64))
		}
		users = append(users, &u)
	}

	return &pb.UserList{Users: users}, nil
}

func (s *MediCoreService) GetUserById(ctx context.Context, req *pb.IntId) (*pb.User, error) {
	var u pb.User
	var roomId sql.NullInt64
	err := s.db.QueryRowContext(ctx,
		"SELECT id, username, password_hash, full_name, role, room_id FROM users WHERE id = ?",
		req.Id).Scan(&u.Id, &u.Username, &u.PasswordHash, &u.FullName, &u.Role, &roomId)

	if err == sql.ErrNoRows {
		return nil, status.Errorf(codes.NotFound, "User not found")
	}
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Database error: %v", err)
	}

	if roomId.Valid {
		u.RoomId = ptrInt32(int32(roomId.Int64))
	}

	return &u, nil
}

func (s *MediCoreService) GetUserByUsername(ctx context.Context, req *pb.UsernameRequest) (*pb.User, error) {
	var u pb.User
	var roomId sql.NullInt64
	err := s.db.QueryRowContext(ctx,
		"SELECT id, username, password_hash, full_name, role, room_id FROM users WHERE username = ?",
		req.Username).Scan(&u.Id, &u.Username, &u.PasswordHash, &u.FullName, &u.Role, &roomId)

	if err == sql.ErrNoRows {
		return nil, status.Errorf(codes.NotFound, "User not found")
	}
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Database error: %v", err)
	}

	if roomId.Valid {
		u.RoomId = ptrInt32(int32(roomId.Int64))
	}

	return &u, nil
}

// ==================== PATIENTS ====================

func (s *MediCoreService) GetAllPatients(ctx context.Context, req *pb.Empty) (*pb.PatientList, error) {
	rows, err := s.db.QueryContext(ctx, "SELECT code, first_name, last_name, date_of_birth, phone, address, insurance, notes FROM patients ORDER BY code")
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Database error: %v", err)
	}
	defer rows.Close()

	var patients []*pb.Patient
	for rows.Next() {
		var p pb.Patient
		var dob, phone, address, insurance, notes sql.NullString
		if err := rows.Scan(&p.Code, &p.FirstName, &p.LastName, &dob, &phone, &address, &insurance, &notes); err != nil {
			return nil, status.Errorf(codes.Internal, "Scan error: %v", err)
		}
		if dob.Valid {
			p.DateOfBirth = ptrString(dob.String)
		}
		if phone.Valid {
			p.Phone = ptrString(phone.String)
		}
		if address.Valid {
			p.Address = ptrString(address.String)
		}
		if insurance.Valid {
			p.Insurance = ptrString(insurance.String)
		}
		if notes.Valid {
			p.Notes = ptrString(notes.String)
		}
		patients = append(patients, &p)
	}

	return &pb.PatientList{Patients: patients}, nil
}

func (s *MediCoreService) GetPatientByCode(ctx context.Context, req *pb.PatientCodeRequest) (*pb.Patient, error) {
	var p pb.Patient
	var dob, phone, address, insurance, notes sql.NullString

	err := s.db.QueryRowContext(ctx,
		"SELECT code, first_name, last_name, date_of_birth, phone, address, insurance, notes FROM patients WHERE code = ?",
		req.PatientCode).Scan(&p.Code, &p.FirstName, &p.LastName, &dob, &phone, &address, &insurance, &notes)

	if err == sql.ErrNoRows {
		return nil, status.Errorf(codes.NotFound, "Patient not found")
	}
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Database error: %v", err)
	}

	if dob.Valid {
		p.DateOfBirth = ptrString(dob.String)
	}
	if phone.Valid {
		p.Phone = ptrString(phone.String)
	}
	if address.Valid {
		p.Address = ptrString(address.String)
	}
	if insurance.Valid {
		p.Insurance = ptrString(insurance.String)
	}
	if notes.Valid {
		p.Notes = ptrString(notes.String)
	}

	return &p, nil
}

func (s *MediCoreService) SearchPatients(ctx context.Context, req *pb.StringQuery) (*pb.PatientList, error) {
	query := "%" + req.Query + "%"
	rows, err := s.db.QueryContext(ctx,
		`SELECT code, first_name, last_name, date_of_birth, phone, address, insurance, notes 
		 FROM patients 
		 WHERE first_name LIKE ? OR last_name LIKE ? OR CAST(code AS TEXT) LIKE ?
		 ORDER BY last_name, first_name
		 LIMIT 50`,
		query, query, query)

	if err != nil {
		return nil, status.Errorf(codes.Internal, "Database error: %v", err)
	}
	defer rows.Close()

	var patients []*pb.Patient
	for rows.Next() {
		var p pb.Patient
		var dob, phone, address, insurance, notes sql.NullString
		if err := rows.Scan(&p.Code, &p.FirstName, &p.LastName, &dob, &phone, &address, &insurance, &notes); err != nil {
			return nil, status.Errorf(codes.Internal, "Scan error: %v", err)
		}
		if dob.Valid {
			p.DateOfBirth = ptrString(dob.String)
		}
		if phone.Valid {
			p.Phone = ptrString(phone.String)
		}
		if address.Valid {
			p.Address = ptrString(address.String)
		}
		if insurance.Valid {
			p.Insurance = ptrString(insurance.String)
		}
		if notes.Valid {
			p.Notes = ptrString(notes.String)
		}
		patients = append(patients, &p)
	}

	return &pb.PatientList{Patients: patients}, nil
}

// ==================== MESSAGES ====================

func (s *MediCoreService) GetMessagesByRecipient(ctx context.Context, req *pb.UserIdRequest) (*pb.MessageList, error) {
	rows, err := s.db.QueryContext(ctx,
		`SELECT id, sender_id, recipient_id, content, created_at, is_read, patient_code, patient_name 
		 FROM messages 
		 WHERE recipient_id = ? 
		 ORDER BY created_at DESC`,
		req.UserId)

	if err != nil {
		return nil, status.Errorf(codes.Internal, "Database error: %v", err)
	}
	defer rows.Close()

	var messages []*pb.Message
	for rows.Next() {
		var m pb.Message
		var createdAt time.Time
		var patientCode sql.NullInt64
		var patientName sql.NullString

		if err := rows.Scan(&m.Id, &m.SenderId, &m.RecipientId, &m.Content, &createdAt, &m.IsRead, &patientCode, &patientName); err != nil {
			return nil, status.Errorf(codes.Internal, "Scan error: %v", err)
		}

		m.CreatedAt = createdAt.Format(time.RFC3339)
		if patientCode.Valid {
			m.PatientCode = ptrInt32(int32(patientCode.Int64))
		}
		if patientName.Valid {
			m.PatientName = ptrString(patientName.String)
		}

		messages = append(messages, &m)
	}

	return &pb.MessageList{Messages: messages}, nil
}

func (s *MediCoreService) GetUnreadMessages(ctx context.Context, req *pb.UserIdRequest) (*pb.MessageList, error) {
	rows, err := s.db.QueryContext(ctx,
		`SELECT id, sender_id, recipient_id, content, created_at, is_read, patient_code, patient_name 
		 FROM messages 
		 WHERE recipient_id = ? AND is_read = 0 
		 ORDER BY created_at DESC`,
		req.UserId)

	if err != nil {
		return nil, status.Errorf(codes.Internal, "Database error: %v", err)
	}
	defer rows.Close()

	var messages []*pb.Message
	for rows.Next() {
		var m pb.Message
		var createdAt time.Time
		var patientCode sql.NullInt64
		var patientName sql.NullString

		if err := rows.Scan(&m.Id, &m.SenderId, &m.RecipientId, &m.Content, &createdAt, &m.IsRead, &patientCode, &patientName); err != nil {
			return nil, status.Errorf(codes.Internal, "Scan error: %v", err)
		}

		m.CreatedAt = createdAt.Format(time.RFC3339)
		if patientCode.Valid {
			m.PatientCode = ptrInt32(int32(patientCode.Int64))
		}
		if patientName.Valid {
			m.PatientName = ptrString(patientName.String)
		}

		messages = append(messages, &m)
	}

	return &pb.MessageList{Messages: messages}, nil
}

func (s *MediCoreService) CreateMessage(ctx context.Context, req *pb.CreateMessageRequest) (*pb.IntId, error) {
	now := time.Now().Format(time.RFC3339)
	result, err := s.db.ExecContext(ctx,
		"INSERT INTO messages (sender_id, recipient_id, content, created_at, is_read, patient_code, patient_name) VALUES (?, ?, ?, ?, 0, ?, ?)",
		req.SenderId, req.RecipientId, req.Content, now, req.PatientCode, req.PatientName)

	if err != nil {
		return nil, status.Errorf(codes.Internal, "Failed to create message: %v", err)
	}

	id, err := result.LastInsertId()
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Failed to get insert ID: %v", err)
	}

	return &pb.IntId{Id: int32(id)}, nil
}

func (s *MediCoreService) MarkMessageAsRead(ctx context.Context, req *pb.IntId) (*pb.Empty, error) {
	_, err := s.db.ExecContext(ctx, "UPDATE messages SET is_read = 1 WHERE id = ?", req.Id)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Failed to mark message as read: %v", err)
	}
	return &pb.Empty{}, nil
}

func (s *MediCoreService) DeleteMessage(ctx context.Context, req *pb.IntId) (*pb.Empty, error) {
	_, err := s.db.ExecContext(ctx, "DELETE FROM messages WHERE id = ?", req.Id)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Failed to delete message: %v", err)
	}
	return &pb.Empty{}, nil
}

// ==================== WAITING PATIENTS ====================

func (s *MediCoreService) GetWaitingPatients(ctx context.Context, req *pb.Empty) (*pb.WaitingPatientList, error) {
	rows, err := s.db.QueryContext(ctx,
		`SELECT id, patient_code, patient_name, arrival_time, room_id, patient_age, is_urgent, is_dilatation, dilatation_type 
		 FROM waiting_patients 
		 ORDER BY arrival_time`)

	if err != nil {
		return nil, status.Errorf(codes.Internal, "Database error: %v", err)
	}
	defer rows.Close()

	var patients []*pb.WaitingPatient
	for rows.Next() {
		var wp pb.WaitingPatient
		var arrivalTime time.Time
		var roomId, patientAge sql.NullInt64
		var dilatationType sql.NullString

		if err := rows.Scan(&wp.Id, &wp.PatientCode, &wp.PatientName, &arrivalTime, &roomId, &patientAge, &wp.IsUrgent, &wp.IsDilatation, &dilatationType); err != nil {
			return nil, status.Errorf(codes.Internal, "Scan error: %v", err)
		}

		wp.ArrivalTime = arrivalTime.Format(time.RFC3339)
		if roomId.Valid {
			wp.RoomId = ptrInt32(int32(roomId.Int64))
		}
		if patientAge.Valid {
			wp.PatientAge = ptrInt32(int32(patientAge.Int64))
		}
		if dilatationType.Valid {
			wp.DilatationType = ptrString(dilatationType.String)
		}

		patients = append(patients, &wp)
	}

	return &pb.WaitingPatientList{Patients: patients}, nil
}

func (s *MediCoreService) GetWaitingPatientsByRoom(ctx context.Context, req *pb.RoomIdRequest) (*pb.WaitingPatientList, error) {
	rows, err := s.db.QueryContext(ctx,
		`SELECT id, patient_code, patient_name, arrival_time, room_id, patient_age, is_urgent, is_dilatation, dilatation_type 
		 FROM waiting_patients 
		 WHERE room_id = ?
		 ORDER BY arrival_time`,
		req.RoomId)

	if err != nil {
		return nil, status.Errorf(codes.Internal, "Database error: %v", err)
	}
	defer rows.Close()

	var patients []*pb.WaitingPatient
	for rows.Next() {
		var wp pb.WaitingPatient
		var arrivalTime time.Time
		var roomId, patientAge sql.NullInt64
		var dilatationType sql.NullString

		if err := rows.Scan(&wp.Id, &wp.PatientCode, &wp.PatientName, &arrivalTime, &roomId, &patientAge, &wp.IsUrgent, &wp.IsDilatation, &dilatationType); err != nil {
			return nil, status.Errorf(codes.Internal, "Scan error: %v", err)
		}

		wp.ArrivalTime = arrivalTime.Format(time.RFC3339)
		if roomId.Valid {
			wp.RoomId = ptrInt32(int32(roomId.Int64))
		}
		if patientAge.Valid {
			wp.PatientAge = ptrInt32(int32(patientAge.Int64))
		}
		if dilatationType.Valid {
			wp.DilatationType = ptrString(dilatationType.String)
		}

		patients = append(patients, &wp)
	}

	return &pb.WaitingPatientList{Patients: patients}, nil
}

func (s *MediCoreService) AddWaitingPatient(ctx context.Context, req *pb.CreateWaitingPatientRequest) (*pb.IntId, error) {
	now := time.Now().Format(time.RFC3339)
	result, err := s.db.ExecContext(ctx,
		`INSERT INTO waiting_patients (patient_code, patient_name, arrival_time, room_id, patient_age, is_urgent, is_dilatation, dilatation_type) 
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
		req.PatientCode, req.PatientName, now, req.RoomId, req.PatientAge, req.IsUrgent, req.IsDilatation, req.DilatationType)

	if err != nil {
		return nil, status.Errorf(codes.Internal, "Failed to add waiting patient: %v", err)
	}

	id, err := result.LastInsertId()
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Failed to get insert ID: %v", err)
	}

	return &pb.IntId{Id: int32(id)}, nil
}

func (s *MediCoreService) RemoveWaitingPatient(ctx context.Context, req *pb.IntId) (*pb.Empty, error) {
	_, err := s.db.ExecContext(ctx, "DELETE FROM waiting_patients WHERE id = ?", req.Id)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Failed to remove waiting patient: %v", err)
	}
	return &pb.Empty{}, nil
}

func (s *MediCoreService) ClearWaitingRoom(ctx context.Context, req *pb.Empty) (*pb.Empty, error) {
	_, err := s.db.ExecContext(ctx, "DELETE FROM waiting_patients")
	if err != nil {
		return nil, status.Errorf(codes.Internal, "Failed to clear waiting room: %v", err)
	}
	return &pb.Empty{}, nil
}

// ==================== STUB IMPLEMENTATIONS ====================
// These return empty results but prevent crashes

func (s *MediCoreService) CreateUser(ctx context.Context, req *pb.CreateUserRequest) (*pb.IntId, error) {
	return nil, status.Errorf(codes.Unimplemented, "CreateUser not implemented yet")
}

func (s *MediCoreService) UpdateUser(ctx context.Context, req *pb.User) (*pb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "UpdateUser not implemented yet")
}

func (s *MediCoreService) DeleteUser(ctx context.Context, req *pb.IntId) (*pb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "DeleteUser not implemented yet")
}

func (s *MediCoreService) GetAllRooms(ctx context.Context, req *pb.Empty) (*pb.RoomList, error) {
	return &pb.RoomList{Rooms: []*pb.Room{}}, nil
}

func (s *MediCoreService) GetRoomById(ctx context.Context, req *pb.IntId) (*pb.Room, error) {
	return nil, status.Errorf(codes.Unimplemented, "GetRoomById not implemented yet")
}

func (s *MediCoreService) CreateRoom(ctx context.Context, req *pb.CreateRoomRequest) (*pb.IntId, error) {
	return nil, status.Errorf(codes.Unimplemented, "CreateRoom not implemented yet")
}

func (s *MediCoreService) UpdateRoom(ctx context.Context, req *pb.Room) (*pb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "UpdateRoom not implemented yet")
}

func (s *MediCoreService) DeleteRoom(ctx context.Context, req *pb.IntId) (*pb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "DeleteRoom not implemented yet")
}

func (s *MediCoreService) CreatePatient(ctx context.Context, req *pb.CreatePatientRequest) (*pb.IntId, error) {
	return nil, status.Errorf(codes.Unimplemented, "CreatePatient not implemented yet")
}

func (s *MediCoreService) UpdatePatient(ctx context.Context, req *pb.Patient) (*pb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "UpdatePatient not implemented yet")
}

func (s *MediCoreService) DeletePatient(ctx context.Context, req *pb.PatientCodeRequest) (*pb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "DeletePatient not implemented yet")
}

func (s *MediCoreService) UpdateWaitingPatient(ctx context.Context, req *pb.WaitingPatient) (*pb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "UpdateWaitingPatient not implemented yet")
}

func (s *MediCoreService) GetVisitsByPatient(ctx context.Context, req *pb.PatientCodeRequest) (*pb.VisitList, error) {
	return &pb.VisitList{Visits: []*pb.Visit{}}, nil
}

func (s *MediCoreService) GetVisitsByDoctor(ctx context.Context, req *pb.UserIdRequest) (*pb.VisitList, error) {
	return &pb.VisitList{Visits: []*pb.Visit{}}, nil
}

func (s *MediCoreService) GetTodayVisits(ctx context.Context, req *pb.Empty) (*pb.VisitList, error) {
	return &pb.VisitList{Visits: []*pb.Visit{}}, nil
}

func (s *MediCoreService) CreateVisit(ctx context.Context, req *pb.CreateVisitRequest) (*pb.IntId, error) {
	return nil, status.Errorf(codes.Unimplemented, "CreateVisit not implemented yet")
}

func (s *MediCoreService) UpdateVisit(ctx context.Context, req *pb.Visit) (*pb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "UpdateVisit not implemented yet")
}

func (s *MediCoreService) GetAllMedicalActs(ctx context.Context, req *pb.Empty) (*pb.MedicalActList, error) {
	return &pb.MedicalActList{Acts: []*pb.MedicalAct{}}, nil
}

func (s *MediCoreService) GetMedicalActById(ctx context.Context, req *pb.IntId) (*pb.MedicalAct, error) {
	return nil, status.Errorf(codes.Unimplemented, "GetMedicalActById not implemented yet")
}

func (s *MediCoreService) GetOrdonnancesByPatient(ctx context.Context, req *pb.PatientCodeRequest) (*pb.OrdonnanceList, error) {
	return &pb.OrdonnanceList{Ordonnances: []*pb.Ordonnance{}}, nil
}

func (s *MediCoreService) CreateOrdonnance(ctx context.Context, req *pb.CreateOrdonnanceRequest) (*pb.IntId, error) {
	return nil, status.Errorf(codes.Unimplemented, "CreateOrdonnance not implemented yet")
}

func (s *MediCoreService) UpdateOrdonnance(ctx context.Context, req *pb.Ordonnance) (*pb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "UpdateOrdonnance not implemented yet")
}

func (s *MediCoreService) DeleteOrdonnance(ctx context.Context, req *pb.IntId) (*pb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "DeleteOrdonnance not implemented yet")
}

func (s *MediCoreService) GetMedicationsByOrdonnance(ctx context.Context, req *pb.OrdonnanceIdRequest) (*pb.MedicationList, error) {
	return &pb.MedicationList{Medications: []*pb.Medication{}}, nil
}

func (s *MediCoreService) CreateMedication(ctx context.Context, req *pb.CreateMedicationRequest) (*pb.IntId, error) {
	return nil, status.Errorf(codes.Unimplemented, "CreateMedication not implemented yet")
}

func (s *MediCoreService) DeleteMedication(ctx context.Context, req *pb.IntId) (*pb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "DeleteMedication not implemented yet")
}

func (s *MediCoreService) GetPaymentsByPatient(ctx context.Context, req *pb.PatientCodeRequest) (*pb.PaymentList, error) {
	return &pb.PaymentList{Payments: []*pb.Payment{}}, nil
}

func (s *MediCoreService) GetPaymentsByDateRange(ctx context.Context, req *pb.DateRange) (*pb.PaymentList, error) {
	return &pb.PaymentList{Payments: []*pb.Payment{}}, nil
}

func (s *MediCoreService) CreatePayment(ctx context.Context, req *pb.CreatePaymentRequest) (*pb.IntId, error) {
	return nil, status.Errorf(codes.Unimplemented, "CreatePayment not implemented yet")
}

func (s *MediCoreService) UpdatePayment(ctx context.Context, req *pb.Payment) (*pb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "UpdatePayment not implemented yet")
}

func (s *MediCoreService) GetAllTemplates(ctx context.Context, req *pb.Empty) (*pb.TemplateList, error) {
	return &pb.TemplateList{Templates: []*pb.Template{}}, nil
}

func (s *MediCoreService) GetTemplateById(ctx context.Context, req *pb.IntId) (*pb.Template, error) {
	return nil, status.Errorf(codes.Unimplemented, "GetTemplateById not implemented yet")
}

func (s *MediCoreService) CreateTemplate(ctx context.Context, req *pb.CreateTemplateRequest) (*pb.IntId, error) {
	return nil, status.Errorf(codes.Unimplemented, "CreateTemplate not implemented yet")
}

func (s *MediCoreService) UpdateTemplate(ctx context.Context, req *pb.Template) (*pb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "UpdateTemplate not implemented yet")
}

func (s *MediCoreService) DeleteTemplate(ctx context.Context, req *pb.IntId) (*pb.Empty, error) {
	return nil, status.Errorf(codes.Unimplemented, "DeleteTemplate not implemented yet")
}

func (s *MediCoreService) GetAllMessageTemplates(ctx context.Context, req *pb.Empty) (*pb.MessageTemplateList, error) {
	return &pb.MessageTemplateList{Templates: []*pb.MessageTemplate{}}, nil
}

func (s *MediCoreService) GetMessageTemplateById(ctx context.Context, req *pb.IntId) (*pb.MessageTemplate, error) {
	return nil, status.Errorf(codes.Unimplemented, "GetMessageTemplateById not implemented yet")
}

// Helper functions for protobuf optional fields
func ptrInt32(v int32) *int32 {
	return &v
}

func ptrString(v string) *string {
	return &v
}
