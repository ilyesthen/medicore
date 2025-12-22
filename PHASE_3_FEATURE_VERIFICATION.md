# 📋 Phase 3: Complete Feature Verification Checklist

## 🎯 Overview

This document provides a comprehensive checklist for verifying that ALL features work correctly in the new client-server architecture.

---

## 3.1 Domain Entity Verification

### ✅ Entity Feature Matrix

| Entity | Fields | CRUD | List | Search | Real-time | Status |
|--------|--------|------|------|--------|-----------|--------|
| **Patients** | 12 | 🔲 | 🔲 | 🔲 | 🔲 | ⏳ Pending |
| **Visits** | 54 | 🔲 | 🔲 | 🔲 | 🔲 | ⏳ Pending |
| **Ordonnances** | 23 | 🔲 | 🔲 | 🔲 | 🔲 | ⏳ Pending |
| **Surgery Plans** | 21 | 🔲 | 🔲 | 🔲 | 🔲 | ⏳ Pending |
| **Waiting Queue** | 19 | 🔲 | 🔲 | 🔲 | 🔲 | ⏳ Pending |
| **Payments** | 14 | 🔲 | 🔲 | 🔲 | 🔲 | ⏳ Pending |
| **Appointments** | 13 | 🔲 | 🔲 | 🔲 | 🔲 | ⏳ Pending |
| **Messages** | 12 | 🔲 | 🔲 | 🔲 | 🔲 | ⏳ Pending |
| **Users** | 12 | 🔲 | 🔲 | 🔲 | 🔲 | ⏳ Pending |
| **Medications** | 8 | 🔲 | 🔲 | 🔲 | 🔲 | ⏳ Pending |
| **Medical Acts** | 6 | 🔲 | 🔲 | 🔲 | 🔲 | ⏳ Pending |
| **Message Templates** | 5 | 🔲 | 🔲 | 🔲 | 🔲 | ⏳ Pending |
| **Templates** | 8 | 🔲 | 🔲 | 🔲 | 🔲 | ⏳ Pending |
| **Rooms** | 4 | 🔲 | 🔲 | 🔲 | 🔲 | ⏳ Pending |

---

## 🧪 Detailed Entity Tests

### 1. PATIENTS (12 fields)

**Fields to verify:**
- `code` (PK, auto-increment)
- `barcode` (8 chars, unique)
- `first_name`
- `last_name`
- `age`
- `date_of_birth`
- `address`
- `phone_number`
- `other_info`
- `created_at`
- `updated_at`
- `needs_sync`

**Test Cases:**
- [ ] **Create Patient**
  - [ ] Auto-generate code
  - [ ] Auto-generate barcode (8 chars)
  - [ ] Save all fields correctly
  - [ ] Return created patient
- [ ] **Read Patient**
  - [ ] Get by code
  - [ ] Get by barcode
  - [ ] Full-text search by name
- [ ] **Update Patient**
  - [ ] Update demographics
  - [ ] Update contact info
  - [ ] `updated_at` timestamp updates
- [ ] **Delete Patient**
  - [ ] Soft delete (set deleted_at)
  - [ ] Cannot delete with existing visits
- [ ] **List Patients**
  - [ ] Paginated list
  - [ ] Sort by name
  - [ ] Sort by created date
- [ ] **Search Patients**
  - [ ] Search by name (first/last)
  - [ ] Search by phone
  - [ ] Multi-word search
- [ ] **Real-time Events**
  - [ ] `patient_created` event
  - [ ] `patient_updated` event
  - [ ] `patient_deleted` event

---

### 2. VISITS (54 fields - Most Complex!)

**Field Categories:**
- Basic: id, patient_code, visit_date, doctor_name, motif, diagnosis, conduct (7)
- Right Eye (OD): 18 fields
- Left Eye (OG): 18 fields
- Shared: addition, dip (2)
- Metadata: created_at, updated_at, needs_sync, is_active (4)
- **Total: 49 fields** (not 54 - need to verify)

**Test Cases:**
- [ ] **Create Visit**
  - [ ] Save all 49+ fields
  - [ ] Link to patient
  - [ ] Auto-increment visit sequence
  - [ ] Set timestamps
- [ ] **Read Visit**
  - [ ] Get by ID
  - [ ] Get all visits for patient
  - [ ] Get latest visit for patient
- [ ] **Update Visit**
  - [ ] Update any field
  - [ ] Preserve other fields
  - [ ] Update timestamp
- [ ] **Delete Visit**
  - [ ] Soft delete (is_active = false)
  - [ ] Cannot delete if referenced
- [ ] **List Visits**
  - [ ] For specific patient
  - [ ] By date range
  - [ ] By doctor
- [ ] **Real-time Events**
  - [ ] `visit_created` event
  - [ ] `visit_updated` event
  - [ ] `visit_deleted` event

---

### 3. ORDONNANCES (23 fields)

**Fields:**
- Basic: id, patient_code, document_date, patient_age, sequence, doctor_name, amount (7)
- Document 1: content1, type1 (2)
- Document 2: content2, type2 (2)
- Document 3: content3, type3 (2)
- Additional: additional_notes, report_title, referred_by (3)
- RDV: rdv_flag, rdv_date, rdv_day (3)
- Metadata: seq_pat, original_id, created_at, updated_at (4)

**Test Cases:**
- [ ] **Create Ordonnance**
  - [ ] Link to patient
  - [ ] Save all 3 documents
  - [ ] Set document types
  - [ ] Auto-increment sequence
- [ ] **Read Ordonnance**
  - [ ] Get by ID
  - [ ] Get all for patient
  - [ ] Get by date range
- [ ] **Update Ordonnance**
  - [ ] Update any document
  - [ ] Update RDV info
  - [ ] Update amount
- [ ] **Delete Ordonnance**
  - [ ] Soft delete
  - [ ] Preserve for audit
- [ ] **PDF Generation**
  - [ ] Generate from template
  - [ ] Include all documents
  - [ ] Print correctly
- [ ] **Real-time Events**
  - [ ] `ordonnance_created` event
  - [ ] `ordonnance_updated` event

---

### 4. SURGERY PLANS (21 fields)

**Fields:**
- Basic: id, patient_code, surgery_date, surgery_hour, surgery_type, eye_to_operate (6)
- Patient cached: patient_first_name, patient_last_name, patient_age, patient_phone (4)
- Surgery: implant_power, tarif, notes (3)
- Status: surgery_status, patient_came (2)
- Payment: payment_status, amount_remaining (2)
- Metadata: created_at, created_by, updated_at, needs_sync (4)

**Test Cases:**
- [ ] **Create Surgery Plan**
  - [ ] Link to patient
  - [ ] Cache patient details
  - [ ] Set surgery details
  - [ ] Default status = 'scheduled'
- [ ] **Read Surgery Plan**
  - [ ] Get by ID
  - [ ] Get all for patient
  - [ ] Get by date
  - [ ] Get by status
- [ ] **Update Surgery Plan**
  - [ ] Update surgery details
  - [ ] Update payment status
  - [ ] Mark as done/cancelled
  - [ ] Mark patient came
- [ ] **Delete Surgery Plan**
  - [ ] Soft delete
  - [ ] Cannot delete if done
- [ ] **Calendar View**
  - [ ] List by date
  - [ ] Filter by status
  - [ ] Sort by time
- [ ] **Real-time Events**
  - [ ] Surgery plan created/updated

---

### 5. WAITING QUEUE (19 fields)

**Fields:**
- Basic: id, patient_code, room_id, motif, is_urgent, is_dilatation, dilatation_type (7)
- Patient cached: patient_first_name, patient_last_name, patient_birth_date, patient_age, patient_created_at (5)
- Room cached: room_name (1)
- Sender: sent_by_user_id, sent_by_user_name, sent_at (3)
- Status: is_checked, is_active, is_notified (3)

**Test Cases:**
- [ ] **Add to Queue**
  - [ ] Cache patient details
  - [ ] Cache room details
  - [ ] Set sender info
  - [ ] Set timestamp
- [ ] **Get Queue**
  - [ ] For specific room
  - [ ] Filter by active
  - [ ] Sort by sent_at
- [ ] **Update Queue Item**
  - [ ] Mark as checked
  - [ ] Mark as notified
  - [ ] Update dilatation status
- [ ] **Remove from Queue**
  - [ ] Set is_active = false
  - [ ] Preserve record
- [ ] **Real-time Events**
  - [ ] `waiting_added` event
  - [ ] `waiting_updated` event
  - [ ] `waiting_removed` event
  - [ ] `dilatation_added` event
- [ ] **Sound Notifications**
  - [ ] Play for nurses in room
  - [ ] Don't play for doctors

---

### 6. PAYMENTS (14 fields)

**Fields:**
- Basic: id, medical_act_id, medical_act_name, amount (4)
- User: user_id, user_name (2)
- Patient: patient_code, patient_first_name, patient_last_name (3)
- Time: payment_time (1)
- Metadata: created_at, updated_at, needs_sync, is_active (4)

**Test Cases:**
- [ ] **Create Payment**
  - [ ] Link to medical act
  - [ ] Cache act name and amount
  - [ ] Link to user
  - [ ] Link to patient
  - [ ] Set payment time
- [ ] **Read Payment**
  - [ ] Get by ID
  - [ ] Get all for user
  - [ ] Get all for patient
  - [ ] Get by date range
- [ ] **Filter Payments**
  - [ ] Morning (before 13:00)
  - [ ] Afternoon (after 13:00)
  - [ ] By date
  - [ ] By user
- [ ] **Reports**
  - [ ] Total by user
  - [ ] Total by date
  - [ ] Total by medical act
- [ ] **Delete Payment**
  - [ ] Soft delete only
  - [ ] Preserve for audit
- [ ] **Real-time Events**
  - [ ] `payment_created` event

---

### 7. APPOINTMENTS (13 fields)

**Fields:**
- Basic: id, appointment_date, first_name, last_name (4)
- Optional: age, date_of_birth, phone_number, address, notes (5)
- Link: existing_patient_code, was_added (2)
- Metadata: created_at, created_by (2)

**Test Cases:**
- [ ] **Create Appointment**
  - [ ] New patient info
  - [ ] Link to existing patient
  - [ ] Set appointment date
  - [ ] Set creator
- [ ] **Read Appointment**
  - [ ] Get by ID
  - [ ] Get all for date
  - [ ] Get future appointments
- [ ] **Update Appointment**
  - [ ] Change date
  - [ ] Update patient info
  - [ ] Mark as added (converted to patient)
- [ ] **Delete Appointment**
  - [ ] Hard delete
  - [ ] Auto-delete past appointments
- [ ] **Convert to Patient**
  - [ ] Create patient from appointment
  - [ ] Mark as added
  - [ ] Link appointment to patient
- [ ] **Calendar**
  - [ ] List by date
  - [ ] Show count per day
- [ ] **Real-time Events**
  - [ ] Appointment created/updated

---

### 8. MESSAGES (12 fields)

**Fields:**
- Basic: id, room_id, content, direction (4)
- Sender: sender_id, sender_name, sender_role (3)
- Status: is_read, sent_at, read_at (3)
- Patient: patient_code, patient_name (2)

**Test Cases:**
- [ ] **Send Message**
  - [ ] Set sender info
  - [ ] Set room
  - [ ] Set direction (to_nurse/to_doctor)
  - [ ] Optional patient context
- [ ] **Read Message**
  - [ ] Get by ID
  - [ ] Get all for room
  - [ ] Get unread count
  - [ ] Filter by direction
- [ ] **Mark as Read**
  - [ ] Set is_read = true
  - [ ] Set read_at timestamp
- [ ] **Delete Message**
  - [ ] Hard delete
  - [ ] Delete all for room
- [ ] **Real-time Events**
  - [ ] `message_created` event
  - [ ] `message_read` event
  - [ ] `messages_cleared` event
- [ ] **Notifications**
  - [ ] Badge count
  - [ ] Sound for recipients
  - [ ] No sound for sender

---

### 9-14. OTHER ENTITIES

**Quick verification for:**
- [ ] **Users** (12 fields) - Create, read, update, delete, roles
- [ ] **Medications** (8 fields) - CRUD, search, usage count
- [ ] **Medical Acts** (6 fields) - CRUD, reorder, fees
- [ ] **Message Templates** (5 fields) - CRUD, reorder
- [ ] **Templates** (8 fields) - Role templates, CRUD
- [ ] **Rooms** (4 fields) - CRUD, simple list

---

## 3.2 REST API Endpoint Verification

### 📡 Complete API Endpoint Checklist (90+ endpoints)

#### **USERS & AUTHENTICATION (10 endpoints)**

- [ ] `POST /api/auth/login` - User login
- [ ] `POST /api/auth/logout` - User logout
- [ ] `GET /api/users` - Get all users
- [ ] `GET /api/users/:id` - Get user by ID
- [ ] `POST /api/users` - Create user
- [ ] `PUT /api/users/:id` - Update user
- [ ] `DELETE /api/users/:id` - Delete user
- [ ] `GET /api/users/by-role/:role` - Get users by role
- [ ] `POST /api/users/validate` - Validate credentials
- [ ] `GET /api/users/count` - Get user count

---

#### **USER TEMPLATES (6 endpoints)**

- [ ] `GET /api/templates` - Get all templates
- [ ] `GET /api/templates/:id` - Get template by ID
- [ ] `POST /api/templates` - Create template
- [ ] `PUT /api/templates/:id` - Update template
- [ ] `DELETE /api/templates/:id` - Delete template
- [ ] `GET /api/templates/by-role/:role` - Get template by role

---

#### **ROOMS (5 endpoints)**

- [ ] `GET /api/rooms` - Get all rooms
- [ ] `GET /api/rooms/:id` - Get room by ID
- [ ] `POST /api/rooms` - Create room
- [ ] `PUT /api/rooms/:id` - Update room
- [ ] `DELETE /api/rooms/:id` - Delete room

---

#### **PATIENTS (7 endpoints)**

- [ ] `GET /api/patients` - Get all patients
- [ ] `GET /api/patients/:code` - Get patient by code
- [ ] `GET /api/patients/by-barcode/:barcode` - Get by barcode
- [ ] `POST /api/patients` - Create patient
- [ ] `POST /api/patients/search` - Search patients
- [ ] `PUT /api/patients/:code` - Update patient
- [ ] `DELETE /api/patients/:code` - Delete patient

---

#### **MESSAGES (6 endpoints)**

- [ ] `GET /api/messages/room/:roomId` - Get messages for room
- [ ] `GET /api/messages/unread/:roomId` - Get unread count
- [ ] `POST /api/messages` - Send message
- [ ] `PUT /api/messages/:id/read` - Mark as read
- [ ] `DELETE /api/messages/:id` - Delete message
- [ ] `DELETE /api/messages/room/:roomId` - Clear room messages

---

#### **MESSAGE TEMPLATES (6 endpoints)**

- [ ] `GET /api/message-templates` - Get all templates
- [ ] `GET /api/message-templates/:id` - Get template by ID
- [ ] `POST /api/message-templates` - Create template
- [ ] `PUT /api/message-templates/:id` - Update template
- [ ] `DELETE /api/message-templates/:id` - Delete template
- [ ] `POST /api/message-templates/reorder` - Reorder templates

---

#### **WAITING QUEUE (7 endpoints)**

- [ ] `GET /api/waiting/room/:roomId` - Get queue for room
- [ ] `GET /api/waiting/:id` - Get queue item by ID
- [ ] `POST /api/waiting` - Add to queue
- [ ] `PUT /api/waiting/:id` - Update queue item
- [ ] `PUT /api/waiting/:id/check` - Toggle checked
- [ ] `DELETE /api/waiting/:id` - Remove from queue
- [ ] `GET /api/waiting/count/:roomId` - Get count for room

---

#### **MEDICAL ACTS (6 endpoints)**

- [ ] `GET /api/medical-acts` - Get all medical acts
- [ ] `GET /api/medical-acts/:id` - Get medical act by ID
- [ ] `POST /api/medical-acts` - Create medical act
- [ ] `PUT /api/medical-acts/:id` - Update medical act
- [ ] `DELETE /api/medical-acts/:id` - Delete medical act
- [ ] `POST /api/medical-acts/reorder` - Reorder acts

---

#### **VISITS (8 endpoints)**

- [ ] `GET /api/visits/patient/:patientCode` - Get visits for patient
- [ ] `GET /api/visits/:id` - Get visit by ID
- [ ] `POST /api/visits` - Create visit
- [ ] `PUT /api/visits/:id` - Update visit
- [ ] `DELETE /api/visits/:id` - Delete visit
- [ ] `GET /api/visits/latest/:patientCode` - Get latest visit
- [ ] `GET /api/visits/count/:patientCode` - Get visit count
- [ ] `GET /api/visits/by-doctor/:doctorName` - Get by doctor

---

#### **ORDONNANCES (4 endpoints)**

- [ ] `GET /api/ordonnances/patient/:patientCode` - Get ordonnances
- [ ] `GET /api/ordonnances/:id` - Get by ID
- [ ] `POST /api/ordonnances` - Create ordonnance
- [ ] `PUT /api/ordonnances/:id` - Update ordonnance

---

#### **PAYMENTS (15 endpoints - Most endpoints!)**

- [ ] `GET /api/payments` - Get all payments
- [ ] `GET /api/payments/:id` - Get by ID
- [ ] `GET /api/payments/patient/:patientCode` - Get for patient
- [ ] `GET /api/payments/user/:userId` - Get for user
- [ ] `POST /api/payments` - Create payment
- [ ] `PUT /api/payments/:id` - Update payment
- [ ] `DELETE /api/payments/:id` - Delete payment
- [ ] `POST /api/payments/filter` - Filter payments
- [ ] `GET /api/payments/stats/user/:userId` - User stats
- [ ] `GET /api/payments/stats/date/:date` - Date stats
- [ ] `GET /api/payments/stats/range` - Date range stats
- [ ] `GET /api/payments/morning/:date` - Morning payments
- [ ] `GET /api/payments/afternoon/:date` - Afternoon payments
- [ ] `GET /api/payments/count` - Get count
- [ ] `POST /api/payments/report` - Generate report

---

#### **MEDICATIONS (9 endpoints)**

- [ ] `GET /api/medications` - Get all medications
- [ ] `GET /api/medications/:id` - Get by ID
- [ ] `POST /api/medications` - Create medication
- [ ] `PUT /api/medications/:id` - Update medication
- [ ] `DELETE /api/medications/:id` - Delete medication
- [ ] `POST /api/medications/search` - Search medications
- [ ] `PUT /api/medications/:id/increment-usage` - Increment usage count
- [ ] `GET /api/medications/top-used` - Get most used
- [ ] `GET /api/medications/by-nature/:nature` - Get by nature

---

#### **NURSE PREFERENCES (6 endpoints)**

- [ ] `GET /api/nurse-prefs/:userId` - Get nurse preferences
- [ ] `POST /api/nurse-prefs` - Create/update preferences
- [ ] `PUT /api/nurse-prefs/:userId/active` - Set active
- [ ] `PUT /api/nurse-prefs/:userId/inactive` - Set inactive
- [ ] `GET /api/nurse-prefs/active` - Get active nurses
- [ ] `GET /api/nurse-prefs/room/:roomId` - Get nurses for room

---

#### **APPOINTMENTS (7 endpoints)**

- [ ] `GET /api/appointments` - Get all appointments
- [ ] `GET /api/appointments/:id` - Get by ID
- [ ] `GET /api/appointments/date/:date` - Get for date
- [ ] `POST /api/appointments` - Create appointment
- [ ] `PUT /api/appointments/:id` - Update appointment
- [ ] `DELETE /api/appointments/:id` - Delete appointment
- [ ] `POST /api/appointments/:id/convert` - Convert to patient

---

#### **SURGERY PLANS (6 endpoints)**

- [ ] `GET /api/surgery-plans` - Get all plans
- [ ] `GET /api/surgery-plans/:id` - Get by ID
- [ ] `GET /api/surgery-plans/patient/:patientCode` - Get for patient
- [ ] `GET /api/surgery-plans/date/:date` - Get for date
- [ ] `POST /api/surgery-plans` - Create plan
- [ ] `PUT /api/surgery-plans/:id` - Update plan
- [ ] `DELETE /api/surgery-plans/:id` - Delete plan

---

#### **SYSTEM & EVENTS (5 endpoints)**

- [ ] `GET /api/health` - Health check
- [ ] `GET /api/version` - Get version
- [ ] `GET /api/events` - SSE event stream
- [ ] `GET /api/events/status` - Event status
- [ ] `GET /api/ping` - Ping

---

### 📊 Endpoint Summary

| Category | Count | Status |
|----------|-------|--------|
| Users & Auth | 10 | ⏳ |
| User Templates | 6 | ⏳ |
| Rooms | 5 | ⏳ |
| Patients | 7 | ⏳ |
| Messages | 6 | ⏳ |
| Message Templates | 6 | ⏳ |
| Waiting Queue | 7 | ⏳ |
| Medical Acts | 6 | ⏳ |
| Visits | 8 | ⏳ |
| Ordonnances | 4 | ⏳ |
| Payments | 15 | ⏳ |
| Medications | 9 | ⏳ |
| Nurse Prefs | 6 | ⏳ |
| Appointments | 7 | ⏳ |
| Surgery Plans | 7 | ⏳ |
| System | 5 | ⏳ |
| **TOTAL** | **114** | **0%** |

---

## 🧪 Testing Strategy

### 1. **Manual Testing**
```bash
# Start server
cd medicore_server
docker-compose up

# Test health check
curl http://localhost:50052/api/health

# Test user creation
curl -X POST http://localhost:50052/api/users \
  -H "Content-Type: application/json" \
  -d '{"id":"test1","name":"Test User","role":"Médecin","password":"test123"}'
```

### 2. **Automated Testing**
```bash
# Create test script
cd medicore_server
go test ./internal/api/... -v
```

### 3. **Flutter Integration Testing**
```bash
# Run Flutter app
cd medicore_app
flutter run

# Test each feature manually
# Check console for errors
```

---

## ✅ Success Criteria

- [ ] All 14 entities work correctly
- [ ] All 114 REST endpoints return correct data
- [ ] Real-time events work for all entities
- [ ] No compilation errors
- [ ] No runtime errors
- [ ] All CRUD operations succeed
- [ ] Data persists correctly in PostgreSQL
- [ ] Multi-client sync works
- [ ] Performance is acceptable (<500ms per request)

---

## 📝 Testing Log Template

```markdown
### Entity: [NAME]
**Date:** [DATE]
**Tester:** [NAME]

**Results:**
- ✅ Create: Success
- ✅ Read: Success
- ❌ Update: Failed - [ERROR]
- ✅ Delete: Success
- ✅ List: Success
- ✅ Real-time: Success

**Issues Found:**
1. [Description]
2. [Description]

**Status:** ✅ PASS / ❌ FAIL
```

---

**Next:** Start systematic testing of each entity and endpoint!
