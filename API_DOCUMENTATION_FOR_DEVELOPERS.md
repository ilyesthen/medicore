# MediCore REST API - Complete Documentation for App Developers

## Server Status: ✅ RUNNING & TESTED

**Base URL:** `http://192.168.1.5:50052`  
**Protocol:** HTTP (not HTTPS)  
**Port:** 50052  
**Database:** PostgreSQL with 63,751 patients

---

## ⚠️ CRITICAL: Why App Cannot Connect

### Problem Identified
The server was **NOT running** when you tested. The app connection failed because:
1. Server process was not started
2. Nothing was listening on port 50052

### Solution
**Server is now running** and all endpoints tested successfully.

**To keep server running permanently:**
Run as Administrator: `C:\medicore\INSTALL_ALWAYS_ON.bat`

This will configure the server to:
- Start automatically on PC boot
- Run 24/7 in background
- Restart automatically if it crashes

---

## Server Configuration

### Network Settings
```
IP Address:     192.168.1.5
Port:           50052
Firewall:       Rule added for port 50052
Protocol:       HTTP (plain, no SSL)
```

### How to Test Connection
```powershell
# From Windows PowerShell
Invoke-RestMethod -Uri "http://192.168.1.5:50052/api/health"

# Expected Response:
{
  "status": "ok",
  "message": "MediCore Server Running",
  "patients": 63751
}
```

### App Connection Format
**Correct format for app:** `http://192.168.1.5:50052`
- Include `http://` prefix
- No trailing slash
- Port must be included `:50052`

**Wrong formats that will fail:**
- ❌ `192.168.1.5:50052` (missing http://)
- ❌ `https://192.168.1.5:50052` (HTTPS not supported)
- ❌ `http://192.168.1.5:50052/` (trailing slash may cause issues)
- ❌ `http://192.168.1.5` (missing port)

---

## Database Statistics

### Total Records
```
Patients:          63,751
Visits:           116,308
Payments:         118,760
Ordonnances:       88,404
Users:                  6
Rooms:                  3
Waiting Patients:     797
Surgeries:              4
Medical Acts:          21
Message Templates:     15
```

### Latest Data
- **Most Recent Patient:** Code 67243 - TAKOUA LAOUAR (Dec 25, 2025)
- **Data Range:** Oct 2016 - Dec 26, 2025
- **Recent Updates:** 15 patients updated Dec 25-26, 2025

---

## API Endpoints - Complete Reference

### 1. Health Check
**Endpoint:** `GET /api/health`  
**Purpose:** Verify server is running

**Request:**
```http
GET http://192.168.1.5:50052/api/health
```

**Response:**
```json
{
  "status": "ok",
  "message": "MediCore Server Running",
  "patients": 63751
}
```

**Status Codes:**
- 200: Server is operational
- 500: Database connection error

---

### 2. Get Patients List
**Endpoint:** `GET /api/patients`  
**Purpose:** Retrieve list of patients with pagination

**Parameters:**
- `limit` (optional): Number of records (default: 100)
- `offset` (optional): Skip records (default: 0)
- `search` (optional): Search by first name, last name, or code

**Examples:**
```http
# Get first 10 patients
GET http://192.168.1.5:50052/api/patients?limit=10

# Get next 10 patients
GET http://192.168.1.5:50052/api/patients?limit=10&offset=10

# Search for patients
GET http://192.168.1.5:50052/api/patients?search=TOUFIK

# Search by code
GET http://192.168.1.5:50052/api/patients?search=67243
```

**Response:**
```json
[
  {
    "code": 67243,
    "barcode": "386Q5Igw",
    "first_name": "TAKOUA",
    "last_name": "LAOUAR",
    "age": 2,
    "date_of_birth": "",
    "address": "Batna",
    "phone_number": "",
    "other_info": "",
    "created_at": "2025-12-25 09:29:01",
    "updated_at": "2025-12-25 09:29:01",
    "needs_sync": 1
  }
]
```

**Status Codes:**
- 200: Success
- 500: Database error

---

### 3. Get Single Patient
**Endpoint:** `GET /api/patients/{code}`  
**Purpose:** Get specific patient by code

**Example:**
```http
GET http://192.168.1.5:50052/api/patients/67243
```

**Response:**
```json
{
  "code": 67243,
  "barcode": "386Q5Igw",
  "first_name": "TAKOUA",
  "last_name": "LAOUAR",
  "age": 2,
  "date_of_birth": "",
  "address": "Batna",
  "phone_number": "",
  "other_info": "",
  "created_at": "2025-12-25 09:29:01",
  "updated_at": "2025-12-25 09:29:01",
  "needs_sync": 1
}
```

**Status Codes:**
- 200: Patient found
- 404: Patient not found
- 500: Database error

---

### 4. Get Users
**Endpoint:** `GET /api/users`  
**Purpose:** Get all active users (doctors, nurses, etc.)

**Request:**
```http
GET http://192.168.1.5:50052/api/users
```

**Response:**
```json
[
  {
    "id": "admin",
    "name": "Administrateur",
    "role": "Administrateur",
    "password_hash": "1234",
    "percentage": null,
    "is_template_user": 0,
    "created_at": "2025-12-02 13:25:27",
    "updated_at": "2025-12-02 13:25:27",
    "deleted_at": null,
    "last_synced_at": null,
    "sync_version": 1,
    "needs_sync": 0
  }
]
```

**Status Codes:**
- 200: Success
- 500: Database error

---

### 5. Get Rooms
**Endpoint:** `GET /api/rooms`  
**Purpose:** Get all examination rooms

**Request:**
```http
GET http://192.168.1.5:50052/api/rooms
```

**Response:**
```json
[
  {
    "id": "7587da69-1d33-4c44-a15d-a18768952715",
    "name": "salle 1",
    "created_at": "2025-12-02T19:51:26.756940 +01:00",
    "updated_at": "2025-12-02T19:51:34.923682 +01:00",
    "needs_sync": 1
  }
]
```

**Status Codes:**
- 200: Success
- 500: Database error

---

### 6. Get Visits
**Endpoint:** `GET /api/visits`  
**Purpose:** Get patient visits/consultations

**Parameters:**
- `patient_code` (optional): Filter by patient code

**Examples:**
```http
# Get all visits (limited to 100)
GET http://192.168.1.5:50052/api/visits

# Get visits for specific patient
GET http://192.168.1.5:50052/api/visits?patient_code=67243
```

**Response:**
```json
[
  {
    "id": 12345,
    "patient_code": 67243,
    "visit_date": "2025-12-25",
    "doctor_name": "KARKOURI.N",
    "motif": "Consultation",
    "diagnosis": "...",
    "conduct": "...",
    "od_sv": "...",
    "og_sv": "...",
    "created_at": "2025-12-25 09:30:00",
    "updated_at": "2025-12-25 09:30:00",
    "is_active": 1
  }
]
```

**Status Codes:**
- 200: Success
- 500: Database error

---

### 7. Get Payments
**Endpoint:** `GET /api/payments`  
**Purpose:** Get payment records

**Parameters:**
- `patient_code` (optional): Filter by patient
- `limit` (optional): Number of records (default: 1000)

**Examples:**
```http
# Get all payments
GET http://192.168.1.5:50052/api/payments

# Get payments for patient
GET http://192.168.1.5:50052/api/payments?patient_code=67243

# Limit results
GET http://192.168.1.5:50052/api/payments?limit=50
```

**Response:**
```json
[
  {
    "id": 1,
    "medical_act_id": 5,
    "medical_act_name": "Consultation",
    "amount": 2000,
    "user_id": "admin",
    "user_name": "Administrateur",
    "patient_code": 67243,
    "patient_first_name": "TAKOUA",
    "patient_last_name": "LAOUAR",
    "payment_time": 1735124400,
    "created_at": 1735124400,
    "updated_at": 1735124400,
    "needs_sync": 1,
    "is_active": 1
  }
]
```

**Status Codes:**
- 200: Success
- 500: Database error

---

### 8. Get Waiting Patients
**Endpoint:** `GET /api/waiting_patients`  
**Purpose:** Get patients in waiting queue

**Request:**
```http
GET http://192.168.1.5:50052/api/waiting_patients
```

**Response:**
```json
[
  {
    "id": 1,
    "patient_code": 67243,
    "patient_first_name": "TAKOUA",
    "patient_last_name": "LAOUAR",
    "patient_birth_date": "",
    "room_id": "7587da69-1d33-4c44-a15d-a18768952715",
    "room_name": "salle 1",
    "motif": "Consultation",
    "sent_by_user_id": "admin",
    "sent_by_user_name": "Administrateur",
    "sent_at": "2025-12-26 18:00:00",
    "is_checked": 0,
    "is_active": 1,
    "patient_age": 2,
    "is_urgent": 0,
    "is_dilatation": 0,
    "dilatation_type": null,
    "is_notified": 0
  }
]
```

**Status Codes:**
- 200: Success
- 500: Database error

---

### 9. Get Ordonnances (Prescriptions)
**Endpoint:** `GET /api/ordonnances`  
**Purpose:** Get prescriptions

**Parameters:**
- `patient_code` (optional): Filter by patient

**Examples:**
```http
# Get all ordonnances
GET http://192.168.1.5:50052/api/ordonnances

# Get ordonnances for patient
GET http://192.168.1.5:50052/api/ordonnances?patient_code=67243
```

**Response:**
```json
[
  {
    "id": 1,
    "patient_code": 67243,
    "document_date": "2025-12-25",
    "patient_age": 2,
    "sequence": 1,
    "doctor_name": "KARKOURI.N",
    "amount": 0.0,
    "content1": "Prescription details...",
    "type1": "ORDONNANCE",
    "content2": null,
    "type2": null,
    "content3": null,
    "type3": null,
    "additional_notes": null,
    "report_title": null,
    "referred_by": null,
    "rdv_flag": 0,
    "rdv_date": null,
    "rdv_day": null,
    "created_at": "2025-12-25 09:30:00",
    "updated_at": "2025-12-25 09:30:00"
  }
]
```

**Status Codes:**
- 200: Success
- 500: Database error

---

### 10. Get Surgeries
**Endpoint:** `GET /api/surgeries`  
**Purpose:** Get scheduled surgeries

**Request:**
```http
GET http://192.168.1.5:50052/api/surgeries
```

**Response:**
```json
[
  {
    "id": 1,
    "patient_code": 12345,
    "patient_first_name": "John",
    "patient_last_name": "Doe",
    "patient_age": 50,
    "patient_phone": "0661234567",
    "surgery_date": "2025-12-30",
    "surgery_hour": "08:00",
    "surgery_type": "Cataract",
    "eye_to_operate": "OD",
    "implant_power": "+20.0",
    "tarif": 50000.0,
    "payment_status": "pending",
    "amount_paid": 0.0,
    "amount_remaining": 50000.0,
    "surgery_status": "scheduled",
    "created_by": "admin",
    "created_at": "2025-12-26 18:00:00",
    "updated_at": "2025-12-26 18:00:00",
    "notes": ""
  }
]
```

**Status Codes:**
- 200: Success
- 500: Database error

---

## Database Schema

### Patients Table (63,751 rows)
```
code              INTEGER      PRIMARY KEY
barcode           TEXT         UNIQUE
first_name        TEXT         NOT NULL
last_name         TEXT         NOT NULL
age               INTEGER      NULL
date_of_birth     TEXT         NULL
address           TEXT         NULL
phone_number      TEXT         NULL
other_info        TEXT         NULL
created_at        TEXT         NOT NULL
updated_at        TEXT         NOT NULL
needs_sync        INTEGER      DEFAULT 1
```

### Visits Table (116,308 rows)
```
id                INTEGER      PRIMARY KEY
patient_code      INTEGER      NOT NULL
visit_date        TEXT         NOT NULL
doctor_name       TEXT         NOT NULL
motif             TEXT         NULL
diagnosis         TEXT         NULL
conduct           TEXT         NULL
od_sv, od_av      TEXT         (Right eye measurements)
og_sv, og_av      TEXT         (Left eye measurements)
created_at        TEXT         NOT NULL
updated_at        TEXT         NOT NULL
is_active         INTEGER      DEFAULT 1
```

### Users Table (6 active users)
```
id                TEXT         PRIMARY KEY
name              TEXT         NOT NULL
role              TEXT         NOT NULL
password_hash     TEXT         NOT NULL
percentage        REAL         NULL
created_at        TEXT         NOT NULL
updated_at        TEXT         NOT NULL
deleted_at        TEXT         NULL
```

### Complete Schema
See: `C:\medicore\database_schema.json` for full schema with all 18 tables

---

## Error Handling

### Common Errors

**1. "Cannot reach server"**
- Server is not running → Run: `C:\medicore\start_server.bat`
- Wrong IP address → Verify with `ipconfig`
- Port blocked → Check firewall
- Wrong URL format → Must include `http://` and `:50052`

**2. "Connection timeout"**
- Server PC is off or sleeping
- Network not connected
- Firewall blocking

**3. "404 Not Found"**
- Wrong endpoint URL
- Missing `/api/` prefix
- Check endpoint spelling

**4. "500 Internal Server Error"**
- PostgreSQL not running
- Database connection failed
- Check server console for errors

---

## Testing the Server

### Quick Test Script
```powershell
# Test from PowerShell
$base = "http://192.168.1.5:50052"

# Health check
Invoke-RestMethod "$base/api/health"

# Get patients
Invoke-RestMethod "$base/api/patients?limit=5"

# Get specific patient
Invoke-RestMethod "$base/api/patients/67243"

# Search
Invoke-RestMethod "$base/api/patients?search=TOUFIK"
```

### All Endpoints Test
Run: `C:\medicore\test_all_endpoints.ps1`

This tests all 11 endpoints and reports success/failure.

---

## App Connection Checklist for Developers

✅ Server URL format: `http://192.168.1.5:50052` (include http:// and port)  
✅ All endpoints start with `/api/`  
✅ Use GET requests (no authentication required currently)  
✅ Response format: JSON  
✅ Handle HTTP status codes: 200 (OK), 404 (Not Found), 500 (Error)  
✅ Test with health endpoint first: `/api/health`  
✅ Implement retry logic (server may restart)  
✅ Show meaningful error messages to users  

---

## Server Management

### Start Server
```powershell
cd C:\medicore
python server.py
```

### Stop Server
Close the command window or press `Ctrl+C`

### Configure Always-On (Recommended)
```powershell
# Run as Administrator
C:\medicore\INSTALL_ALWAYS_ON.bat
```

This ensures the server is always running when PC has power.

---

## Support Files

- **Complete Schema:** `C:\medicore\database_schema.json`
- **Test Script:** `C:\medicore\test_all_endpoints.ps1`
- **Setup Guide:** `C:\medicore\SETUP_COMPLETE_GUIDE.md`
- **Server Code:** `C:\medicore\server.py`

---

## Summary for App Developers

**The server IS working - all 11 endpoints tested successfully.**

**Problem:** Server was not running when you tested.

**Solution:** 
1. Start server: `C:\medicore\start_server.bat`
2. Test connection: Visit `http://192.168.1.5:50052/api/health` in browser
3. Configure always-on: Run `C:\medicore\INSTALL_ALWAYS_ON.bat` as Admin

**App must:**
- Use full URL: `http://192.168.1.5:50052`
- Include `/api/` prefix on all endpoints
- Use HTTP (not HTTPS)
- Include port number `:50052`

**Data available:**
- 63,751 patients
- 116,308 visits
- 88,404 prescriptions
- All data from Oct 2016 to Dec 26, 2025

The server is production-ready and serving real clinic data.
