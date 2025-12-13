package api

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"
)

// EventType represents the type of real-time event
type EventType string

const (
	// Patient events
	EventPatientCreated EventType = "patient_created"
	EventPatientUpdated EventType = "patient_updated"
	EventPatientDeleted EventType = "patient_deleted"

	// Message events
	EventMessageCreated  EventType = "message_created"
	EventMessageRead     EventType = "message_read"
	EventMessagesCleared EventType = "messages_cleared"

	// Waiting queue events
	EventWaitingAdded    EventType = "waiting_added"
	EventWaitingUpdated  EventType = "waiting_updated"
	EventWaitingRemoved  EventType = "waiting_removed"
	EventDilatationAdded EventType = "dilatation_added"

	// Payment events
	EventPaymentCreated EventType = "payment_created"
	EventPaymentUpdated EventType = "payment_updated"
	EventPaymentDeleted EventType = "payment_deleted"

	// User events
	EventUserCreated EventType = "user_created"
	EventUserUpdated EventType = "user_updated"
	EventUserDeleted EventType = "user_deleted"

	// User template events
	EventTemplateCreated EventType = "template_created"
	EventTemplateUpdated EventType = "template_updated"
	EventTemplateDeleted EventType = "template_deleted"

	// Room events
	EventRoomCreated EventType = "room_created"
	EventRoomUpdated EventType = "room_updated"
	EventRoomDeleted EventType = "room_deleted"

	// Visit events
	EventVisitCreated EventType = "visit_created"
	EventVisitUpdated EventType = "visit_updated"
	EventVisitDeleted EventType = "visit_deleted"

	// Ordonnance events
	EventOrdonnanceCreated EventType = "ordonnance_created"
	EventOrdonnanceUpdated EventType = "ordonnance_updated"
	EventOrdonnanceDeleted EventType = "ordonnance_deleted"

	// Medical act events
	EventMedicalActCreated EventType = "medical_act_created"
	EventMedicalActUpdated EventType = "medical_act_updated"
	EventMedicalActDeleted EventType = "medical_act_deleted"
	EventMedicalActReorder EventType = "medical_act_reorder"

	// Message template events
	EventMsgTemplateCreated EventType = "msg_template_created"
	EventMsgTemplateUpdated EventType = "msg_template_updated"
	EventMsgTemplateDeleted EventType = "msg_template_deleted"
	EventMsgTemplateReorder EventType = "msg_template_reorder"

	// Medication events
	EventMedicationCreated EventType = "medication_created"
	EventMedicationUpdated EventType = "medication_updated"
	EventMedicationDeleted EventType = "medication_deleted"

	// Nurse preference events
	EventNursePrefsUpdated EventType = "nurse_prefs_updated"
	EventNurseActive       EventType = "nurse_active"
	EventNurseInactive     EventType = "nurse_inactive"

	// System events
	EventPing EventType = "ping"
)

// Event represents a real-time event to broadcast
type Event struct {
	Type      EventType              `json:"type"`
	RoomID    string                 `json:"room_id,omitempty"`
	Data      map[string]interface{} `json:"data,omitempty"`
	Timestamp int64                  `json:"timestamp"`
}

// SSEClient represents a connected SSE client
type SSEClient struct {
	ID      string
	RoomIDs []string // Optional: rooms this client is interested in
	Events  chan Event
	Done    chan struct{}
}

// EventHub manages SSE connections and broadcasts events
type EventHub struct {
	clients    map[string]*SSEClient
	register   chan *SSEClient
	unregister chan string
	broadcast  chan Event
	mutex      sync.RWMutex
}

// Global event hub instance
var Hub *EventHub

func init() {
	Hub = NewEventHub()
	go Hub.Run()
}

// NewEventHub creates a new event hub
func NewEventHub() *EventHub {
	return &EventHub{
		clients:    make(map[string]*SSEClient),
		register:   make(chan *SSEClient),
		unregister: make(chan string),
		broadcast:  make(chan Event, 100), // Buffered channel for events
	}
}

// Run starts the event hub main loop
func (h *EventHub) Run() {
	// Ping ticker to keep connections alive
	pingTicker := time.NewTicker(15 * time.Second)
	defer pingTicker.Stop()

	for {
		select {
		case client := <-h.register:
			h.mutex.Lock()
			h.clients[client.ID] = client
			h.mutex.Unlock()
			log.Printf("📡 SSE: Client %s connected (total: %d)", client.ID, len(h.clients))

		case clientID := <-h.unregister:
			h.mutex.Lock()
			if client, ok := h.clients[clientID]; ok {
				close(client.Events)
				delete(h.clients, clientID)
			}
			h.mutex.Unlock()
			log.Printf("📡 SSE: Client %s disconnected (total: %d)", clientID, len(h.clients))

		case event := <-h.broadcast:
			h.mutex.RLock()
			for _, client := range h.clients {
				// Send to all clients (they filter by room if needed)
				select {
				case client.Events <- event:
				default:
					// Client buffer full, skip this event
					log.Printf("⚠️ SSE: Client %s buffer full, skipping event", client.ID)
				}
			}
			h.mutex.RUnlock()

		case <-pingTicker.C:
			// Send ping to all clients
			h.Broadcast(Event{
				Type:      EventPing,
				Timestamp: time.Now().UnixMilli(),
			})
		}
	}
}

// Broadcast sends an event to all connected clients
func (h *EventHub) Broadcast(event Event) {
	if event.Timestamp == 0 {
		event.Timestamp = time.Now().UnixMilli()
	}
	select {
	case h.broadcast <- event:
	default:
		log.Printf("⚠️ SSE: Broadcast channel full, dropping event")
	}
}

// BroadcastToRoom sends an event only to clients interested in a specific room
func (h *EventHub) BroadcastToRoom(roomID string, event Event) {
	event.RoomID = roomID
	h.Broadcast(event)
}

// ClientCount returns the number of connected clients
func (h *EventHub) ClientCount() int {
	h.mutex.RLock()
	defer h.mutex.RUnlock()
	return len(h.clients)
}

// SetupSSERoutes adds SSE endpoint to the mux
func (h *RESTHandler) SetupSSERoutes(mux *http.ServeMux) {
	mux.HandleFunc("/api/events", h.SSEHandler)
	mux.HandleFunc("/api/events/status", h.SSEStatusHandler)
	log.Println("📡 SSE real-time events endpoint registered at /api/events")
}

// SSEHandler handles Server-Sent Events connections
func (h *RESTHandler) SSEHandler(w http.ResponseWriter, r *http.Request) {
	// Set SSE headers
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
	w.Header().Set("X-Accel-Buffering", "no") // Disable nginx buffering

	// Get flusher
	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "SSE not supported", http.StatusInternalServerError)
		return
	}

	// Generate client ID
	clientID := fmt.Sprintf("client_%d", time.Now().UnixNano())

	// Get optional room filter from query params
	roomIDs := r.URL.Query()["room"]

	// Create client
	client := &SSEClient{
		ID:      clientID,
		RoomIDs: roomIDs,
		Events:  make(chan Event, 50), // Buffer 50 events
		Done:    make(chan struct{}),
	}

	// Register client
	Hub.register <- client

	// Cleanup on disconnect
	defer func() {
		Hub.unregister <- clientID
	}()

	// Send initial connection event
	initialEvent := Event{
		Type:      "connected",
		Timestamp: time.Now().UnixMilli(),
		Data:      map[string]interface{}{"client_id": clientID},
	}
	data, _ := json.Marshal(initialEvent)
	fmt.Fprintf(w, "data: %s\n\n", data)
	flusher.Flush()

	// Stream events
	for {
		select {
		case event, ok := <-client.Events:
			if !ok {
				return
			}
			data, err := json.Marshal(event)
			if err != nil {
				continue
			}
			fmt.Fprintf(w, "data: %s\n\n", data)
			flusher.Flush()

		case <-r.Context().Done():
			return
		}
	}
}

// SSEStatusHandler returns SSE connection status
func (h *RESTHandler) SSEStatusHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	status := map[string]interface{}{
		"connected_clients": Hub.ClientCount(),
		"server_time":       time.Now().UnixMilli(),
	}
	json.NewEncoder(w).Encode(status)
}

// Helper functions to broadcast events from handlers

// BroadcastPatientEvent broadcasts patient-related events
func BroadcastPatientEvent(eventType EventType, patientCode int, data map[string]interface{}) {
	if data == nil {
		data = make(map[string]interface{})
	}
	data["patient_code"] = patientCode
	Hub.Broadcast(Event{
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now().UnixMilli(),
	})
}

// BroadcastMessageEvent broadcasts message-related events
func BroadcastMessageEvent(eventType EventType, roomID string, data map[string]interface{}) {
	Hub.BroadcastToRoom(roomID, Event{
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now().UnixMilli(),
	})
}

// BroadcastWaitingEvent broadcasts waiting queue events
func BroadcastWaitingEvent(eventType EventType, roomID string, data map[string]interface{}) {
	Hub.BroadcastToRoom(roomID, Event{
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now().UnixMilli(),
	})
}

// BroadcastPaymentEvent broadcasts payment-related events
func BroadcastPaymentEvent(eventType EventType, data map[string]interface{}) {
	Hub.Broadcast(Event{
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now().UnixMilli(),
	})
}

// BroadcastUserEvent broadcasts user-related events
func BroadcastUserEvent(eventType EventType, data map[string]interface{}) {
	Hub.Broadcast(Event{
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now().UnixMilli(),
	})
}

// BroadcastRoomEvent broadcasts room-related events
func BroadcastRoomEvent(eventType EventType, data map[string]interface{}) {
	Hub.Broadcast(Event{
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now().UnixMilli(),
	})
}

// BroadcastVisitEvent broadcasts visit-related events
func BroadcastVisitEvent(eventType EventType, patientCode int, data map[string]interface{}) {
	if data == nil {
		data = make(map[string]interface{})
	}
	data["patient_code"] = patientCode
	Hub.Broadcast(Event{
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now().UnixMilli(),
	})
}

// BroadcastTemplateEvent broadcasts user template events
func BroadcastTemplateEvent(eventType EventType, data map[string]interface{}) {
	Hub.Broadcast(Event{
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now().UnixMilli(),
	})
}

// BroadcastOrdonnanceEvent broadcasts ordonnance events
func BroadcastOrdonnanceEvent(eventType EventType, patientCode int, data map[string]interface{}) {
	if data == nil {
		data = make(map[string]interface{})
	}
	data["patient_code"] = patientCode
	Hub.Broadcast(Event{
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now().UnixMilli(),
	})
}

// BroadcastMedicalActEvent broadcasts medical act events
func BroadcastMedicalActEvent(eventType EventType, data map[string]interface{}) {
	Hub.Broadcast(Event{
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now().UnixMilli(),
	})
}

// BroadcastMsgTemplateEvent broadcasts message template events
func BroadcastMsgTemplateEvent(eventType EventType, data map[string]interface{}) {
	Hub.Broadcast(Event{
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now().UnixMilli(),
	})
}

// BroadcastMedicationEvent broadcasts medication events
func BroadcastMedicationEvent(eventType EventType, data map[string]interface{}) {
	Hub.Broadcast(Event{
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now().UnixMilli(),
	})
}

// BroadcastNursePrefsEvent broadcasts nurse preference events
func BroadcastNursePrefsEvent(eventType EventType, data map[string]interface{}) {
	Hub.Broadcast(Event{
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now().UnixMilli(),
	})
}
