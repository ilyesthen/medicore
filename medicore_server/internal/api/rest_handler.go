package api

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"strings"
)

// RESTHandler provides HTTP/JSON API endpoints for Flutter clients
// This allows clients to communicate without full gRPC implementation
type RESTHandler struct {
	db *sql.DB
}

// NewRESTHandler creates a new REST API handler
func NewRESTHandler(db *sql.DB) *RESTHandler {
	return &RESTHandler{db: db}
}

// SetupRoutes configures all REST API routes
func (h *RESTHandler) SetupRoutes(mux *http.ServeMux) {
	// CORS middleware wrapper
	cors := func(handler http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
			w.Header().Set("Content-Type", "application/json")

			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusOK)
				return
			}
			handler(w, r)
		}
	}

	// User endpoints
	mux.HandleFunc("/api/GetAllUsers", cors(h.GetAllUsers))
	mux.HandleFunc("/api/GetUserById", cors(h.GetUserById))
	mux.HandleFunc("/api/GetUserByUsername", cors(h.GetUserByUsername))
	mux.HandleFunc("/api/CreateUser", cors(h.CreateUser))
	mux.HandleFunc("/api/UpdateUser", cors(h.UpdateUser))
	mux.HandleFunc("/api/DeleteUser", cors(h.DeleteUser))

	// Room endpoints
	mux.HandleFunc("/api/GetAllRooms", cors(h.GetAllRooms))
	mux.HandleFunc("/api/GetRoomById", cors(h.GetRoomById))
	mux.HandleFunc("/api/CreateRoom", cors(h.CreateRoom))
	mux.HandleFunc("/api/UpdateRoom", cors(h.UpdateRoom))
	mux.HandleFunc("/api/DeleteRoom", cors(h.DeleteRoom))

	// Patient endpoints
	mux.HandleFunc("/api/GetAllPatients", cors(h.GetAllPatients))
	mux.HandleFunc("/api/GetPatientByCode", cors(h.GetPatientByCode))
	mux.HandleFunc("/api/SearchPatients", cors(h.SearchPatients))
	mux.HandleFunc("/api/CreatePatient", cors(h.CreatePatient))
	mux.HandleFunc("/api/UpdatePatient", cors(h.UpdatePatient))
	mux.HandleFunc("/api/DeletePatient", cors(h.DeletePatient))

	// Message endpoints
	mux.HandleFunc("/api/GetMessagesByRoom", cors(h.GetMessagesByRoom))
	mux.HandleFunc("/api/CreateMessage", cors(h.CreateMessage))
	mux.HandleFunc("/api/DeleteMessage", cors(h.DeleteMessage))

	// Waiting patient endpoints
	mux.HandleFunc("/api/GetWaitingPatientsByRoom", cors(h.GetWaitingPatientsByRoom))
	mux.HandleFunc("/api/AddWaitingPatient", cors(h.AddWaitingPatient))
	mux.HandleFunc("/api/UpdateWaitingPatient", cors(h.UpdateWaitingPatient))
	mux.HandleFunc("/api/RemoveWaitingPatient", cors(h.RemoveWaitingPatient))

	// Medical act endpoints
	mux.HandleFunc("/api/GetAllMedicalActs", cors(h.GetAllMedicalActs))
	mux.HandleFunc("/api/GetMedicalActById", cors(h.GetMedicalActById))

	log.Println("📡 REST API endpoints registered")
}

// Helper to decode JSON request body
func decodeBody(r *http.Request, v interface{}) error {
	return json.NewDecoder(r.Body).Decode(v)
}

// Helper to encode JSON response
func respondJSON(w http.ResponseWriter, data interface{}) {
	json.NewEncoder(w).Encode(data)
}

// Helper to respond with error
func respondError(w http.ResponseWriter, code int, message string) {
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]string{"error": message})
}

// ==================== USER HANDLERS ====================

func (h *RESTHandler) GetAllUsers(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(`
		SELECT id, name, role, password_hash, percentage, is_template_user 
		FROM users WHERE deleted_at IS NULL
	`)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	users := []map[string]interface{}{}
	for rows.Next() {
		var id, name, role, passwordHash string
		var percentage sql.NullFloat64
		var isTemplateUser bool

		if err := rows.Scan(&id, &name, &role, &passwordHash, &percentage, &isTemplateUser); err != nil {
			continue
		}

		user := map[string]interface{}{
			"id":               id,
			"username":         name,
			"full_name":        name,
			"role":             role,
			"password_hash":    passwordHash,
			"is_template_user": isTemplateUser,
		}
		if percentage.Valid {
			user["percentage"] = percentage.Float64
		}
		users = append(users, user)
	}

	respondJSON(w, map[string]interface{}{"users": users})
}

func (h *RESTHandler) GetUserById(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := req["id"]
	row := h.db.QueryRow(`
		SELECT id, name, role, password_hash, percentage, is_template_user 
		FROM users WHERE id = ? AND deleted_at IS NULL
	`, id)

	var userId, name, role, passwordHash string
	var percentage sql.NullFloat64
	var isTemplateUser bool

	if err := row.Scan(&userId, &name, &role, &passwordHash, &percentage, &isTemplateUser); err != nil {
		respondJSON(w, map[string]interface{}{})
		return
	}

	user := map[string]interface{}{
		"id":            userId,
		"username":      name,
		"full_name":     name,
		"role":          role,
		"password_hash": passwordHash,
	}
	if percentage.Valid {
		user["percentage"] = percentage.Float64
	}

	respondJSON(w, user)
}

func (h *RESTHandler) GetUserByUsername(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	username := req["username"].(string)
	row := h.db.QueryRow(`
		SELECT id, name, role, password_hash, percentage, is_template_user 
		FROM users WHERE name = ? AND deleted_at IS NULL
	`, username)

	var userId, name, role, passwordHash string
	var percentage sql.NullFloat64
	var isTemplateUser bool

	if err := row.Scan(&userId, &name, &role, &passwordHash, &percentage, &isTemplateUser); err != nil {
		respondJSON(w, map[string]interface{}{})
		return
	}

	user := map[string]interface{}{
		"id":            userId,
		"username":      name,
		"full_name":     name,
		"role":          role,
		"password_hash": passwordHash,
	}
	if percentage.Valid {
		user["percentage"] = percentage.Float64
	}

	respondJSON(w, user)
}

func (h *RESTHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	result, err := h.db.Exec(`
		INSERT INTO users (id, name, role, password_hash, percentage, is_template_user, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
	`, req["id"], req["full_name"], req["role"], req["password_hash"], req["percentage"], false)

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	id, _ := result.LastInsertId()
	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) UpdateUser(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	_, err := h.db.Exec(`
		UPDATE users SET name = ?, role = ?, password_hash = ?, percentage = ?, updated_at = datetime('now')
		WHERE id = ?
	`, req["full_name"], req["role"], req["password_hash"], req["percentage"], req["id"])

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	_, err := h.db.Exec(`UPDATE users SET deleted_at = datetime('now') WHERE id = ?`, req["id"])
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	respondJSON(w, map[string]interface{}{})
}

// ==================== ROOM HANDLERS ====================

func (h *RESTHandler) GetAllRooms(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(`SELECT id, name FROM rooms`)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	rooms := []map[string]interface{}{}
	for rows.Next() {
		var id, name string
		if err := rows.Scan(&id, &name); err != nil {
			continue
		}
		rooms = append(rooms, map[string]interface{}{
			"id":   id,
			"name": name,
		})
	}

	respondJSON(w, map[string]interface{}{"rooms": rooms})
}

func (h *RESTHandler) GetRoomById(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := req["id"]
	row := h.db.QueryRow(`SELECT id, name FROM rooms WHERE id = ?`, id)

	var roomId, name string
	if err := row.Scan(&roomId, &name); err != nil {
		respondJSON(w, map[string]interface{}{})
		return
	}

	respondJSON(w, map[string]interface{}{"id": roomId, "name": name})
}

func (h *RESTHandler) CreateRoom(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	result, err := h.db.Exec(`
		INSERT INTO rooms (id, name, created_at, updated_at)
		VALUES (?, ?, datetime('now'), datetime('now'))
	`, req["id"], req["name"])

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	id, _ := result.LastInsertId()
	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) UpdateRoom(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	_, err := h.db.Exec(`UPDATE rooms SET name = ?, updated_at = datetime('now') WHERE id = ?`, req["name"], req["id"])
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) DeleteRoom(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	_, err := h.db.Exec(`DELETE FROM rooms WHERE id = ?`, req["id"])
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	respondJSON(w, map[string]interface{}{})
}

// ==================== PATIENT HANDLERS ====================

func (h *RESTHandler) GetAllPatients(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(`
		SELECT code, barcode, first_name, last_name, age, date_of_birth, address, phone_number, other_info, created_at
		FROM patients ORDER BY code DESC LIMIT 1000
	`)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	patients := []map[string]interface{}{}
	for rows.Next() {
		var code int
		var barcode, firstName, lastName string
		var age sql.NullInt64
		var dateOfBirth, address, phone, otherInfo, createdAt sql.NullString

		if err := rows.Scan(&code, &barcode, &firstName, &lastName, &age, &dateOfBirth, &address, &phone, &otherInfo, &createdAt); err != nil {
			continue
		}

		patient := map[string]interface{}{
			"code":       code,
			"barcode":    barcode,
			"first_name": firstName,
			"last_name":  lastName,
		}
		if age.Valid {
			patient["age"] = age.Int64
		}
		if dateOfBirth.Valid {
			patient["date_of_birth"] = dateOfBirth.String
		}
		if address.Valid {
			patient["address"] = address.String
		}
		if phone.Valid {
			patient["phone"] = phone.String
		}
		patients = append(patients, patient)
	}

	respondJSON(w, map[string]interface{}{"patients": patients})
}

func (h *RESTHandler) GetPatientByCode(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	code := int(req["patient_code"].(float64))
	row := h.db.QueryRow(`
		SELECT code, barcode, first_name, last_name, age, date_of_birth, address, phone_number
		FROM patients WHERE code = ?
	`, code)

	var patientCode int
	var barcode, firstName, lastName string
	var age sql.NullInt64
	var dateOfBirth, address, phone sql.NullString

	if err := row.Scan(&patientCode, &barcode, &firstName, &lastName, &age, &dateOfBirth, &address, &phone); err != nil {
		respondJSON(w, map[string]interface{}{})
		return
	}

	patient := map[string]interface{}{
		"code":       patientCode,
		"barcode":    barcode,
		"first_name": firstName,
		"last_name":  lastName,
	}
	if age.Valid {
		patient["age"] = age.Int64
	}

	respondJSON(w, patient)
}

func (h *RESTHandler) SearchPatients(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	query := "%" + strings.ToLower(req["query"].(string)) + "%"
	rows, err := h.db.Query(`
		SELECT code, barcode, first_name, last_name, age
		FROM patients 
		WHERE LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR CAST(code AS TEXT) LIKE ?
		ORDER BY code DESC LIMIT 100
	`, query, query, query)

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	patients := []map[string]interface{}{}
	for rows.Next() {
		var code int
		var barcode, firstName, lastName string
		var age sql.NullInt64

		if err := rows.Scan(&code, &barcode, &firstName, &lastName, &age); err != nil {
			continue
		}

		patient := map[string]interface{}{
			"code":       code,
			"barcode":    barcode,
			"first_name": firstName,
			"last_name":  lastName,
		}
		if age.Valid {
			patient["age"] = age.Int64
		}
		patients = append(patients, patient)
	}

	respondJSON(w, map[string]interface{}{"patients": patients})
}

func (h *RESTHandler) CreatePatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	code := int(req["code"].(float64))
	_, err := h.db.Exec(`
		INSERT INTO patients (code, barcode, first_name, last_name, age, address, phone_number, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'), datetime('now'))
	`, code, req["barcode"], req["first_name"], req["last_name"], req["age"], req["address"], req["phone"])

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	respondJSON(w, map[string]interface{}{"code": code})
}

func (h *RESTHandler) UpdatePatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	code := int(req["code"].(float64))
	_, err := h.db.Exec(`
		UPDATE patients SET first_name = ?, last_name = ?, age = ?, address = ?, phone_number = ?, updated_at = datetime('now')
		WHERE code = ?
	`, req["first_name"], req["last_name"], req["age"], req["address"], req["phone"], code)

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) DeletePatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	code := int(req["patient_code"].(float64))
	_, err := h.db.Exec(`DELETE FROM patients WHERE code = ?`, code)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	respondJSON(w, map[string]interface{}{})
}

// ==================== MESSAGE HANDLERS ====================

func (h *RESTHandler) GetMessagesByRoom(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	roomId := req["room_id"].(string)
	rows, err := h.db.Query(`
		SELECT id, room_id, sender_id, sender_name, sender_role, content, direction, is_read, sent_at, patient_code, patient_name
		FROM messages WHERE room_id = ? ORDER BY sent_at DESC
	`, roomId)

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	messages := []map[string]interface{}{}
	for rows.Next() {
		var id int
		var roomId, senderId, senderName, senderRole, content, direction, sentAt string
		var isRead bool
		var patientCode sql.NullInt64
		var patientName sql.NullString

		if err := rows.Scan(&id, &roomId, &senderId, &senderName, &senderRole, &content, &direction, &isRead, &sentAt, &patientCode, &patientName); err != nil {
			continue
		}

		msg := map[string]interface{}{
			"id":          id,
			"room_id":     roomId,
			"sender_id":   senderId,
			"sender_name": senderName,
			"sender_role": senderRole,
			"content":     content,
			"direction":   direction,
			"is_read":     isRead,
			"sent_at":     sentAt,
		}
		if patientCode.Valid {
			msg["patient_code"] = patientCode.Int64
		}
		if patientName.Valid {
			msg["patient_name"] = patientName.String
		}
		messages = append(messages, msg)
	}

	respondJSON(w, map[string]interface{}{"messages": messages})
}

func (h *RESTHandler) CreateMessage(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	result, err := h.db.Exec(`
		INSERT INTO messages (room_id, sender_id, sender_name, sender_role, content, direction, is_read, sent_at, patient_code, patient_name)
		VALUES (?, ?, ?, ?, ?, ?, 0, datetime('now'), ?, ?)
	`, req["room_id"], req["sender_id"], req["sender_name"], req["sender_role"], req["content"], req["direction"], req["patient_code"], req["patient_name"])

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	id, _ := result.LastInsertId()
	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) DeleteMessage(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	_, err := h.db.Exec(`DELETE FROM messages WHERE id = ?`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	respondJSON(w, map[string]interface{}{})
}

// ==================== WAITING PATIENT HANDLERS ====================

func (h *RESTHandler) GetWaitingPatientsByRoom(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	roomId := req["room_id"].(string)
	rows, err := h.db.Query(`
		SELECT id, patient_code, patient_first_name, patient_last_name, patient_age, is_urgent, is_dilatation, 
			   dilatation_type, room_id, room_name, motif, sent_by_user_id, sent_by_user_name, sent_at, is_checked, is_active
		FROM waiting_patients WHERE room_id = ? AND is_active = 1 ORDER BY sent_at ASC
	`, roomId)

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	patients := []map[string]interface{}{}
	for rows.Next() {
		var id, patientCode int
		var patientFirstName, patientLastName, roomId, roomName, motif, sentByUserId, sentByUserName, sentAt string
		var patientAge sql.NullInt64
		var dilatationType sql.NullString
		var isUrgent, isDilatation, isChecked, isActive bool

		if err := rows.Scan(&id, &patientCode, &patientFirstName, &patientLastName, &patientAge, &isUrgent, &isDilatation,
			&dilatationType, &roomId, &roomName, &motif, &sentByUserId, &sentByUserName, &sentAt, &isChecked, &isActive); err != nil {
			continue
		}

		patient := map[string]interface{}{
			"id":                 id,
			"patient_code":       patientCode,
			"patient_first_name": patientFirstName,
			"patient_last_name":  patientLastName,
			"is_urgent":          isUrgent,
			"is_dilatation":      isDilatation,
			"room_id":            roomId,
			"room_name":          roomName,
			"motif":              motif,
			"sent_by_user_id":    sentByUserId,
			"sent_by_user_name":  sentByUserName,
			"sent_at":            sentAt,
			"is_checked":         isChecked,
			"is_active":          isActive,
		}
		if patientAge.Valid {
			patient["patient_age"] = patientAge.Int64
		}
		if dilatationType.Valid {
			patient["dilatation_type"] = dilatationType.String
		}
		patients = append(patients, patient)
	}

	respondJSON(w, map[string]interface{}{"patients": patients})
}

func (h *RESTHandler) AddWaitingPatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	patientCode := int(req["patient_code"].(float64))
	result, err := h.db.Exec(`
		INSERT INTO waiting_patients (patient_code, patient_first_name, patient_last_name, patient_age, is_urgent, is_dilatation,
			dilatation_type, room_id, room_name, motif, sent_by_user_id, sent_by_user_name, sent_at, is_checked, is_active, is_notified)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'), 0, 1, 0)
	`, patientCode, req["patient_first_name"], req["patient_last_name"], req["patient_age"], req["is_urgent"], req["is_dilatation"],
		req["dilatation_type"], req["room_id"], req["room_name"], req["motif"], req["sent_by_user_id"], req["sent_by_user_name"])

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	id, _ := result.LastInsertId()
	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) UpdateWaitingPatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	_, err := h.db.Exec(`
		UPDATE waiting_patients SET is_checked = ?, is_active = ? WHERE id = ?
	`, req["is_checked"], req["is_active"], id)

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) RemoveWaitingPatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	_, err := h.db.Exec(`UPDATE waiting_patients SET is_active = 0 WHERE id = ?`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	respondJSON(w, map[string]interface{}{})
}

// ==================== MEDICAL ACT HANDLERS ====================

func (h *RESTHandler) GetAllMedicalActs(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(`
		SELECT id, name, fee_amount, display_order FROM medical_acts WHERE is_active = 1 ORDER BY display_order
	`)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	acts := []map[string]interface{}{}
	for rows.Next() {
		var id, feeAmount, displayOrder int
		var name string

		if err := rows.Scan(&id, &name, &feeAmount, &displayOrder); err != nil {
			continue
		}

		acts = append(acts, map[string]interface{}{
			"id":            id,
			"name":          name,
			"fee_amount":    feeAmount,
			"display_order": displayOrder,
		})
	}

	respondJSON(w, map[string]interface{}{"acts": acts})
}

func (h *RESTHandler) GetMedicalActById(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	row := h.db.QueryRow(`SELECT id, name, fee_amount, display_order FROM medical_acts WHERE id = ?`, id)

	var actId, feeAmount, displayOrder int
	var name string

	if err := row.Scan(&actId, &name, &feeAmount, &displayOrder); err != nil {
		respondJSON(w, map[string]interface{}{})
		return
	}

	respondJSON(w, map[string]interface{}{
		"id":            actId,
		"name":          name,
		"fee_amount":    feeAmount,
		"display_order": displayOrder,
	})
}

// StartRESTServer starts the REST API server
func StartRESTServer(db *sql.DB, port string) error {
	handler := NewRESTHandler(db)
	mux := http.NewServeMux()
	handler.SetupRoutes(mux)

	addr := "0.0.0.0:" + port
	log.Printf("🌐 REST API server starting on %s", addr)

	return http.ListenAndServe(addr, mux)
}
