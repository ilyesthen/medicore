package api

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"strings"
	"time"
)

// generateBarcode creates a random 8-character barcode
func generateBarcode() string {
	const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+"
	rand.Seed(time.Now().UnixNano())
	b := make([]byte, 8)
	for i := range b {
		b[i] = chars[rand.Intn(len(chars))]
	}
	return string(b)
}

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
	mux.HandleFunc("/api/GetTemplateUsers", cors(h.GetTemplateUsers))
	mux.HandleFunc("/api/GetPermanentUsers", cors(h.GetPermanentUsers))

	// User template endpoints
	mux.HandleFunc("/api/GetAllUserTemplates", cors(h.GetAllUserTemplates))
	mux.HandleFunc("/api/GetUserTemplateById", cors(h.GetUserTemplateById))
	mux.HandleFunc("/api/CreateUserTemplate", cors(h.CreateUserTemplate))
	mux.HandleFunc("/api/UpdateUserTemplate", cors(h.UpdateUserTemplate))
	mux.HandleFunc("/api/DeleteUserTemplate", cors(h.DeleteUserTemplate))
	mux.HandleFunc("/api/CreateUserFromTemplate", cors(h.CreateUserFromTemplate))

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
	mux.HandleFunc("/api/MarkMessageAsRead", cors(h.MarkMessageAsRead))
	mux.HandleFunc("/api/MarkAllMessagesAsRead", cors(h.MarkAllMessagesAsRead))

	// Message template endpoints
	mux.HandleFunc("/api/GetAllMessageTemplates", cors(h.GetAllMessageTemplates))
	mux.HandleFunc("/api/GetMessageTemplateById", cors(h.GetMessageTemplateById))
	mux.HandleFunc("/api/CreateMessageTemplate", cors(h.CreateMessageTemplate))
	mux.HandleFunc("/api/UpdateMessageTemplate", cors(h.UpdateMessageTemplate))
	mux.HandleFunc("/api/DeleteMessageTemplate", cors(h.DeleteMessageTemplate))
	mux.HandleFunc("/api/ReorderMessageTemplates", cors(h.ReorderMessageTemplates))

	// Waiting patient endpoints
	mux.HandleFunc("/api/GetWaitingPatientsByRoom", cors(h.GetWaitingPatientsByRoom))
	mux.HandleFunc("/api/GetWaitingPatientById", cors(h.GetWaitingPatientById))
	mux.HandleFunc("/api/AddWaitingPatient", cors(h.AddWaitingPatient))
	mux.HandleFunc("/api/UpdateWaitingPatient", cors(h.UpdateWaitingPatient))
	mux.HandleFunc("/api/RemoveWaitingPatient", cors(h.RemoveWaitingPatient))
	mux.HandleFunc("/api/RemoveWaitingPatientByCode", cors(h.RemoveWaitingPatientByCode))
	mux.HandleFunc("/api/MarkDilatationsAsNotified", cors(h.MarkDilatationsAsNotified))

	// Medical act endpoints
	mux.HandleFunc("/api/GetAllMedicalActs", cors(h.GetAllMedicalActs))
	mux.HandleFunc("/api/GetMedicalActById", cors(h.GetMedicalActById))
	mux.HandleFunc("/api/CreateMedicalAct", cors(h.CreateMedicalAct))
	mux.HandleFunc("/api/UpdateMedicalAct", cors(h.UpdateMedicalAct))
	mux.HandleFunc("/api/DeleteMedicalAct", cors(h.DeleteMedicalAct))
	mux.HandleFunc("/api/ReorderMedicalActs", cors(h.ReorderMedicalActs))

	// Visit endpoints
	mux.HandleFunc("/api/GetVisitsForPatient", cors(h.GetVisitsForPatient))
	mux.HandleFunc("/api/GetVisitById", cors(h.GetVisitById))
	mux.HandleFunc("/api/CreateVisit", cors(h.CreateVisit))
	mux.HandleFunc("/api/UpdateVisit", cors(h.UpdateVisit))
	mux.HandleFunc("/api/DeleteVisit", cors(h.DeleteVisit))

	// Ordonnance/Document endpoints
	mux.HandleFunc("/api/GetOrdonnancesForPatient", cors(h.GetOrdonnancesForPatient))
	mux.HandleFunc("/api/CreateOrdonnance", cors(h.CreateOrdonnance))
	mux.HandleFunc("/api/UpdateOrdonnance", cors(h.UpdateOrdonnance))
	mux.HandleFunc("/api/DeleteOrdonnance", cors(h.DeleteOrdonnance))

	// Payment endpoints
	mux.HandleFunc("/api/GetPaymentsForPatient", cors(h.GetPaymentsForPatient))
	mux.HandleFunc("/api/GetPaymentsByPatient", cors(h.GetPaymentsForPatient)) // Alias for historic payments
	mux.HandleFunc("/api/GetPaymentsForVisit", cors(h.GetPaymentsForVisit))
	mux.HandleFunc("/api/GetPaymentsByUserAndDate", cors(h.GetPaymentsByUserAndDate))
	mux.HandleFunc("/api/CreatePayment", cors(h.CreatePayment))
	mux.HandleFunc("/api/UpdatePayment", cors(h.UpdatePayment))
	mux.HandleFunc("/api/DeletePayment", cors(h.DeletePayment))
	mux.HandleFunc("/api/GetPaymentById", cors(h.GetPaymentById))
	mux.HandleFunc("/api/GetAllPaymentsByUser", cors(h.GetAllPaymentsByUser))
	mux.HandleFunc("/api/DeletePaymentsByPatientAndDate", cors(h.DeletePaymentsByPatientAndDate))
	mux.HandleFunc("/api/CountPaymentsByPatientAndDate", cors(h.CountPaymentsByPatientAndDate))
	mux.HandleFunc("/api/GetMaxPaymentId", cors(h.GetMaxPaymentId))

	// Medication endpoints
	mux.HandleFunc("/api/GetAllMedications", cors(h.GetAllMedications))
	mux.HandleFunc("/api/SearchMedications", cors(h.SearchMedications))
	mux.HandleFunc("/api/GetMedicationById", cors(h.GetMedicationById))
	mux.HandleFunc("/api/GetMedicationCount", cors(h.GetMedicationCount))
	mux.HandleFunc("/api/IncrementMedicationUsage", cors(h.IncrementMedicationUsage))
	mux.HandleFunc("/api/SetMedicationUsageCount", cors(h.SetMedicationUsageCount))
	mux.HandleFunc("/api/AddMedication", cors(h.AddMedication))
	mux.HandleFunc("/api/UpdateMedication", cors(h.UpdateMedication))
	mux.HandleFunc("/api/DeleteMedication", cors(h.DeleteMedication))

	// Visit additional endpoints
	mux.HandleFunc("/api/GetTotalVisitCount", cors(h.GetTotalVisitCount))
	mux.HandleFunc("/api/ClearAllVisits", cors(h.ClearAllVisits))
	mux.HandleFunc("/api/InsertVisits", cors(h.InsertVisits))

	// Message additional endpoints
	mux.HandleFunc("/api/GetMessageById", cors(h.GetMessageById))

	// Patient additional endpoints
	mux.HandleFunc("/api/ImportPatient", cors(h.ImportPatient))

	// Nurse preferences endpoints
	mux.HandleFunc("/api/GetNurseRoomPreferences", cors(h.GetNurseRoomPreferences))
	mux.HandleFunc("/api/SaveNurseRoomPreferences", cors(h.SaveNurseRoomPreferences))
	mux.HandleFunc("/api/ClearNurseRoomPreferences", cors(h.ClearNurseRoomPreferences))
	mux.HandleFunc("/api/GetActiveNurses", cors(h.GetActiveNurses))
	mux.HandleFunc("/api/MarkNurseActive", cors(h.MarkNurseActive))
	mux.HandleFunc("/api/MarkNurseInactive", cors(h.MarkNurseInactive))

	// Templates CR endpoints (Compte Rendu templates)
	mux.HandleFunc("/api/GetAllTemplatesCR", cors(h.GetAllTemplatesCR))
	mux.HandleFunc("/api/IncrementTemplateCRUsage", cors(h.IncrementTemplateCRUsage))

	// Appointment endpoints
	mux.HandleFunc("/api/GetAppointmentsForDate", cors(h.GetAppointmentsForDate))
	mux.HandleFunc("/api/GetAllAppointments", cors(h.GetAllAppointments))
	mux.HandleFunc("/api/CreateAppointment", cors(h.CreateAppointment))
	mux.HandleFunc("/api/UpdateAppointmentDate", cors(h.UpdateAppointmentDate))
	mux.HandleFunc("/api/MarkAppointmentAsAdded", cors(h.MarkAppointmentAsAdded))
	mux.HandleFunc("/api/DeleteAppointment", cors(h.DeleteAppointment))
	mux.HandleFunc("/api/CleanupPastAppointments", cors(h.CleanupPastAppointments))

	// Surgery Plan endpoints
	mux.HandleFunc("/api/GetSurgeryPlansForDate", cors(h.GetSurgeryPlansForDate))
	mux.HandleFunc("/api/GetAllSurgeryPlans", cors(h.GetAllSurgeryPlans))
	mux.HandleFunc("/api/CreateSurgeryPlan", cors(h.CreateSurgeryPlan))
	mux.HandleFunc("/api/UpdateSurgeryPlan", cors(h.UpdateSurgeryPlan))
	mux.HandleFunc("/api/RescheduleSurgery", cors(h.RescheduleSurgery))
	mux.HandleFunc("/api/DeleteSurgeryPlan", cors(h.DeleteSurgeryPlan))

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
		FROM users WHERE id = $1 AND deleted_at IS NULL
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
		FROM users WHERE name = $1 AND deleted_at IS NULL
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

	// Auto-generate ID if not provided
	userId := ""
	if id, ok := req["id"].(string); ok && id != "" {
		userId = id
	} else {
		userId = fmt.Sprintf("%d", time.Now().UnixNano()/1e6)
	}

	// Get name from full_name or username
	name := ""
	if fn, ok := req["full_name"].(string); ok && fn != "" {
		name = fn
	} else if un, ok := req["username"].(string); ok {
		name = un
	}

	_, err := h.db.Exec(`
		INSERT INTO users (id, name, role, password_hash, percentage, is_template_user, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
	`, userId, name, req["role"], req["password_hash"], req["percentage"], false)

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	// Broadcast SSE event for real-time sync
	BroadcastUserEvent(EventUserCreated, map[string]interface{}{"id": userId, "name": name})

	respondJSON(w, map[string]interface{}{"id": userId})
}

func (h *RESTHandler) UpdateUser(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	// Get name from full_name or username
	name := ""
	if fn, ok := req["full_name"].(string); ok && fn != "" {
		name = fn
	} else if un, ok := req["username"].(string); ok {
		name = un
	}

	// Get ID from id field (can be string or int)
	userId := ""
	if id, ok := req["id"].(string); ok {
		userId = id
	} else if id, ok := req["id"].(float64); ok {
		userId = fmt.Sprintf("%.0f", id)
	}

	_, err := h.db.Exec(`
		UPDATE users SET name = $1, role = $2, password_hash = $3, percentage = $4, updated_at = NOW()
		WHERE id = $5
	`, name, req["role"], req["password_hash"], req["percentage"], userId)

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	// Broadcast SSE event for real-time sync
	BroadcastUserEvent(EventUserUpdated, map[string]interface{}{"id": userId})

	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	// Get ID from id field (can be string or int)
	userId := ""
	if id, ok := req["id"].(string); ok {
		userId = id
	} else if id, ok := req["id"].(float64); ok {
		userId = fmt.Sprintf("%.0f", id)
	}

	_, err := h.db.Exec(`UPDATE users SET deleted_at = NOW() WHERE id = $1`, userId)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	// Broadcast SSE event for real-time sync
	BroadcastUserEvent(EventUserDeleted, map[string]interface{}{"id": userId})

	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) GetTemplateUsers(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(`
		SELECT id, name, role, password_hash, percentage, is_template_user 
		FROM users WHERE deleted_at IS NULL AND is_template_user = 1
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

func (h *RESTHandler) GetPermanentUsers(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(`
		SELECT id, name, role, password_hash, percentage, is_template_user 
		FROM users WHERE deleted_at IS NULL AND is_template_user = 0 AND id != 'admin'
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

// ==================== USER TEMPLATE HANDLERS ====================

func (h *RESTHandler) GetAllUserTemplates(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(`SELECT id, role, password_hash, percentage, created_at FROM templates WHERE deleted_at IS NULL`)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	templates := []map[string]interface{}{}
	for rows.Next() {
		var id, role, passwordHash, createdAt string
		var percentage float64

		if err := rows.Scan(&id, &role, &passwordHash, &percentage, &createdAt); err != nil {
			continue
		}

		templates = append(templates, map[string]interface{}{
			"id":            id,
			"role":          role,
			"password_hash": passwordHash,
			"percentage":    percentage,
			"created_at":    createdAt,
		})
	}

	respondJSON(w, map[string]interface{}{"templates": templates})
}

func (h *RESTHandler) GetUserTemplateById(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := req["id"].(string)
	row := h.db.QueryRow(`SELECT id, role, password_hash, percentage, created_at FROM templates WHERE id = $1 AND deleted_at IS NULL`, id)

	var role, passwordHash, createdAt string
	var percentage float64
	if err := row.Scan(&id, &role, &passwordHash, &percentage, &createdAt); err != nil {
		respondJSON(w, map[string]interface{}{})
		return
	}

	respondJSON(w, map[string]interface{}{
		"id":            id,
		"role":          role,
		"password_hash": passwordHash,
		"percentage":    percentage,
		"created_at":    createdAt,
	})
}

func (h *RESTHandler) CreateUserTemplate(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := req["id"].(string)
	role := req["role"].(string)
	passwordHash := req["password_hash"].(string)
	percentage := req["percentage"].(float64)

	_, err := h.db.Exec(`
		INSERT INTO templates (id, role, password_hash, percentage, created_at, updated_at, needs_sync)
		VALUES ($1, $2, $3, $4, NOW(), NOW(), 1)
	`, id, role, passwordHash, percentage)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	BroadcastTemplateEvent(EventTemplateCreated, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) UpdateUserTemplate(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := req["id"].(string)
	role := req["role"].(string)
	passwordHash := req["password_hash"].(string)
	percentage := req["percentage"].(float64)

	_, err := h.db.Exec(`UPDATE templates SET role = $1, password_hash = $2, percentage = $3, updated_at = NOW() WHERE id = $4`,
		role, passwordHash, percentage, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	BroadcastTemplateEvent(EventTemplateUpdated, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) DeleteUserTemplate(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := req["id"].(string)
	_, err := h.db.Exec(`UPDATE templates SET deleted_at = NOW() WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	BroadcastTemplateEvent(EventTemplateDeleted, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) CreateUserFromTemplate(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	templateId := req["template_id"].(string)
	userName := req["user_name"].(string)

	// Get template
	row := h.db.QueryRow(`SELECT role, password_hash, percentage FROM templates WHERE id = $1 AND deleted_at IS NULL`, templateId)
	var role, passwordHash string
	var percentage float64
	if err := row.Scan(&role, &passwordHash, &percentage); err != nil {
		respondError(w, 404, "Template not found")
		return
	}

	// Create user with generated ID
	userId := req["user_id"].(string)
	_, err := h.db.Exec(`
		INSERT INTO users (id, name, role, password_hash, percentage, is_template_user, created_at, updated_at, needs_sync)
		VALUES ($1, $2, $3, $4, $5, 1, NOW(), NOW(), 1)
	`, userId, userName, role, passwordHash, percentage)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	respondJSON(w, map[string]interface{}{
		"id":            userId,
		"username":      userName,
		"full_name":     userName,
		"role":          role,
		"password_hash": passwordHash,
		"percentage":    percentage,
	})
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
	row := h.db.QueryRow(`SELECT id, name FROM rooms WHERE id = $1`, id)

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
		VALUES ($1, $2, NOW(), NOW())
	`, req["id"], req["name"])

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	id, _ := result.LastInsertId()
	BroadcastRoomEvent(EventRoomCreated, map[string]interface{}{"id": req["id"]})
	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) UpdateRoom(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	_, err := h.db.Exec(`UPDATE rooms SET name = $1, updated_at = NOW() WHERE id = $2`, req["name"], req["id"])
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	BroadcastRoomEvent(EventRoomUpdated, map[string]interface{}{"id": req["id"]})
	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) DeleteRoom(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	_, err := h.db.Exec(`DELETE FROM rooms WHERE id = $1`, req["id"])
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	BroadcastRoomEvent(EventRoomDeleted, map[string]interface{}{"id": req["id"]})
	respondJSON(w, map[string]interface{}{})
}

// ==================== PATIENT HANDLERS ====================

func (h *RESTHandler) GetAllPatients(w http.ResponseWriter, r *http.Request) {
	// Order by created_at DESC so newest patients appear first, fallback to code DESC
	rows, err := h.db.Query(`
		SELECT code, barcode, first_name, last_name, age, date_of_birth, address, phone_number, other_info, created_at
		FROM patients ORDER BY COALESCE(created_at, '1970-01-01') DESC, code DESC
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
		if createdAt.Valid {
			patient["created_at"] = createdAt.String
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
		SELECT code, barcode, first_name, last_name, age, date_of_birth, address, phone_number, other_info
		FROM patients WHERE code = $1
	`, code)

	var patientCode int
	var barcode, firstName, lastName string
	var age sql.NullInt64
	var dateOfBirth, address, phone, otherInfo sql.NullString

	if err := row.Scan(&patientCode, &barcode, &firstName, &lastName, &age, &dateOfBirth, &address, &phone, &otherInfo); err != nil {
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
	if dateOfBirth.Valid {
		patient["date_of_birth"] = dateOfBirth.String
	}
	if address.Valid {
		patient["address"] = address.String
	}
	if phone.Valid {
		patient["phone"] = phone.String
	}
	if otherInfo.Valid {
		patient["notes"] = otherInfo.String
	}

	respondJSON(w, patient)
}

func (h *RESTHandler) SearchPatients(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	queryStr := strings.TrimSpace(req["query"].(string))
	queryLower := strings.ToLower(queryStr)

	var rows *sql.Rows
	var err error

	// Check if query is a number (code search)
	if _, parseErr := fmt.Sscanf(queryStr, "%d", new(int)); parseErr == nil {
		// Exact code match
		rows, err = h.db.Query(`
			SELECT code, barcode, first_name, last_name, age, date_of_birth, address, phone_number
			FROM patients WHERE code = $1
			ORDER BY code ASC
		`, queryStr)
	} else if strings.Contains(queryLower, " ") {
		// Space-separated: search both first AND last name (either order)
		parts := strings.SplitN(queryLower, " ", 2)
		part1 := "%" + parts[0] + "%"
		part2 := "%" + parts[1] + "%"
		rows, err = h.db.Query(`
			SELECT code, barcode, first_name, last_name, age, date_of_birth, address, phone_number
			FROM patients 
			WHERE (LOWER(first_name) LIKE $1 AND LOWER(last_name) LIKE $2)
			   OR (LOWER(first_name) LIKE $1 AND LOWER(last_name) LIKE $2)
			ORDER BY code ASC LIMIT 100
		`, part1, part2, part2, part1)
	} else {
		// Single word: search in first OR last name
		queryPattern := "%" + queryLower + "%"
		rows, err = h.db.Query(`
			SELECT code, barcode, first_name, last_name, age, date_of_birth, address, phone_number
			FROM patients 
			WHERE LOWER(first_name) LIKE $1 OR LOWER(last_name) LIKE $2
			ORDER BY code ASC LIMIT 100
		`, queryPattern, queryPattern)
	}

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
		var dateOfBirth, address, phone sql.NullString

		if err := rows.Scan(&code, &barcode, &firstName, &lastName, &age, &dateOfBirth, &address, &phone); err != nil {
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

func (h *RESTHandler) CreatePatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	// Auto-generate code if not provided or 0 - NEVER reuse codes even after deletion
	code := 0
	if c, ok := req["code"].(float64); ok && c > 0 {
		code = int(c)
	} else {
		// Create metadata table if not exists
		h.db.Exec(`CREATE TABLE IF NOT EXISTS app_metadata (key TEXT PRIMARY KEY, value INTEGER)`)

		// Get highest code ever used
		var highestEver int
		h.db.QueryRow(`SELECT COALESCE(value, 0) FROM app_metadata WHERE key = 'highest_patient_code'`).Scan(&highestEver)

		// Get current max in patients table
		var currentMax int
		h.db.QueryRow(`SELECT COALESCE(MAX(code), 0) FROM patients`).Scan(&currentMax)

		// Use the higher of the two + 1
		if highestEver > currentMax {
			code = highestEver + 1
		} else {
			code = currentMax + 1
		}

		// Save this as the new highest ever
		h.db.Exec(`INSERT INTO app_metadata (key, value_int) VALUES ('highest_patient_code', $1) ON CONFLICT (key) DO UPDATE SET value_int = $1`, code)
	}

	// Auto-generate barcode if not provided
	barcode := ""
	if b, ok := req["barcode"].(string); ok && b != "" {
		barcode = b
	} else {
		barcode = generateBarcode()
	}

	// Get optional fields
	var dateOfBirth interface{}
	if v, ok := req["date_of_birth"]; ok {
		dateOfBirth = v
	}

	_, err := h.db.Exec(`
		INSERT INTO patients (code, barcode, first_name, last_name, age, date_of_birth, address, phone_number, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW())
	`, code, barcode, req["first_name"], req["last_name"], req["age"], dateOfBirth, req["address"], req["phone"])

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	// Broadcast SSE event for real-time sync
	BroadcastPatientEvent(EventPatientCreated, code, map[string]interface{}{
		"first_name": req["first_name"],
		"last_name":  req["last_name"],
	})

	respondJSON(w, map[string]interface{}{"code": code, "id": code})
}

func (h *RESTHandler) UpdatePatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	code := int(req["code"].(float64))

	// Get optional fields
	var dateOfBirth interface{}
	if v, ok := req["date_of_birth"]; ok {
		dateOfBirth = v
	}

	_, err := h.db.Exec(`
		UPDATE patients SET first_name = $1, last_name = $2, age = $3, date_of_birth = $4, address = $5, phone_number = $6, updated_at = NOW()
		WHERE code = $1
	`, req["first_name"], req["last_name"], req["age"], dateOfBirth, req["address"], req["phone"], code)

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	// Broadcast SSE event for real-time sync
	BroadcastPatientEvent(EventPatientUpdated, code, nil)

	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) DeletePatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	code := int(req["patient_code"].(float64))

	// Delete ALL related data first (cascade delete)
	h.db.Exec(`DELETE FROM visits WHERE patient_code = $1`, code)
	h.db.Exec(`DELETE FROM payments WHERE patient_code = $1`, code)
	h.db.Exec(`DELETE FROM ordonnances WHERE patient_code = $1`, code)
	h.db.Exec(`DELETE FROM messages WHERE patient_code = $1`, code)
	h.db.Exec(`DELETE FROM waiting_patients WHERE patient_code = $1`, code)

	// Finally delete the patient
	_, err := h.db.Exec(`DELETE FROM patients WHERE code = $1`, code)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	log.Printf("✓ Patient %d and all related data deleted", code)

	// Broadcast SSE event for real-time sync
	BroadcastPatientEvent(EventPatientDeleted, code, nil)

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
		FROM messages WHERE room_id = $1 ORDER BY sent_at DESC
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
		VALUES ($1, $2, $3, $4, $5, $6, 0, NOW(), $7, $8)
	`, req["room_id"], req["sender_id"], req["sender_name"], req["sender_role"], req["content"], req["direction"], req["patient_code"], req["patient_name"])

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	id, _ := result.LastInsertId()

	// Broadcast SSE event for real-time sync - this is critical for instant notifications!
	roomID := ""
	if r, ok := req["room_id"].(string); ok {
		roomID = r
	}
	BroadcastMessageEvent(EventMessageCreated, roomID, map[string]interface{}{
		"id":          id,
		"sender_name": req["sender_name"],
		"direction":   req["direction"],
		"content":     req["content"],
	})

	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) DeleteMessage(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	_, err := h.db.Exec(`DELETE FROM messages WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) MarkMessageAsRead(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))

	// Get room_id before deleting for SSE broadcast
	var roomID string
	h.db.QueryRow(`SELECT room_id FROM messages WHERE id = $1`, id).Scan(&roomID)

	// Delete message when marked as read (no history kept - matches Flutter behavior)
	_, err := h.db.Exec(`DELETE FROM messages WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	// Broadcast SSE event for real-time sync
	BroadcastMessageEvent(EventMessageRead, roomID, map[string]interface{}{"id": id})

	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) MarkAllMessagesAsRead(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	roomId := req["room_id"].(string)
	direction := req["direction"].(string)

	// Delete all messages when marked as read (no history kept - matches Flutter behavior)
	_, err := h.db.Exec(`DELETE FROM messages WHERE room_id = $1 AND direction = $2`, roomId, direction)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	// Broadcast SSE event for real-time sync
	BroadcastMessageEvent(EventMessagesCleared, roomId, map[string]interface{}{"direction": direction})

	respondJSON(w, map[string]interface{}{})
}

// ==================== MESSAGE TEMPLATE HANDLERS ====================

func (h *RESTHandler) GetAllMessageTemplates(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(`SELECT id, content, display_order, created_at, created_by FROM message_templates ORDER BY display_order`)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	templates := []map[string]interface{}{}
	for rows.Next() {
		var id, displayOrder int
		var content, createdAt string
		var createdBy sql.NullString

		if err := rows.Scan(&id, &content, &displayOrder, &createdAt, &createdBy); err != nil {
			continue
		}

		t := map[string]interface{}{
			"id":            id,
			"content":       content,
			"display_order": displayOrder,
			"created_at":    createdAt,
		}
		if createdBy.Valid {
			t["created_by"] = createdBy.String
		}
		templates = append(templates, t)
	}

	respondJSON(w, map[string]interface{}{"templates": templates})
}

func (h *RESTHandler) CreateMessageTemplate(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	content := req["content"].(string)
	createdBy := ""
	if cb, ok := req["created_by"].(string); ok {
		createdBy = cb
	}

	// Get max display order
	var maxOrder int
	h.db.QueryRow(`SELECT COALESCE(MAX(display_order), 0) FROM message_templates`).Scan(&maxOrder)

	result, err := h.db.Exec(`
		INSERT INTO message_templates (content, display_order, created_at, created_by)
		VALUES ($1, $2, NOW(), $3)
	`, content, maxOrder+1, createdBy)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	id, _ := result.LastInsertId()
	BroadcastMsgTemplateEvent(EventMsgTemplateCreated, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) UpdateMessageTemplate(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	content := req["content"].(string)

	_, err := h.db.Exec(`UPDATE message_templates SET content = $1 WHERE id = $2`, content, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	BroadcastMsgTemplateEvent(EventMsgTemplateUpdated, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) GetMessageTemplateById(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	row := h.db.QueryRow(`SELECT id, content, display_order, created_at, created_by FROM message_templates WHERE id = $1`, id)

	var templateId, displayOrder int
	var content, createdAt string
	var createdBy sql.NullString
	if err := row.Scan(&templateId, &content, &displayOrder, &createdAt, &createdBy); err != nil {
		respondJSON(w, map[string]interface{}{})
		return
	}

	t := map[string]interface{}{
		"id":            templateId,
		"content":       content,
		"display_order": displayOrder,
		"created_at":    createdAt,
	}
	if createdBy.Valid {
		t["created_by"] = createdBy.String
	}
	respondJSON(w, t)
}

func (h *RESTHandler) DeleteMessageTemplate(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	_, err := h.db.Exec(`DELETE FROM message_templates WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	BroadcastMsgTemplateEvent(EventMsgTemplateDeleted, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) ReorderMessageTemplates(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	// Accept both "ordered_ids" (Flutter) and "ids" (legacy)
	var idsRaw []interface{}
	if ids, ok := req["ordered_ids"].([]interface{}); ok {
		idsRaw = ids
	} else if ids, ok := req["ids"].([]interface{}); ok {
		idsRaw = ids
	} else {
		respondError(w, 400, "missing ordered_ids or ids array")
		return
	}

	for i, idRaw := range idsRaw {
		id := int(idRaw.(float64))
		_, err := h.db.Exec(`UPDATE message_templates SET display_order = $1 WHERE id = $2`, i+1, id)
		if err != nil {
			respondError(w, 500, err.Error())
			return
		}
	}
	BroadcastMsgTemplateEvent(EventMsgTemplateReorder, nil)
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
			   dilatation_type, room_id, room_name, motif, sent_by_user_id, sent_by_user_name, sent_at, is_checked, is_active, is_notified
		FROM waiting_patients WHERE room_id = $1 AND is_active = 1 ORDER BY sent_at ASC
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
		var isUrgent, isDilatation, isChecked, isActive, isNotified bool

		if err := rows.Scan(&id, &patientCode, &patientFirstName, &patientLastName, &patientAge, &isUrgent, &isDilatation,
			&dilatationType, &roomId, &roomName, &motif, &sentByUserId, &sentByUserName, &sentAt, &isChecked, &isActive, &isNotified); err != nil {
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
			"is_notified":        isNotified,
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

func (h *RESTHandler) GetWaitingPatientById(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	row := h.db.QueryRow(`
		SELECT id, patient_code, patient_first_name, patient_last_name, patient_age, is_urgent, is_dilatation, 
			   dilatation_type, room_id, room_name, motif, sent_by_user_id, sent_by_user_name, sent_at, is_checked, is_active, is_notified
		FROM waiting_patients WHERE id = $1
	`, id)

	var patientId, patientCode int
	var patientFirstName, patientLastName, roomId, roomName, motif, sentByUserId, sentByUserName, sentAt string
	var patientAge sql.NullInt64
	var dilatationType sql.NullString
	var isUrgent, isDilatation, isChecked, isActive, isNotified bool

	if err := row.Scan(&patientId, &patientCode, &patientFirstName, &patientLastName, &patientAge, &isUrgent, &isDilatation,
		&dilatationType, &roomId, &roomName, &motif, &sentByUserId, &sentByUserName, &sentAt, &isChecked, &isActive, &isNotified); err != nil {
		respondJSON(w, map[string]interface{}{})
		return
	}

	patient := map[string]interface{}{
		"id":                 patientId,
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
		"is_notified":        isNotified,
	}
	if patientAge.Valid {
		patient["patient_age"] = patientAge.Int64
	}
	if dilatationType.Valid {
		patient["dilatation_type"] = dilatationType.String
	}

	respondJSON(w, patient)
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
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW(), 0, 1, 0)
	`, patientCode, req["patient_first_name"], req["patient_last_name"], req["patient_age"], req["is_urgent"], req["is_dilatation"],
		req["dilatation_type"], req["room_id"], req["room_name"], req["motif"], req["sent_by_user_id"], req["sent_by_user_name"])

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	id, _ := result.LastInsertId()

	// Broadcast SSE event for real-time sync - critical for nurse notifications!
	roomID := ""
	if r, ok := req["room_id"].(string); ok {
		roomID = r
	}
	isDilatation, _ := req["is_dilatation"].(bool)
	eventType := EventWaitingAdded
	if isDilatation {
		eventType = EventDilatationAdded
	}
	BroadcastWaitingEvent(eventType, roomID, map[string]interface{}{
		"id":                 id,
		"patient_code":       patientCode,
		"patient_first_name": req["patient_first_name"],
		"patient_last_name":  req["patient_last_name"],
		"is_urgent":          req["is_urgent"],
		"is_dilatation":      isDilatation,
		"motif":              req["motif"],
	})

	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) UpdateWaitingPatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))

	// Get room_id for SSE broadcast
	var roomID string
	h.db.QueryRow(`SELECT room_id FROM waiting_patients WHERE id = $1`, id).Scan(&roomID)

	// Check if this is a toggle request (is_checked sent without explicit value to set)
	// If is_checked is true from Flutter toggleChecked, we toggle the current value
	if isChecked, ok := req["is_checked"].(bool); ok && isChecked {
		// Toggle: set is_checked = NOT is_checked
		_, err := h.db.Exec(`UPDATE waiting_patients SET is_checked = NOT is_checked WHERE id = $1`, id)
		if err != nil {
			respondError(w, 500, err.Error())
			return
		}
	} else {
		// Direct update with provided values
		_, err := h.db.Exec(`
			UPDATE waiting_patients SET is_checked = $1, is_active = $2 WHERE id = $3
		`, req["is_checked"], req["is_active"], id)
		if err != nil {
			respondError(w, 500, err.Error())
			return
		}
	}

	// Broadcast SSE event for real-time sync
	BroadcastWaitingEvent(EventWaitingUpdated, roomID, map[string]interface{}{"id": id})

	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) RemoveWaitingPatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))

	// Get room_id for SSE broadcast
	var roomID string
	h.db.QueryRow(`SELECT room_id FROM waiting_patients WHERE id = $1`, id).Scan(&roomID)

	_, err := h.db.Exec(`UPDATE waiting_patients SET is_active = 0 WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	// Broadcast SSE event for real-time sync
	BroadcastWaitingEvent(EventWaitingRemoved, roomID, map[string]interface{}{"id": id})

	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) RemoveWaitingPatientByCode(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	patientCode := int(req["patient_code"].(float64))

	// Get room_id for SSE broadcast before removing
	var roomID string
	h.db.QueryRow(`SELECT room_id FROM waiting_patients WHERE patient_code = $1 AND is_active = 1`, patientCode).Scan(&roomID)

	_, err := h.db.Exec(`UPDATE waiting_patients SET is_active = 0 WHERE patient_code = $1 AND is_active = 1`, patientCode)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	// Broadcast SSE event for real-time sync
	BroadcastWaitingEvent(EventWaitingRemoved, roomID, map[string]interface{}{"patient_code": patientCode})

	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) MarkDilatationsAsNotified(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	roomIds := req["room_ids"].([]interface{})
	for _, roomId := range roomIds {
		_, err := h.db.Exec(`UPDATE waiting_patients SET is_notified = 1 WHERE room_id = $1 AND is_dilatation = 1 AND is_active = 1`, roomId.(string))
		if err != nil {
			respondError(w, 500, err.Error())
			return
		}
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
	row := h.db.QueryRow(`SELECT id, name, fee_amount, display_order FROM medical_acts WHERE id = $1`, id)

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

func (h *RESTHandler) CreateMedicalAct(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	name := req["name"].(string)
	feeAmount := int(req["fee_amount"].(float64))

	// Get max display order
	var maxOrder int
	h.db.QueryRow(`SELECT COALESCE(MAX(display_order), 0) FROM medical_acts`).Scan(&maxOrder)

	result, err := h.db.Exec(`
		INSERT INTO medical_acts (name, fee_amount, display_order, is_active, created_at, updated_at)
		VALUES ($1, $2, $3, 1, NOW(), NOW())
	`, name, feeAmount, maxOrder+1)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	id, _ := result.LastInsertId()
	BroadcastMedicalActEvent(EventMedicalActCreated, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) UpdateMedicalAct(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	name := req["name"].(string)
	feeAmount := int(req["fee_amount"].(float64))

	_, err := h.db.Exec(`UPDATE medical_acts SET name = $1, fee_amount = $2, updated_at = NOW() WHERE id = $3`,
		name, feeAmount, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	BroadcastMedicalActEvent(EventMedicalActUpdated, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) DeleteMedicalAct(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	_, err := h.db.Exec(`UPDATE medical_acts SET is_active = 0, updated_at = NOW() WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	BroadcastMedicalActEvent(EventMedicalActDeleted, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) ReorderMedicalActs(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	ids := req["ids"].([]interface{})
	for i, idVal := range ids {
		id := int(idVal.(float64))
		h.db.Exec(`UPDATE medical_acts SET display_order = $1, updated_at = NOW() WHERE id = $2`, i+1, id)
	}
	BroadcastMedicalActEvent(EventMedicalActReorder, nil)
	respondJSON(w, map[string]interface{}{})
}

// ==================== VISIT HANDLERS ====================

func (h *RESTHandler) GetVisitsForPatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	// Safe type conversion for patient_code
	patientCode := 0
	if pc, ok := req["patient_code"].(float64); ok {
		patientCode = int(pc)
	} else {
		respondError(w, 400, "patient_code is required")
		return
	}
	// Include old visits that might have NULL is_active (not explicitly deleted)
	rows, err := h.db.Query(`
		SELECT id, patient_code, visit_sequence, visit_date, doctor_name, motif, diagnosis, conduct,
			   od_sv, od_av, od_sphere, od_cylinder, od_axis, od_vl, od_k1, od_k2, od_r1, od_r2, od_r0, od_pachy, od_toc, od_notes, od_gonio, od_to, od_laf, od_fo,
			   og_sv, og_av, og_sphere, og_cylinder, og_axis, og_vl, og_k1, og_k2, og_r1, og_r2, og_r0, og_pachy, og_toc, og_notes, og_gonio, og_to, og_laf, og_fo,
			   addition, dip, created_at
		FROM visits WHERE patient_code = $1 AND (is_active = 1 OR is_active IS NULL) ORDER BY visit_date DESC
	`, patientCode)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	visits := []map[string]interface{}{}
	for rows.Next() {
		var id, patientCode, visitSequence int
		var visitDate, createdAt string
		var doctorName, motif, diagnosis, conduct sql.NullString
		var odSv, odAv, odSphere, odCylinder, odAxis, odVl, odK1, odK2, odR1, odR2, odR0, odPachy, odToc, odNotes, odGonio, odTo, odLaf, odFo sql.NullString
		var ogSv, ogAv, ogSphere, ogCylinder, ogAxis, ogVl, ogK1, ogK2, ogR1, ogR2, ogR0, ogPachy, ogToc, ogNotes, ogGonio, ogTo, ogLaf, ogFo sql.NullString
		var addition, dip sql.NullString

		if err := rows.Scan(&id, &patientCode, &visitSequence, &visitDate, &doctorName, &motif, &diagnosis, &conduct,
			&odSv, &odAv, &odSphere, &odCylinder, &odAxis, &odVl, &odK1, &odK2, &odR1, &odR2, &odR0, &odPachy, &odToc, &odNotes, &odGonio, &odTo, &odLaf, &odFo,
			&ogSv, &ogAv, &ogSphere, &ogCylinder, &ogAxis, &ogVl, &ogK1, &ogK2, &ogR1, &ogR2, &ogR0, &ogPachy, &ogToc, &ogNotes, &ogGonio, &ogTo, &ogLaf, &ogFo,
			&addition, &dip, &createdAt); err != nil {
			continue
		}

		visit := map[string]interface{}{
			"id":             id,
			"patient_code":   patientCode,
			"visit_sequence": visitSequence,
			"visit_date":     visitDate,
			"created_at":     createdAt,
		}
		// Helper to add nullable string
		addIfValid := func(key string, val sql.NullString) {
			if val.Valid {
				visit[key] = val.String
			}
		}
		addIfValid("doctor_name", doctorName)
		addIfValid("motif", motif)
		addIfValid("diagnosis", diagnosis)
		addIfValid("conduct", conduct)
		// OD fields
		addIfValid("od_sv", odSv)
		addIfValid("od_av", odAv)
		addIfValid("od_sphere", odSphere)
		addIfValid("od_cylinder", odCylinder)
		addIfValid("od_axis", odAxis)
		addIfValid("od_vl", odVl)
		addIfValid("od_k1", odK1)
		addIfValid("od_k2", odK2)
		addIfValid("od_r1", odR1)
		addIfValid("od_r2", odR2)
		addIfValid("od_r0", odR0)
		addIfValid("od_pachy", odPachy)
		addIfValid("od_toc", odToc)
		addIfValid("od_notes", odNotes)
		addIfValid("od_gonio", odGonio)
		addIfValid("od_to", odTo)
		addIfValid("od_laf", odLaf)
		addIfValid("od_fo", odFo)
		// OG fields
		addIfValid("og_sv", ogSv)
		addIfValid("og_av", ogAv)
		addIfValid("og_sphere", ogSphere)
		addIfValid("og_cylinder", ogCylinder)
		addIfValid("og_axis", ogAxis)
		addIfValid("og_vl", ogVl)
		addIfValid("og_k1", ogK1)
		addIfValid("og_k2", ogK2)
		addIfValid("og_r1", ogR1)
		addIfValid("og_r2", ogR2)
		addIfValid("og_r0", ogR0)
		addIfValid("og_pachy", ogPachy)
		addIfValid("og_toc", ogToc)
		addIfValid("og_notes", ogNotes)
		addIfValid("og_gonio", ogGonio)
		addIfValid("og_to", ogTo)
		addIfValid("og_laf", ogLaf)
		addIfValid("og_fo", ogFo)
		// Shared
		addIfValid("addition", addition)
		addIfValid("dip", dip)

		visits = append(visits, visit)
	}

	respondJSON(w, map[string]interface{}{"visits": visits})
}

func (h *RESTHandler) GetVisitById(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}
	id := int(req["id"].(float64))
	row := h.db.QueryRow(`
		SELECT id, patient_code, visit_sequence, visit_date, doctor_name, motif, diagnosis, conduct,
			   od_sv, od_av, od_sphere, od_cylinder, od_axis, od_vl, od_k1, od_k2, od_r1, od_r2, od_r0, od_pachy, od_toc, od_notes, od_gonio, od_to, od_laf, od_fo,
			   og_sv, og_av, og_sphere, og_cylinder, og_axis, og_vl, og_k1, og_k2, og_r1, og_r2, og_r0, og_pachy, og_toc, og_notes, og_gonio, og_to, og_laf, og_fo,
			   addition, dip, created_at
		FROM visits WHERE id = $1
	`, id)

	var visitId, patientCode, visitSequence int
	var visitDate, createdAt string
	var doctorName, motif, diagnosis, conduct sql.NullString
	var odSv, odAv, odSphere, odCylinder, odAxis, odVl, odK1, odK2, odR1, odR2, odR0, odPachy, odToc, odNotes, odGonio, odTo, odLaf, odFo sql.NullString
	var ogSv, ogAv, ogSphere, ogCylinder, ogAxis, ogVl, ogK1, ogK2, ogR1, ogR2, ogR0, ogPachy, ogToc, ogNotes, ogGonio, ogTo, ogLaf, ogFo sql.NullString
	var addition, dip sql.NullString

	if err := row.Scan(&visitId, &patientCode, &visitSequence, &visitDate, &doctorName, &motif, &diagnosis, &conduct,
		&odSv, &odAv, &odSphere, &odCylinder, &odAxis, &odVl, &odK1, &odK2, &odR1, &odR2, &odR0, &odPachy, &odToc, &odNotes, &odGonio, &odTo, &odLaf, &odFo,
		&ogSv, &ogAv, &ogSphere, &ogCylinder, &ogAxis, &ogVl, &ogK1, &ogK2, &ogR1, &ogR2, &ogR0, &ogPachy, &ogToc, &ogNotes, &ogGonio, &ogTo, &ogLaf, &ogFo,
		&addition, &dip, &createdAt); err != nil {
		respondJSON(w, map[string]interface{}{})
		return
	}

	visit := map[string]interface{}{
		"id":             visitId,
		"patient_code":   patientCode,
		"visit_sequence": visitSequence,
		"visit_date":     visitDate,
		"created_at":     createdAt,
	}
	// Helper to add nullable string
	addIfValid := func(key string, val sql.NullString) {
		if val.Valid {
			visit[key] = val.String
		}
	}
	addIfValid("doctor_name", doctorName)
	addIfValid("motif", motif)
	addIfValid("diagnosis", diagnosis)
	addIfValid("conduct", conduct)
	// OD fields
	addIfValid("od_sv", odSv)
	addIfValid("od_av", odAv)
	addIfValid("od_sphere", odSphere)
	addIfValid("od_cylinder", odCylinder)
	addIfValid("od_axis", odAxis)
	addIfValid("od_vl", odVl)
	addIfValid("od_k1", odK1)
	addIfValid("od_k2", odK2)
	addIfValid("od_r1", odR1)
	addIfValid("od_r2", odR2)
	addIfValid("od_r0", odR0)
	addIfValid("od_pachy", odPachy)
	addIfValid("od_toc", odToc)
	addIfValid("od_notes", odNotes)
	addIfValid("od_gonio", odGonio)
	addIfValid("od_to", odTo)
	addIfValid("od_laf", odLaf)
	addIfValid("od_fo", odFo)
	// OG fields
	addIfValid("og_sv", ogSv)
	addIfValid("og_av", ogAv)
	addIfValid("og_sphere", ogSphere)
	addIfValid("og_cylinder", ogCylinder)
	addIfValid("og_axis", ogAxis)
	addIfValid("og_vl", ogVl)
	addIfValid("og_k1", ogK1)
	addIfValid("og_k2", ogK2)
	addIfValid("og_r1", ogR1)
	addIfValid("og_r2", ogR2)
	addIfValid("og_r0", ogR0)
	addIfValid("og_pachy", ogPachy)
	addIfValid("og_toc", ogToc)
	addIfValid("og_notes", ogNotes)
	addIfValid("og_gonio", ogGonio)
	addIfValid("og_to", ogTo)
	addIfValid("og_laf", ogLaf)
	addIfValid("og_fo", ogFo)
	// Shared
	addIfValid("addition", addition)
	addIfValid("dip", dip)

	respondJSON(w, visit)
}

func (h *RESTHandler) CreateVisit(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}
	// Convert numeric values from float64 to int with nil checks
	patientCode := 0
	if pc, ok := req["patient_code"].(float64); ok {
		patientCode = int(pc)
	} else {
		respondError(w, 400, "patient_code is required")
		return
	}
	visitSequence := 1
	if vs, ok := req["visit_sequence"].(float64); ok {
		visitSequence = int(vs)
	}
	result, err := h.db.Exec(`
		INSERT INTO visits (
			patient_code, visit_sequence, visit_date, doctor_name, motif, diagnosis, conduct,
			od_sv, od_av, od_sphere, od_cylinder, od_axis, od_vl, od_k1, od_k2, od_r1, od_r2, od_r0, od_pachy, od_toc, od_notes, od_gonio, od_to, od_laf, od_fo,
			og_sv, og_av, og_sphere, og_cylinder, og_axis, og_vl, og_k1, og_k2, og_r1, og_r2, og_r0, og_pachy, og_toc, og_notes, og_gonio, og_to, og_laf, og_fo,
			addition, dip, created_at, updated_at, is_active
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43, $44, $45, NOW(), NOW(), 1)
	`, patientCode, visitSequence, req["visit_date"], req["doctor_name"], req["motif"], req["diagnosis"], req["conduct"],
		req["od_sv"], req["od_av"], req["od_sphere"], req["od_cylinder"], req["od_axis"], req["od_vl"], req["od_k1"], req["od_k2"], req["od_r1"], req["od_r2"], req["od_r0"], req["od_pachy"], req["od_toc"], req["od_notes"], req["od_gonio"], req["od_to"], req["od_laf"], req["od_fo"],
		req["og_sv"], req["og_av"], req["og_sphere"], req["og_cylinder"], req["og_axis"], req["og_vl"], req["og_k1"], req["og_k2"], req["og_r1"], req["og_r2"], req["og_r0"], req["og_pachy"], req["og_toc"], req["og_notes"], req["og_gonio"], req["og_to"], req["og_laf"], req["og_fo"],
		req["addition"], req["dip"])
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	id, _ := result.LastInsertId()
	BroadcastVisitEvent(EventVisitCreated, patientCode, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) UpdateVisit(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}
	id := int(req["id"].(float64))
	_, err := h.db.Exec(`
		UPDATE visits SET 
			doctor_name = $1, motif = $2, diagnosis = $3, conduct = $4,
			od_sv = $5, od_av = $6, od_sphere = $7, od_cylinder = $8, od_axis = $9, od_vl = $10, od_k1 = $11, od_k2 = $12, od_r1 = $13, od_r2 = $14, od_r0 = $15, od_pachy = $16, od_toc = $17, od_notes = $18, od_gonio = $19, od_to = $20, od_laf = $21, od_fo = $22,
			og_sv = $23, og_av = $24, og_sphere = $25, og_cylinder = $26, og_axis = $27, og_vl = $28, og_k1 = $29, og_k2 = $30, og_r1 = $31, og_r2 = $32, og_r0 = $33, og_pachy = $34, og_toc = $35, og_notes = $36, og_gonio = $37, og_to = $38, og_laf = $39, og_fo = $40,
			addition = $41, dip = $42, updated_at = NOW()
		WHERE id = $43`,
		req["doctor_name"], req["motif"], req["diagnosis"], req["conduct"],
		req["od_sv"], req["od_av"], req["od_sphere"], req["od_cylinder"], req["od_axis"], req["od_vl"], req["od_k1"], req["od_k2"], req["od_r1"], req["od_r2"], req["od_r0"], req["od_pachy"], req["od_toc"], req["od_notes"], req["od_gonio"], req["od_to"], req["od_laf"], req["od_fo"],
		req["og_sv"], req["og_av"], req["og_sphere"], req["og_cylinder"], req["og_axis"], req["og_vl"], req["og_k1"], req["og_k2"], req["og_r1"], req["og_r2"], req["og_r0"], req["og_pachy"], req["og_toc"], req["og_notes"], req["og_gonio"], req["og_to"], req["og_laf"], req["og_fo"],
		req["addition"], req["dip"], id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	patientCode := 0
	if pc, ok := req["patient_code"].(float64); ok {
		patientCode = int(pc)
	}
	BroadcastVisitEvent(EventVisitUpdated, patientCode, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) DeleteVisit(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}
	id := int(req["id"].(float64))
	_, err := h.db.Exec(`UPDATE visits SET is_active = 0, updated_at = NOW() WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	patientCode := 0
	if pc, ok := req["patient_code"].(float64); ok {
		patientCode = int(pc)
	}
	BroadcastVisitEvent(EventVisitDeleted, patientCode, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{})
}

// ==================== ORDONNANCE HANDLERS ====================

func (h *RESTHandler) GetOrdonnancesForPatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	patientCode := int(req["patient_code"].(float64))
	rows, err := h.db.Query(`
		SELECT id, patient_code, sequence, document_date, doctor_name, report_title, referred_by,
			   type1, content1, type2, content2, type3, content3
		FROM ordonnances WHERE patient_code = $1 ORDER BY document_date DESC, id DESC
	`, patientCode)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	ordonnances := []map[string]interface{}{}
	for rows.Next() {
		var id, patientCode, sequence int
		var documentDate, doctorName, reportTitle, referredBy sql.NullString
		var type1, content1, type2, content2, type3, content3 sql.NullString

		if err := rows.Scan(&id, &patientCode, &sequence, &documentDate, &doctorName, &reportTitle, &referredBy,
			&type1, &content1, &type2, &content2, &type3, &content3); err != nil {
			continue
		}

		ord := map[string]interface{}{
			"id":           id,
			"patient_code": patientCode,
			"sequence":     sequence,
		}
		if documentDate.Valid {
			ord["document_date"] = documentDate.String
		}
		if doctorName.Valid {
			ord["doctor_name"] = doctorName.String
		}
		if reportTitle.Valid {
			ord["report_title"] = reportTitle.String
		}
		if referredBy.Valid {
			ord["referred_by"] = referredBy.String
		}
		if type1.Valid {
			ord["type1"] = type1.String
		}
		if content1.Valid {
			ord["content1"] = content1.String
		}
		if type2.Valid {
			ord["type2"] = type2.String
		}
		if content2.Valid {
			ord["content2"] = content2.String
		}
		if type3.Valid {
			ord["type3"] = type3.String
		}
		if content3.Valid {
			ord["content3"] = content3.String
		}

		ordonnances = append(ordonnances, ord)
	}

	respondJSON(w, map[string]interface{}{"ordonnances": ordonnances})
}

func (h *RESTHandler) CreateOrdonnance(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}
	result, err := h.db.Exec(`
		INSERT INTO ordonnances (patient_code, sequence, document_date, doctor_name, report_title, type1, content1)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`, req["patient_code"], req["sequence"], req["document_date"], req["doctor_name"], req["report_title"], req["type1"], req["content1"])
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	id, _ := result.LastInsertId()
	patientCode := 0
	if pc, ok := req["patient_code"].(float64); ok {
		patientCode = int(pc)
	}
	BroadcastOrdonnanceEvent(EventOrdonnanceCreated, patientCode, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) UpdateOrdonnance(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}
	id := int(req["id"].(float64))
	_, err := h.db.Exec(`UPDATE ordonnances SET content1 = $1, type1 = $2 WHERE id = $3`, req["content1"], req["type1"], id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	patientCode := 0
	if pc, ok := req["patient_code"].(float64); ok {
		patientCode = int(pc)
	}
	BroadcastOrdonnanceEvent(EventOrdonnanceUpdated, patientCode, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) DeleteOrdonnance(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}
	id := int(req["id"].(float64))
	_, err := h.db.Exec(`DELETE FROM ordonnances WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	patientCode := 0
	if pc, ok := req["patient_code"].(float64); ok {
		patientCode = int(pc)
	}
	BroadcastOrdonnanceEvent(EventOrdonnanceDeleted, patientCode, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{})
}

// ==================== PAYMENT HANDLERS ====================

func (h *RESTHandler) GetPaymentsForPatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	patientCode := int(req["patient_code"].(float64))
	// Include old payments that might have NULL is_active (not explicitly deleted)
	rows, err := h.db.Query(`
		SELECT id, medical_act_id, medical_act_name, amount, user_id, user_name,
			   patient_code, patient_first_name, patient_last_name, payment_time, COALESCE(is_active, 1) as is_active
		FROM payments WHERE patient_code = $1 AND (is_active = 1 OR is_active IS NULL) ORDER BY payment_time DESC
	`, patientCode)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	payments := []map[string]interface{}{}
	for rows.Next() {
		var id, medicalActId, amount, pCode int
		var medicalActName, userId, userName, patientFirstName, patientLastName string
		var paymentTime sql.NullString
		var isActive bool

		if err := rows.Scan(&id, &medicalActId, &medicalActName, &amount, &userId, &userName,
			&pCode, &patientFirstName, &patientLastName, &paymentTime, &isActive); err != nil {
			continue
		}

		payments = append(payments, map[string]interface{}{
			"id":                 id,
			"medical_act_id":     medicalActId,
			"medical_act_name":   medicalActName,
			"amount":             amount,
			"user_id":            userId,
			"user_name":          userName,
			"patient_code":       pCode,
			"patient_first_name": patientFirstName,
			"patient_last_name":  patientLastName,
			"payment_time":       paymentTime.String,
			"is_active":          isActive,
		})
	}

	respondJSON(w, map[string]interface{}{"payments": payments})
}

func (h *RESTHandler) GetPaymentsForVisit(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	// Note: visit_id is not in the new schema, so this returns empty for now
	// Future: could be reimplemented to use patient_code + date matching
	_ = int(req["visit_id"].(float64))

	// Return empty array since visit_id is not tracked in new schema
	respondJSON(w, map[string]interface{}{"payments": []map[string]interface{}{}})
}

func (h *RESTHandler) GetPaymentsByUserAndDate(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	userName := req["user_name"].(string)
	dateStr := req["date"].(string) // Format: YYYY-MM-DD

	// Include old payments that might have NULL is_active (not explicitly deleted)
	// Handle both ISO string dates AND Unix timestamps (milliseconds) for backward compatibility
	rows, err := h.db.Query(`
		SELECT id, medical_act_id, medical_act_name, amount, user_id, user_name,
			   patient_code, patient_first_name, patient_last_name, payment_time, COALESCE(is_active, 1) as is_active
		FROM payments 
		WHERE user_name = $1 
		  AND (is_active = 1 OR is_active IS NULL)
		  AND (
		    date(payment_time) = $1
		    OR date(payment_time / 1000, 'unixepoch', 'localtime') = $1
		  )
		ORDER BY payment_time ASC
	`, userName, dateStr, dateStr)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	payments := []map[string]interface{}{}
	for rows.Next() {
		var id, medicalActId, amount, patientCode int
		var medicalActName, userId, userName, patientFirstName, patientLastName string
		var paymentTime sql.NullString
		var isActive bool

		if err := rows.Scan(&id, &medicalActId, &medicalActName, &amount, &userId, &userName,
			&patientCode, &patientFirstName, &patientLastName, &paymentTime, &isActive); err != nil {
			continue
		}

		payments = append(payments, map[string]interface{}{
			"id":                 id,
			"medical_act_id":     medicalActId,
			"medical_act_name":   medicalActName,
			"amount":             amount,
			"user_id":            userId,
			"user_name":          userName,
			"patient_code":       patientCode,
			"patient_first_name": patientFirstName,
			"patient_last_name":  patientLastName,
			"payment_time":       paymentTime.String,
			"is_active":          isActive,
		})
	}

	respondJSON(w, map[string]interface{}{"payments": payments})
}

func (h *RESTHandler) CreatePayment(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	// Get values with defaults
	medicalActId := 0
	if v, ok := req["medical_act_id"].(float64); ok {
		medicalActId = int(v)
	}
	medicalActName := ""
	if v, ok := req["medical_act_name"].(string); ok {
		medicalActName = v
	} else if v, ok := req["notes"].(string); ok {
		medicalActName = v // fallback to notes
	}
	amount := 0
	if v, ok := req["amount"].(float64); ok {
		amount = int(v)
	}
	userId := ""
	if v, ok := req["user_id"].(string); ok {
		userId = v
	}
	userName := ""
	if v, ok := req["user_name"].(string); ok {
		userName = v
	}
	patientCode := 0
	if v, ok := req["patient_code"].(float64); ok {
		patientCode = int(v)
	}
	patientFirstName := ""
	if v, ok := req["patient_first_name"].(string); ok {
		patientFirstName = v
	}
	patientLastName := ""
	if v, ok := req["patient_last_name"].(string); ok {
		patientLastName = v
	}
	paymentTime := time.Now().Format("2006-01-02 15:04:05")
	if v, ok := req["payment_time"].(string); ok && v != "" {
		paymentTime = v
	} else if v, ok := req["payment_date"].(string); ok && v != "" {
		paymentTime = v
	}

	result, err := h.db.Exec(`
		INSERT INTO payments (medical_act_id, medical_act_name, amount, user_id, user_name, patient_code, patient_first_name, patient_last_name, payment_time, created_at, updated_at, needs_sync, is_active)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW(), 1, 1)
	`, medicalActId, medicalActName, amount, userId, userName, patientCode, patientFirstName, patientLastName, paymentTime)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	id, _ := result.LastInsertId()

	// Broadcast SSE event for real-time sync
	BroadcastPaymentEvent(EventPaymentCreated, map[string]interface{}{
		"id":           id,
		"patient_code": patientCode,
		"amount":       amount,
		"user_name":    userName,
	})

	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) UpdatePayment(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := 0
	if v, ok := req["id"].(float64); ok {
		id = int(v)
	}
	medicalActId := 0
	if v, ok := req["medical_act_id"].(float64); ok {
		medicalActId = int(v)
	}
	medicalActName := ""
	if v, ok := req["medical_act_name"].(string); ok {
		medicalActName = v
	}
	amount := 0
	if v, ok := req["amount"].(float64); ok {
		amount = int(v)
	}
	patientCode := 0
	if v, ok := req["patient_code"].(float64); ok {
		patientCode = int(v)
	}
	patientFirstName := ""
	if v, ok := req["patient_first_name"].(string); ok {
		patientFirstName = v
	}
	patientLastName := ""
	if v, ok := req["patient_last_name"].(string); ok {
		patientLastName = v
	}
	paymentTime := ""
	if v, ok := req["payment_time"].(string); ok {
		paymentTime = v
	}

	_, err := h.db.Exec(`UPDATE payments SET medical_act_id = $1, medical_act_name = $2, amount = $3, patient_code = $4, patient_first_name = $5, patient_last_name = $6, payment_time = $7, updated_at = NOW() WHERE id = $8`,
		medicalActId, medicalActName, amount, patientCode, patientFirstName, patientLastName, paymentTime, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	// Broadcast SSE event for real-time sync
	BroadcastPaymentEvent(EventPaymentUpdated, map[string]interface{}{"id": id, "patient_code": patientCode})

	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) DeletePayment(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}
	id := int(req["id"].(float64))
	// Soft delete to preserve accounting integrity
	_, err := h.db.Exec(`UPDATE payments SET is_active = 0, updated_at = NOW() WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	// Broadcast SSE event for real-time sync
	BroadcastPaymentEvent(EventPaymentDeleted, map[string]interface{}{"id": id})

	respondJSON(w, map[string]interface{}{})
}

// ==================== MEDICATION HANDLERS ====================

func (h *RESTHandler) GetAllMedications(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(`SELECT id, original_id, code, prescription, usage_count, nature FROM medications ORDER BY usage_count DESC`)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	medications := []map[string]interface{}{}
	for rows.Next() {
		var id int
		var originalId sql.NullInt64
		var code, prescription string
		var usageCount int
		var nature sql.NullString
		if err := rows.Scan(&id, &originalId, &code, &prescription, &usageCount, &nature); err != nil {
			continue
		}
		med := map[string]interface{}{
			"id":           id,
			"name":         code,
			"code":         code,
			"prescription": prescription,
			"usage_count":  usageCount,
		}
		if originalId.Valid {
			med["original_id"] = originalId.Int64
		}
		if nature.Valid {
			med["nature"] = nature.String
		}
		medications = append(medications, med)
	}
	respondJSON(w, map[string]interface{}{"medications": medications})
}

func (h *RESTHandler) SearchMedications(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	query := "%" + req["query"].(string) + "%"
	rows, err := h.db.Query(`SELECT id, original_id, code, prescription, usage_count, nature FROM medications WHERE code LIKE $1 ORDER BY usage_count DESC LIMIT 50`, query)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	medications := []map[string]interface{}{}
	for rows.Next() {
		var id int
		var originalId sql.NullInt64
		var code, prescription string
		var usageCount int
		var nature sql.NullString
		if err := rows.Scan(&id, &originalId, &code, &prescription, &usageCount, &nature); err != nil {
			continue
		}
		med := map[string]interface{}{
			"id":           id,
			"name":         code,
			"code":         code,
			"prescription": prescription,
			"usage_count":  usageCount,
		}
		if originalId.Valid {
			med["original_id"] = originalId.Int64
		}
		if nature.Valid {
			med["nature"] = nature.String
		}
		medications = append(medications, med)
	}
	respondJSON(w, map[string]interface{}{"medications": medications})
}

// ==================== ADDITIONAL PAYMENT HANDLERS ====================

func (h *RESTHandler) GetPaymentById(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	row := h.db.QueryRow(`SELECT id, medical_act_id, medical_act_name, amount, user_id, user_name, patient_code, patient_first_name, patient_last_name, payment_time FROM payments WHERE id = $1 AND is_active = 1`, id)

	var paymentId, medicalActId, amount, patientCode int
	var medicalActName, userId, userName, patientFirstName, patientLastName, paymentTime string

	if err := row.Scan(&paymentId, &medicalActId, &medicalActName, &amount, &userId, &userName, &patientCode, &patientFirstName, &patientLastName, &paymentTime); err != nil {
		respondJSON(w, map[string]interface{}{})
		return
	}

	respondJSON(w, map[string]interface{}{
		"id":                 paymentId,
		"medical_act_id":     medicalActId,
		"medical_act_name":   medicalActName,
		"amount":             amount,
		"user_id":            userId,
		"user_name":          userName,
		"patient_code":       patientCode,
		"patient_first_name": patientFirstName,
		"patient_last_name":  patientLastName,
		"payment_time":       paymentTime,
	})
}

func (h *RESTHandler) GetAllPaymentsByUser(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	userName := req["user_name"].(string)
	// Include old payments that might have NULL or missing is_active (not explicitly deleted)
	rows, err := h.db.Query(`SELECT id, medical_act_id, medical_act_name, amount, patient_code, patient_first_name, patient_last_name, payment_time FROM payments WHERE user_name = $1 AND (is_active = 1 OR is_active IS NULL) ORDER BY payment_time DESC`, userName)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	payments := []map[string]interface{}{}
	for rows.Next() {
		var id, medicalActId, amount, patientCode int
		var medicalActName, patientFirstName, patientLastName, paymentTime string
		if err := rows.Scan(&id, &medicalActId, &medicalActName, &amount, &patientCode, &patientFirstName, &patientLastName, &paymentTime); err != nil {
			continue
		}
		payments = append(payments, map[string]interface{}{
			"id":                 id,
			"medical_act_id":     medicalActId,
			"medical_act_name":   medicalActName,
			"amount":             amount,
			"patient_code":       patientCode,
			"patient_first_name": patientFirstName,
			"patient_last_name":  patientLastName,
			"payment_time":       paymentTime,
		})
	}
	respondJSON(w, map[string]interface{}{"payments": payments})
}

func (h *RESTHandler) DeletePaymentsByPatientAndDate(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	patientCode := int(req["patient_code"].(float64))
	dateStr := req["date"].(string)

	result, err := h.db.Exec(`UPDATE payments SET is_active = 0, updated_at = NOW() WHERE patient_code = $1 AND (date(payment_time) = $2 OR date(payment_time / 1000, 'unixepoch', 'localtime') = $3)`, patientCode, dateStr, dateStr)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	count, _ := result.RowsAffected()
	respondJSON(w, map[string]interface{}{"deleted": count})
}

func (h *RESTHandler) CountPaymentsByPatientAndDate(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	patientCode := int(req["patient_code"].(float64))
	dateStr := req["date"].(string)

	var count int
	h.db.QueryRow(`SELECT COUNT(*) FROM payments WHERE patient_code = $1 AND (date(payment_time) = $2 OR date(payment_time / 1000, 'unixepoch', 'localtime') = $3) AND is_active = 1`, patientCode, dateStr, dateStr).Scan(&count)
	respondJSON(w, map[string]interface{}{"count": count})
}

func (h *RESTHandler) GetMaxPaymentId(w http.ResponseWriter, r *http.Request) {
	var maxId int
	h.db.QueryRow(`SELECT COALESCE(MAX(id), 0) FROM payments`).Scan(&maxId)
	respondJSON(w, map[string]interface{}{"max_id": maxId})
}

// ==================== ADDITIONAL MEDICATION HANDLERS ====================

func (h *RESTHandler) GetMedicationById(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	row := h.db.QueryRow(`SELECT id, original_id, code, prescription, usage_count, nature FROM medications WHERE id = $1`, id)

	var medId int
	var originalId sql.NullInt64
	var code, prescription string
	var usageCount int
	var nature sql.NullString

	if err := row.Scan(&medId, &originalId, &code, &prescription, &usageCount, &nature); err != nil {
		respondJSON(w, map[string]interface{}{})
		return
	}

	med := map[string]interface{}{
		"id":           medId,
		"code":         code,
		"name":         code,
		"prescription": prescription,
		"usage_count":  usageCount,
	}
	if originalId.Valid {
		med["original_id"] = originalId.Int64
	}
	if nature.Valid {
		med["nature"] = nature.String
	}
	respondJSON(w, med)
}

func (h *RESTHandler) GetMedicationCount(w http.ResponseWriter, r *http.Request) {
	var count int
	h.db.QueryRow(`SELECT COUNT(*) FROM medications`).Scan(&count)
	respondJSON(w, map[string]interface{}{"count": count})
}

func (h *RESTHandler) IncrementMedicationUsage(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	_, err := h.db.Exec(`UPDATE medications SET usage_count = usage_count + 1, updated_at = NOW() WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	BroadcastMedicationEvent(EventMedicationUpdated, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) SetMedicationUsageCount(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	count := int(req["count"].(float64))
	_, err := h.db.Exec(`UPDATE medications SET usage_count = $1, updated_at = NOW() WHERE id = $2`, count, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	BroadcastMedicationEvent(EventMedicationUpdated, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) AddMedication(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	code := req["code"].(string)
	prescription := ""
	if p, ok := req["prescription"].(string); ok {
		prescription = p
	}

	result, err := h.db.Exec(`INSERT INTO medications (code, prescription, usage_count, nature, created_at, updated_at) VALUES ($1, $2, 0, 'O', NOW(), NOW())`, code, prescription)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	id, _ := result.LastInsertId()
	BroadcastMedicationEvent(EventMedicationCreated, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) UpdateMedication(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	code := req["code"].(string)
	prescription := ""
	if p, ok := req["prescription"].(string); ok {
		prescription = p
	}

	_, err := h.db.Exec(`UPDATE medications SET code = $1, prescription = $2, updated_at = NOW() WHERE id = $3`, code, prescription, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	BroadcastMedicationEvent(EventMedicationUpdated, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{"success": true})
}

func (h *RESTHandler) DeleteMedication(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	_, err := h.db.Exec(`DELETE FROM medications WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	BroadcastMedicationEvent(EventMedicationDeleted, map[string]interface{}{"id": id})
	respondJSON(w, map[string]interface{}{"success": true})
}

// ==================== ADDITIONAL VISIT HANDLERS ====================

func (h *RESTHandler) GetTotalVisitCount(w http.ResponseWriter, r *http.Request) {
	var count int
	h.db.QueryRow(`SELECT COUNT(*) FROM visits WHERE is_active = 1`).Scan(&count)
	respondJSON(w, map[string]interface{}{"count": count})
}

func (h *RESTHandler) ClearAllVisits(w http.ResponseWriter, r *http.Request) {
	result, err := h.db.Exec(`DELETE FROM visits`)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	count, _ := result.RowsAffected()
	respondJSON(w, map[string]interface{}{"deleted": count})
}

func (h *RESTHandler) InsertVisits(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	visits := req["visits"].([]interface{})
	insertedCount := 0

	for _, v := range visits {
		visit := v.(map[string]interface{})

		// Helper to get int with default
		getInt := func(key string) interface{} {
			if val, ok := visit[key]; ok && val != nil {
				if f, ok := val.(float64); ok {
					return int(f)
				}
			}
			return nil
		}

		_, err := h.db.Exec(`
			INSERT INTO visits (
				patient_code, visit_sequence, visit_date, doctor_name, motif, diagnosis, conduct,
				od_sv, od_av, od_sphere, od_cylinder, od_axis, od_vl, od_k1, od_k2, od_r1, od_r2, od_r0, od_pachy, od_toc, od_notes, od_gonio, od_to, od_laf, od_fo,
				og_sv, og_av, og_sphere, og_cylinder, og_axis, og_vl, og_k1, og_k2, og_r1, og_r2, og_r0, og_pachy, og_toc, og_notes, og_gonio, og_to, og_laf, og_fo,
				addition, dip, is_active, created_at, updated_at, needs_sync
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43, $44, $45, 1, NOW(), NOW(), 1)
		`,
			getInt("patient_code"), getInt("visit_sequence"), visit["visit_date"], visit["doctor_name"], visit["motif"], visit["diagnosis"], visit["conduct"],
			visit["od_sv"], visit["od_av"], visit["od_sphere"], visit["od_cylinder"], visit["od_axis"], visit["od_vl"], visit["od_k1"], visit["od_k2"], visit["od_r1"], visit["od_r2"], visit["od_r0"], visit["od_pachy"], visit["od_toc"], visit["od_notes"], visit["od_gonio"], visit["od_to"], visit["od_laf"], visit["od_fo"],
			visit["og_sv"], visit["og_av"], visit["og_sphere"], visit["og_cylinder"], visit["og_axis"], visit["og_vl"], visit["og_k1"], visit["og_k2"], visit["og_r1"], visit["og_r2"], visit["og_r0"], visit["og_pachy"], visit["og_toc"], visit["og_notes"], visit["og_gonio"], visit["og_to"], visit["og_laf"], visit["og_fo"],
			visit["addition"], visit["dip"],
		)
		if err == nil {
			insertedCount++
		}
	}

	respondJSON(w, map[string]interface{}{"inserted": insertedCount})
}

// ==================== ADDITIONAL MESSAGE HANDLERS ====================

func (h *RESTHandler) GetMessageById(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	row := h.db.QueryRow(`SELECT id, room_id, sender_id, sender_name, sender_role, content, direction, is_read, sent_at, patient_code, patient_name FROM messages WHERE id = $1`, id)

	var msgId int
	var roomId, senderId, senderName, senderRole, content, direction, sentAt string
	var isRead bool
	var patientCode sql.NullInt64
	var patientName sql.NullString

	if err := row.Scan(&msgId, &roomId, &senderId, &senderName, &senderRole, &content, &direction, &isRead, &sentAt, &patientCode, &patientName); err != nil {
		respondJSON(w, map[string]interface{}{})
		return
	}

	msg := map[string]interface{}{
		"id":          msgId,
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
	respondJSON(w, msg)
}

// ==================== ADDITIONAL PATIENT HANDLERS ====================

func (h *RESTHandler) ImportPatient(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	code := int(req["code"].(float64))
	firstName := req["first_name"].(string)
	lastName := req["last_name"].(string)

	var age interface{}
	var dateOfBirth, address, phone, otherInfo interface{}

	if v, ok := req["age"]; ok && v != nil {
		age = int(v.(float64))
	}
	if v, ok := req["date_of_birth"]; ok {
		dateOfBirth = v
	}
	if v, ok := req["address"]; ok {
		address = v
	}
	if v, ok := req["phone"]; ok {
		phone = v
	}
	if v, ok := req["other_info"]; ok {
		otherInfo = v
	}

	_, err := h.db.Exec(`
		INSERT INTO patients (code, barcode, first_name, last_name, age, date_of_birth, address, phone_number, other_info, created_at, updated_at, needs_sync)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW(), 1)
		ON CONFLICT(code) DO UPDATE SET
			first_name = excluded.first_name,
			last_name = excluded.last_name,
			age = excluded.age,
			date_of_birth = excluded.date_of_birth,
			address = excluded.address,
			phone_number = excluded.phone_number,
			other_info = excluded.other_info,
			updated_at = NOW()
	`, code, "", firstName, lastName, age, dateOfBirth, address, phone, otherInfo)

	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	respondJSON(w, map[string]interface{}{"code": code})
}

// ==================== NURSE PREFERENCES HANDLERS ====================
// Note: These store preferences in a nurse_preferences table
// The table structure: nurse_id TEXT, box_index INT, room_id TEXT, PRIMARY KEY(nurse_id, box_index)

func (h *RESTHandler) GetNurseRoomPreferences(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	nurseId := req["nurse_id"].(string)

	// Ensure table exists
	h.db.Exec(`CREATE TABLE IF NOT EXISTS nurse_preferences (nurse_id TEXT, box_index INTEGER, room_id TEXT, PRIMARY KEY(nurse_id, box_index))`)

	rows, err := h.db.Query(`SELECT box_index, room_id FROM nurse_preferences WHERE nurse_id = $1 ORDER BY box_index`, nurseId)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	rooms := []interface{}{nil, nil, nil}
	for rows.Next() {
		var boxIndex int
		var roomId string
		if err := rows.Scan(&boxIndex, &roomId); err == nil && boxIndex >= 0 && boxIndex < 3 {
			rooms[boxIndex] = roomId
		}
	}

	respondJSON(w, map[string]interface{}{"rooms": rooms})
}

func (h *RESTHandler) SaveNurseRoomPreferences(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	nurseId := req["nurse_id"].(string)
	rooms := req["rooms"].([]interface{})

	// Ensure table exists
	h.db.Exec(`CREATE TABLE IF NOT EXISTS nurse_preferences (nurse_id TEXT, box_index INTEGER, room_id TEXT, PRIMARY KEY(nurse_id, box_index))`)

	// Clear existing and insert new
	h.db.Exec(`DELETE FROM nurse_preferences WHERE nurse_id = $1`, nurseId)

	for i, room := range rooms {
		if room != nil {
			h.db.Exec(`INSERT INTO nurse_preferences (nurse_id, box_index, room_id) VALUES ($1, $2, $3)`, nurseId, i, room.(string))
		}
	}
	BroadcastNursePrefsEvent(EventNursePrefsUpdated, map[string]interface{}{"nurse_id": nurseId})
	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) ClearNurseRoomPreferences(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	nurseId := req["nurse_id"].(string)
	h.db.Exec(`DELETE FROM nurse_preferences WHERE nurse_id = $1`, nurseId)
	BroadcastNursePrefsEvent(EventNursePrefsUpdated, map[string]interface{}{"nurse_id": nurseId})
	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) GetActiveNurses(w http.ResponseWriter, r *http.Request) {
	// Ensure table exists
	h.db.Exec(`CREATE TABLE IF NOT EXISTS active_nurses (nurse_id TEXT PRIMARY KEY, active_since TEXT)`)

	rows, err := h.db.Query(`SELECT nurse_id FROM active_nurses`)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	nurses := []string{}
	for rows.Next() {
		var nurseId string
		if err := rows.Scan(&nurseId); err == nil {
			nurses = append(nurses, nurseId)
		}
	}

	respondJSON(w, map[string]interface{}{"nurses": nurses})
}

func (h *RESTHandler) MarkNurseActive(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	nurseId := req["nurse_id"].(string)

	// Ensure table exists
	// Note: active_nurses table should be in schema, not created here
	h.db.Exec(`INSERT INTO nurse_preferences (user_id, is_active, updated_at) VALUES ($1, TRUE, NOW()) ON CONFLICT (user_id) DO UPDATE SET is_active = TRUE, updated_at = NOW()`, nurseId)
	BroadcastNursePrefsEvent(EventNurseActive, map[string]interface{}{"nurse_id": nurseId})
	respondJSON(w, map[string]interface{}{})
}

func (h *RESTHandler) MarkNurseInactive(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	nurseId := req["nurse_id"].(string)
	h.db.Exec(`DELETE FROM active_nurses WHERE nurse_id = $1`, nurseId)
	BroadcastNursePrefsEvent(EventNurseInactive, map[string]interface{}{"nurse_id": nurseId})
	respondJSON(w, map[string]interface{}{})
}

// ==================== TEMPLATES CR HANDLERS ====================

func (h *RESTHandler) GetAllTemplatesCR(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(`SELECT id, code, content, usage_count FROM templates_cr ORDER BY usage_count DESC`)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	templates := []map[string]interface{}{}
	for rows.Next() {
		var id, usageCount int
		var code, content string
		if err := rows.Scan(&id, &code, &content, &usageCount); err != nil {
			continue
		}
		templates = append(templates, map[string]interface{}{
			"id":          id,
			"code":        code,
			"content":     content,
			"usage_count": usageCount,
		})
	}
	respondJSON(w, map[string]interface{}{"templates": templates})
}

func (h *RESTHandler) IncrementTemplateCRUsage(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	_, err := h.db.Exec(`UPDATE templates_cr SET usage_count = usage_count + 1 WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	respondJSON(w, map[string]interface{}{})
}

// ==================== APPOINTMENT HANDLERS ====================

func (h *RESTHandler) GetAppointmentsForDate(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	dateStr := req["date"].(string)
	date, _ := time.Parse(time.RFC3339, dateStr)
	startOfDay := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.Local)
	endOfDay := time.Date(date.Year(), date.Month(), date.Day(), 23, 59, 59, 0, time.Local)

	rows, err := h.db.Query(`
		SELECT id, appointment_date, first_name, last_name, age, date_of_birth, 
		       phone_number, address, notes, existing_patient_code, was_added, created_at, created_by
		FROM appointments 
		WHERE appointment_date BETWEEN $1 AND $2
		ORDER BY last_name
	`, startOfDay, endOfDay)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	appointments := []map[string]interface{}{}
	for rows.Next() {
		var id int
		var appointmentDate time.Time
		var firstName, lastName string
		var age sql.NullInt64
		var dateOfBirth sql.NullTime
		var phoneNumber, address, notes, createdBy sql.NullString
		var existingPatientCode sql.NullInt64
		var wasAdded bool
		var createdAt time.Time

		if err := rows.Scan(&id, &appointmentDate, &firstName, &lastName, &age, &dateOfBirth,
			&phoneNumber, &address, &notes, &existingPatientCode, &wasAdded, &createdAt, &createdBy); err != nil {
			continue
		}

		apt := map[string]interface{}{
			"id":               id,
			"appointment_date": appointmentDate.Format(time.RFC3339),
			"first_name":       firstName,
			"last_name":        lastName,
			"was_added":        wasAdded,
			"created_at":       createdAt.Format(time.RFC3339),
		}
		if age.Valid {
			apt["age"] = age.Int64
		}
		if dateOfBirth.Valid {
			apt["date_of_birth"] = dateOfBirth.Time.Format(time.RFC3339)
		}
		if phoneNumber.Valid {
			apt["phone_number"] = phoneNumber.String
		}
		if address.Valid {
			apt["address"] = address.String
		}
		if notes.Valid {
			apt["notes"] = notes.String
		}
		if existingPatientCode.Valid {
			apt["existing_patient_code"] = existingPatientCode.Int64
		}
		if createdBy.Valid {
			apt["created_by"] = createdBy.String
		}
		appointments = append(appointments, apt)
	}
	respondJSON(w, map[string]interface{}{"appointments": appointments})
}

func (h *RESTHandler) GetAllAppointments(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(`
		SELECT id, appointment_date, first_name, last_name, age, date_of_birth, 
		       phone_number, address, notes, existing_patient_code, was_added, created_at, created_by
		FROM appointments 
		ORDER BY appointment_date
	`)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	appointments := []map[string]interface{}{}
	for rows.Next() {
		var id int
		var appointmentDate time.Time
		var firstName, lastName string
		var age sql.NullInt64
		var dateOfBirth sql.NullTime
		var phoneNumber, address, notes, createdBy sql.NullString
		var existingPatientCode sql.NullInt64
		var wasAdded bool
		var createdAt time.Time

		if err := rows.Scan(&id, &appointmentDate, &firstName, &lastName, &age, &dateOfBirth,
			&phoneNumber, &address, &notes, &existingPatientCode, &wasAdded, &createdAt, &createdBy); err != nil {
			continue
		}

		apt := map[string]interface{}{
			"id":               id,
			"appointment_date": appointmentDate.Format(time.RFC3339),
			"first_name":       firstName,
			"last_name":        lastName,
			"was_added":        wasAdded,
			"created_at":       createdAt.Format(time.RFC3339),
		}
		if age.Valid {
			apt["age"] = age.Int64
		}
		if dateOfBirth.Valid {
			apt["date_of_birth"] = dateOfBirth.Time.Format(time.RFC3339)
		}
		if phoneNumber.Valid {
			apt["phone_number"] = phoneNumber.String
		}
		if address.Valid {
			apt["address"] = address.String
		}
		if notes.Valid {
			apt["notes"] = notes.String
		}
		if existingPatientCode.Valid {
			apt["existing_patient_code"] = existingPatientCode.Int64
		}
		if createdBy.Valid {
			apt["created_by"] = createdBy.String
		}
		appointments = append(appointments, apt)
	}
	respondJSON(w, map[string]interface{}{"appointments": appointments})
}

func (h *RESTHandler) CreateAppointment(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	appointmentDate, _ := time.Parse(time.RFC3339, req["appointment_date"].(string))
	firstName := req["first_name"].(string)
	lastName := req["last_name"].(string)

	var age sql.NullInt64
	if v, ok := req["age"]; ok && v != nil {
		age = sql.NullInt64{Int64: int64(v.(float64)), Valid: true}
	}

	var dateOfBirth sql.NullTime
	if v, ok := req["date_of_birth"]; ok && v != nil {
		if t, err := time.Parse(time.RFC3339, v.(string)); err == nil {
			dateOfBirth = sql.NullTime{Time: t, Valid: true}
		}
	}

	var phoneNumber, address, notes, createdBy sql.NullString
	if v, ok := req["phone_number"]; ok && v != nil {
		phoneNumber = sql.NullString{String: v.(string), Valid: true}
	}
	if v, ok := req["address"]; ok && v != nil {
		address = sql.NullString{String: v.(string), Valid: true}
	}
	if v, ok := req["notes"]; ok && v != nil {
		notes = sql.NullString{String: v.(string), Valid: true}
	}
	if v, ok := req["created_by"]; ok && v != nil {
		createdBy = sql.NullString{String: v.(string), Valid: true}
	}

	var existingPatientCode sql.NullInt64
	if v, ok := req["existing_patient_code"]; ok && v != nil {
		existingPatientCode = sql.NullInt64{Int64: int64(v.(float64)), Valid: true}
	}

	result, err := h.db.Exec(`
		INSERT INTO appointments (appointment_date, first_name, last_name, age, date_of_birth, 
		                          phone_number, address, notes, existing_patient_code, created_by, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
	`, appointmentDate, firstName, lastName, age, dateOfBirth, phoneNumber, address, notes, existingPatientCode, createdBy, time.Now())
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	id, _ := result.LastInsertId()
	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) UpdateAppointmentDate(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	newDate, _ := time.Parse(time.RFC3339, req["new_date"].(string))

	_, err := h.db.Exec(`UPDATE appointments SET appointment_date = $1 WHERE id = $2`, newDate, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	respondJSON(w, map[string]interface{}{"success": true})
}

func (h *RESTHandler) MarkAppointmentAsAdded(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	_, err := h.db.Exec(`UPDATE appointments SET was_added = 1 WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	respondJSON(w, map[string]interface{}{"success": true})
}

func (h *RESTHandler) DeleteAppointment(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	_, err := h.db.Exec(`DELETE FROM appointments WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	respondJSON(w, map[string]interface{}{"success": true})
}

func (h *RESTHandler) CleanupPastAppointments(w http.ResponseWriter, r *http.Request) {
	startOfToday := time.Date(time.Now().Year(), time.Now().Month(), time.Now().Day(), 0, 0, 0, 0, time.Local)

	result, err := h.db.Exec(`DELETE FROM appointments WHERE appointment_date < $1 AND was_added = 0`, startOfToday)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}

	deleted, _ := result.RowsAffected()
	respondJSON(w, map[string]interface{}{"deleted": deleted})
}

// ==================== SURGERY PLAN HANDLERS ====================

func (h *RESTHandler) GetSurgeryPlansForDate(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	date, _ := time.Parse(time.RFC3339, req["date"].(string))
	startOfDay := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.Local)
	endOfDay := time.Date(date.Year(), date.Month(), date.Day(), 23, 59, 59, 0, time.Local)

	rows, err := h.db.Query(`
		SELECT id, surgery_date, surgery_hour, patient_code, patient_first_name, patient_last_name,
		       patient_age, patient_phone, surgery_type, eye_to_operate, implant_power, tarif,
		       payment_status, amount_remaining, surgery_status, patient_came, notes,
		       created_at, created_by, updated_at, needs_sync
		FROM surgery_plans 
		WHERE surgery_date BETWEEN $1 AND $2
		ORDER BY surgery_hour
	`, startOfDay, endOfDay)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	plans := []map[string]interface{}{}
	for rows.Next() {
		var id, patientCode int
		var surgeryDate time.Time
		var surgeryHour, patientFirstName, patientLastName, surgeryType, eyeToOperate string
		var patientAge sql.NullInt64
		var patientPhone, implantPower, notes, createdBy sql.NullString
		var tarif, amountRemaining sql.NullInt64
		var paymentStatus, surgeryStatus string
		var patientCame, needsSync bool
		var createdAt, updatedAt time.Time

		if err := rows.Scan(&id, &surgeryDate, &surgeryHour, &patientCode, &patientFirstName, &patientLastName,
			&patientAge, &patientPhone, &surgeryType, &eyeToOperate, &implantPower, &tarif,
			&paymentStatus, &amountRemaining, &surgeryStatus, &patientCame, &notes,
			&createdAt, &createdBy, &updatedAt, &needsSync); err != nil {
			continue
		}

		plan := map[string]interface{}{
			"id":                 id,
			"surgery_date":       surgeryDate.Format(time.RFC3339),
			"surgery_hour":       surgeryHour,
			"patient_code":       patientCode,
			"patient_first_name": patientFirstName,
			"patient_last_name":  patientLastName,
			"surgery_type":       surgeryType,
			"eye_to_operate":     eyeToOperate,
			"payment_status":     paymentStatus,
			"surgery_status":     surgeryStatus,
			"patient_came":       patientCame,
			"created_at":         createdAt.Format(time.RFC3339),
			"updated_at":         updatedAt.Format(time.RFC3339),
			"needs_sync":         needsSync,
		}
		if patientAge.Valid {
			plan["patient_age"] = patientAge.Int64
		}
		if patientPhone.Valid {
			plan["patient_phone"] = patientPhone.String
		}
		if implantPower.Valid {
			plan["implant_power"] = implantPower.String
		}
		if tarif.Valid {
			plan["tarif"] = tarif.Int64
		}
		if amountRemaining.Valid {
			plan["amount_remaining"] = amountRemaining.Int64
		}
		if notes.Valid {
			plan["notes"] = notes.String
		}
		if createdBy.Valid {
			plan["created_by"] = createdBy.String
		}
		plans = append(plans, plan)
	}
	respondJSON(w, map[string]interface{}{"surgery_plans": plans})
}

func (h *RESTHandler) GetAllSurgeryPlans(w http.ResponseWriter, r *http.Request) {
	rows, err := h.db.Query(`
		SELECT id, surgery_date, surgery_hour, patient_code, patient_first_name, patient_last_name,
		       patient_age, patient_phone, surgery_type, eye_to_operate, implant_power, tarif,
		       payment_status, amount_remaining, surgery_status, patient_came, notes,
		       created_at, created_by, updated_at, needs_sync
		FROM surgery_plans 
		ORDER BY surgery_date, surgery_hour
	`)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	defer rows.Close()

	plans := []map[string]interface{}{}
	for rows.Next() {
		var id, patientCode int
		var surgeryDate time.Time
		var surgeryHour, patientFirstName, patientLastName, surgeryType, eyeToOperate string
		var patientAge sql.NullInt64
		var patientPhone, implantPower, notes, createdBy sql.NullString
		var tarif, amountRemaining sql.NullInt64
		var paymentStatus, surgeryStatus string
		var patientCame, needsSync bool
		var createdAt, updatedAt time.Time

		if err := rows.Scan(&id, &surgeryDate, &surgeryHour, &patientCode, &patientFirstName, &patientLastName,
			&patientAge, &patientPhone, &surgeryType, &eyeToOperate, &implantPower, &tarif,
			&paymentStatus, &amountRemaining, &surgeryStatus, &patientCame, &notes,
			&createdAt, &createdBy, &updatedAt, &needsSync); err != nil {
			continue
		}

		plan := map[string]interface{}{
			"id":                 id,
			"surgery_date":       surgeryDate.Format(time.RFC3339),
			"surgery_hour":       surgeryHour,
			"patient_code":       patientCode,
			"patient_first_name": patientFirstName,
			"patient_last_name":  patientLastName,
			"surgery_type":       surgeryType,
			"eye_to_operate":     eyeToOperate,
			"payment_status":     paymentStatus,
			"surgery_status":     surgeryStatus,
			"patient_came":       patientCame,
			"created_at":         createdAt.Format(time.RFC3339),
			"updated_at":         updatedAt.Format(time.RFC3339),
			"needs_sync":         needsSync,
		}
		if patientAge.Valid {
			plan["patient_age"] = patientAge.Int64
		}
		if patientPhone.Valid {
			plan["patient_phone"] = patientPhone.String
		}
		if implantPower.Valid {
			plan["implant_power"] = implantPower.String
		}
		if tarif.Valid {
			plan["tarif"] = tarif.Int64
		}
		if amountRemaining.Valid {
			plan["amount_remaining"] = amountRemaining.Int64
		}
		if notes.Valid {
			plan["notes"] = notes.String
		}
		if createdBy.Valid {
			plan["created_by"] = createdBy.String
		}
		plans = append(plans, plan)
	}
	respondJSON(w, map[string]interface{}{"surgery_plans": plans})
}

func (h *RESTHandler) CreateSurgeryPlan(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	surgeryDate, _ := time.Parse(time.RFC3339, req["surgery_date"].(string))
	surgeryHour := req["surgery_hour"].(string)
	patientCode := int(req["patient_code"].(float64))
	patientFirstName := req["patient_first_name"].(string)
	patientLastName := req["patient_last_name"].(string)
	surgeryType := req["surgery_type"].(string)
	eyeToOperate := req["eye_to_operate"].(string)

	var patientAge *int
	if v, ok := req["patient_age"]; ok && v != nil {
		age := int(v.(float64))
		patientAge = &age
	}

	var patientPhone, implantPower, notes, createdBy *string
	if v, ok := req["patient_phone"]; ok && v != nil {
		s := v.(string)
		patientPhone = &s
	}
	if v, ok := req["implant_power"]; ok && v != nil {
		s := v.(string)
		implantPower = &s
	}
	if v, ok := req["notes"]; ok && v != nil {
		s := v.(string)
		notes = &s
	}
	if v, ok := req["created_by"]; ok && v != nil {
		s := v.(string)
		createdBy = &s
	}

	var tarif *int
	if v, ok := req["tarif"]; ok && v != nil {
		t := int(v.(float64))
		tarif = &t
	}

	now := time.Now()
	result, err := h.db.Exec(`
		INSERT INTO surgery_plans (surgery_date, surgery_hour, patient_code, patient_first_name, patient_last_name,
		                          patient_age, patient_phone, surgery_type, eye_to_operate, implant_power, tarif,
		                          payment_status, surgery_status, notes, created_by, created_at, updated_at, needs_sync)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'pending', 'scheduled', $12, $13, $14, $15, 1)
	`, surgeryDate, surgeryHour, patientCode, patientFirstName, patientLastName,
		patientAge, patientPhone, surgeryType, eyeToOperate, implantPower, tarif,
		notes, createdBy, now, now)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	id, _ := result.LastInsertId()
	respondJSON(w, map[string]interface{}{"id": id})
}

func (h *RESTHandler) UpdateSurgeryPlan(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))

	// Build dynamic update query
	updates := []string{}
	args := []interface{}{}

	if v, ok := req["surgery_hour"]; ok && v != nil {
		updates = append(updates, "surgery_hour = $1")
		args = append(args, v.(string))
	}
	if v, ok := req["surgery_type"]; ok && v != nil {
		updates = append(updates, "surgery_type = $1")
		args = append(args, v.(string))
	}
	if v, ok := req["eye_to_operate"]; ok && v != nil {
		updates = append(updates, "eye_to_operate = $1")
		args = append(args, v.(string))
	}
	if v, ok := req["implant_power"]; ok && v != nil {
		updates = append(updates, "implant_power = $1")
		args = append(args, v.(string))
	}
	if v, ok := req["tarif"]; ok && v != nil {
		updates = append(updates, "tarif = $1")
		args = append(args, int(v.(float64)))
	}
	if v, ok := req["payment_status"]; ok && v != nil {
		updates = append(updates, "payment_status = $1")
		args = append(args, v.(string))
	}
	if v, ok := req["amount_remaining"]; ok && v != nil {
		updates = append(updates, "amount_remaining = $1")
		args = append(args, int(v.(float64)))
	}
	if v, ok := req["surgery_status"]; ok && v != nil {
		updates = append(updates, "surgery_status = $1")
		args = append(args, v.(string))
	}
	if v, ok := req["patient_came"]; ok && v != nil {
		updates = append(updates, "patient_came = $1")
		if v.(bool) {
			args = append(args, 1)
		} else {
			args = append(args, 0)
		}
	}
	if v, ok := req["notes"]; ok && v != nil {
		updates = append(updates, "notes = $1")
		args = append(args, v.(string))
	}

	if len(updates) == 0 {
		respondJSON(w, map[string]interface{}{"success": true})
		return
	}

	updates = append(updates, "updated_at = $1", "needs_sync = 1")
	args = append(args, time.Now())
	args = append(args, id)

	query := "UPDATE surgery_plans SET " + joinStrings(updates, ", ") + " WHERE id = $1"
	_, err := h.db.Exec(query, args...)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	respondJSON(w, map[string]interface{}{"success": true})
}

func (h *RESTHandler) RescheduleSurgery(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	newDate, _ := time.Parse(time.RFC3339, req["surgery_date"].(string))

	// Build dynamic update query
	updates := []string{"surgery_date = $1"}
	args := []interface{}{newDate}

	if v, ok := req["surgery_hour"]; ok && v != nil {
		updates = append(updates, "surgery_hour = $1")
		args = append(args, v.(string))
	}
	if v, ok := req["surgery_type"]; ok && v != nil {
		updates = append(updates, "surgery_type = $1")
		args = append(args, v.(string))
	}
	if v, ok := req["eye_to_operate"]; ok && v != nil {
		updates = append(updates, "eye_to_operate = $1")
		args = append(args, v.(string))
	}
	if v, ok := req["implant_power"]; ok && v != nil {
		updates = append(updates, "implant_power = $1")
		args = append(args, v.(string))
	}
	if v, ok := req["tarif"]; ok && v != nil {
		updates = append(updates, "tarif = $1")
		args = append(args, int(v.(float64)))
	}

	updates = append(updates, "updated_at = $1", "needs_sync = 1")
	args = append(args, time.Now())
	args = append(args, id)

	query := "UPDATE surgery_plans SET " + joinStrings(updates, ", ") + " WHERE id = $1"
	_, err := h.db.Exec(query, args...)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	respondJSON(w, map[string]interface{}{"success": true})
}

func (h *RESTHandler) DeleteSurgeryPlan(w http.ResponseWriter, r *http.Request) {
	var req map[string]interface{}
	if err := decodeBody(r, &req); err != nil {
		respondError(w, 400, err.Error())
		return
	}

	id := int(req["id"].(float64))
	_, err := h.db.Exec(`DELETE FROM surgery_plans WHERE id = $1`, id)
	if err != nil {
		respondError(w, 500, err.Error())
		return
	}
	respondJSON(w, map[string]interface{}{"success": true})
}

// Helper function to join strings
func joinStrings(strs []string, sep string) string {
	result := ""
	for i, s := range strs {
		if i > 0 {
			result += sep
		}
		result += s
	}
	return result
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
