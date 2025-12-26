# 🏗️ MediCore Architecture Overview

## 📊 System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        YOUR CLINIC NETWORK                       │
│                         (192.168.1.x)                           │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                      SERVER PC (Always On)                       │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  PostgreSQL Database (Port 5432)                       │    │
│  │  ┌──────────────────────────────────────────────┐     │    │
│  │  │  medicore_db                                 │     │    │
│  │  │  • 63,664 patients                           │     │    │
│  │  │  • All visits, payments, appointments        │     │    │
│  │  │  • All medical records                       │     │    │
│  │  │  • Size: 240 MB                              │     │    │
│  │  └──────────────────────────────────────────────┘     │    │
│  └────────────────────────────────────────────────────────┘    │
│                            ↕                                     │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Go Server (medicore-server.exe)                       │    │
│  │  • REST API (Port 50052)                               │    │
│  │  • Real-time sync via SSE                              │    │
│  │  • Auto-discovery (Port 50051)                         │    │
│  │  • 114 API endpoints                                   │    │
│  └────────────────────────────────────────────────────────┘    │
│                            ↕                                     │
│                    Network (LAN)                                │
└──────────────────────────────────────────────────────────────────┘
                             ↕
        ┌────────────────────┼────────────────────┐
        ↓                    ↓                    ↓
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  CLIENT PC 1  │    │  CLIENT PC 2  │    │  CLIENT PC 3  │
│               │    │               │    │               │
│  MediCore App │    │  MediCore App │    │  MediCore App │
│               │    │               │    │               │
│  • Reception  │    │  • Doctor     │    │  • Nurse      │
│  • Payments   │    │  • Consults   │    │  • Queue      │
│               │    │               │    │               │
└───────────────┘    └───────────────┘    └───────────────┘
```

---

## 🔄 How It Works

### 1. Server PC Setup
```
Server PC
├── PostgreSQL Database
│   └── Stores ALL data (patients, visits, etc.)
├── Go Server
│   ├── Provides REST API
│   ├── Handles all database operations
│   └── Broadcasts presence on network
└── Auto-starts on boot
```

### 2. Client PC Setup
```
Client PC
├── MediCore App (Flutter)
│   ├── Setup Wizard (first launch)
│   │   ├── Scans network for servers
│   │   ├── Shows available servers
│   │   └── Connects automatically
│   └── Normal Operation
│       ├── Sends requests to server
│       ├── Receives real-time updates
│       └── No local database
```

### 3. Data Flow

```
User Action on Client PC:
  ↓
[MediCore App]
  ↓ (HTTP Request)
[Go Server on Server PC]
  ↓ (SQL Query)
[PostgreSQL Database]
  ↓ (Data)
[Go Server]
  ↓ (HTTP Response)
[MediCore App]
  ↓
Display to User

Real-time Updates:
[Change on ANY Client]
  ↓
[Server broadcasts via SSE]
  ↓
[ALL Clients receive update]
  ↓
[UI updates automatically]
```

---

## 🌐 Network Discovery

### How Clients Find the Server Automatically

```
Step 1: Client App Starts
  ↓
Step 2: Setup Wizard Opens
  ↓
Step 3: User Clicks "Scan for Servers"
  ↓
Step 4: App Broadcasts UDP Packet
  ↓ (Network broadcast to 255.255.255.255)
Step 5: Server Receives Broadcast
  ↓
Step 6: Server Responds with IP Address
  ↓ (192.168.1.XXX)
Step 7: Client Receives Response
  ↓
Step 8: Client Tests Connection (Port 50051)
  ↓
Step 9: Connection Successful
  ↓
Step 10: Client Saves Configuration
  ↓
Step 11: Client Connects to REST API (Port 50052)
  ↓
DONE! ✅
```

---

## 📡 Ports Used

| Port  | Protocol | Purpose                          |
|-------|----------|----------------------------------|
| 5432  | TCP      | PostgreSQL Database              |
| 50051 | TCP      | Server Discovery / Test Port     |
| 50052 | TCP      | REST API & Real-time Sync (SSE)  |

---

## 💾 Data Storage

### Server PC
```
C:\medicore\
├── medicore_database_COMPLETE.sql  (Your database file - 240MB)
├── medicore_server\                (Server code)
│   ├── medicore-server.exe         (Compiled server)
│   └── ...
└── start_server.bat                (Startup script)
```

### PostgreSQL Database
```
medicore_db (Database)
├── patients         (63,664 rows)
├── visits           (XXX rows)
├── payments         (XXX rows)
├── appointments     (XXX rows)
├── users            (XX rows)
├── rooms            (XX rows)
├── messages         (XXX rows)
├── ordonnances      (XXX rows)
├── medications      (XXX rows)
├── medical_acts     (XXX rows)
├── waiting_queue    (XXX rows)
├── surgery_plans    (XXX rows)
└── ... (18 tables total)
```

### Client PC
```
C:\Users\[Username]\AppData\Local\MediCore\
├── medicore_config.txt  (Server IP, mode)
└── (No database - everything is remote!)
```

---

## 🔐 Security Model

```
┌─────────────────────────────────────────┐
│         Internet (No Access)            │
└─────────────────────────────────────────┘
                   ↕ (Blocked)
┌─────────────────────────────────────────┐
│      Router / Firewall                  │
└─────────────────────────────────────────┘
                   ↕ (Allowed)
┌─────────────────────────────────────────┐
│      Local Clinic Network (LAN)         │
│                                         │
│  ┌────────┐  ┌────────┐  ┌────────┐   │
│  │Server  │  │Client 1│  │Client 2│   │
│  │  PC    │←→│   PC   │←→│   PC   │   │
│  └────────┘  └────────┘  └────────┘   │
│                                         │
│  All communication stays INSIDE LAN    │
│  No internet exposure                  │
└─────────────────────────────────────────┘
```

**Security Features:**
- ✅ Server only accessible on local network
- ✅ No internet exposure
- ✅ Password-protected database
- ✅ Firewall rules restrict access
- ✅ All data stays in your clinic

---

## 🚀 Startup Sequence

### Server PC Boot
```
1. Windows Starts
   ↓
2. Startup Folder Runs
   ↓
3. start_server.bat Executes
   ↓
4. PostgreSQL Starts (if not running)
   ↓
5. Go Server Starts
   ↓
6. Server Connects to Database
   ↓
7. Server Listens on Ports 50051 & 50052
   ↓
8. Server Broadcasts Presence
   ↓
9. READY! ✅
```

### Client PC Launch
```
1. User Launches MediCore
   ↓
2. App Checks Configuration
   ↓
3a. First Time:              3b. Already Configured:
    Setup Wizard Opens            Connects to Server
    ↓                             ↓
    User Scans Network            Loads Data
    ↓                             ↓
    Selects Server                Shows Dashboard
    ↓                             ↓
    Tests Connection              READY! ✅
    ↓
    Saves Config
    ↓
    Connects to Server
    ↓
    READY! ✅
```

---

## 📊 API Architecture

### REST API Endpoints (114 total)

```
/api/health                    → Server status
/api/patients                  → Patient operations
/api/visits                    → Visit management
/api/payments                  → Payment tracking
/api/appointments              → Appointment scheduling
/api/users                     → User management
/api/rooms                     → Room management
/api/messages                  → Messaging system
/api/ordonnances              → Prescriptions
/api/medications              → Medication database
/api/medical-acts             → Medical procedures
/api/waiting-queue            → Queue management
/api/surgery-plans            → Surgery planning
/api/events                   → Real-time updates (SSE)
... (and more)
```

### Real-time Sync (Server-Sent Events)

```
Client connects to: /api/events
  ↓
Server sends updates when data changes:
  • patient_updated
  • visit_created
  • payment_added
  • appointment_modified
  • queue_changed
  ↓
Client receives event
  ↓
Client updates UI automatically
```

---

## 🎯 Comparison: Before vs After

### BEFORE (Old Architecture)
```
Each PC:
├── MediCore App
├── Local SQLite Database
├── gRPC Server (if admin)
└── Manual sync required

Problems:
❌ Data fragmentation
❌ Sync conflicts
❌ Complex setup
❌ Hard to maintain
```

### AFTER (New Architecture)
```
Server PC:
├── PostgreSQL Database (centralized)
└── Go Server

Client PCs:
└── MediCore App (no database)

Benefits:
✅ Single source of truth
✅ Real-time sync
✅ Easy setup (auto-discovery)
✅ Scalable
✅ Professional
```

---

## 📈 Scalability

### Current Setup
- 1 Server PC
- 3-10 Client PCs
- 63,664 patients
- Works perfectly!

### Can Scale To
- 1 Server PC (same)
- 50+ Client PCs
- 500,000+ patients
- Just add more RAM/CPU to server

### Performance
- PostgreSQL handles millions of records
- Connection pooling (50 connections)
- Optimized queries
- Real-time updates
- Fast response times

---

## 🔧 Maintenance

### Daily
- ✅ Server PC stays on
- ✅ Automatic operation
- ✅ No manual intervention needed

### Weekly
- Check server logs
- Monitor disk space
- Verify backups

### Monthly
- Database backup
- Update server if needed
- Check for updates

---

## ✅ Success Indicators

**You know it's working when:**

1. **Server PC:**
   - Shows "READY FOR LAN CONNECTIONS" in console
   - Responds to `http://localhost:50052/api/health`
   - PostgreSQL running (check Task Manager)

2. **Client PCs:**
   - Setup wizard finds server automatically
   - Can login and see all data
   - Changes sync in real-time
   - All features work

3. **Network:**
   - All PCs on same network
   - Firewall allows connections
   - Server IP visible to clients

**Everything centralized, everything synchronized, everything automatic!** 🎉
