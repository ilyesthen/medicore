# ✅ MediCore Setup Checklist

Print this and check off each step as you complete it!

---

## 🖥️ SERVER PC SETUP

### Prerequisites
- [ ] One Windows PC designated as server
- [ ] PC will stay on 24/7
- [ ] Database file copied to PC: `medicore_database_COMPLETE.sql` (240 MB)

---

### Step 1: Install PostgreSQL
- [ ] Downloaded PostgreSQL 14 from https://www.postgresql.org/download/windows/
- [ ] Ran installer
- [ ] Set password for `postgres` user: _________________ (write it down!)
- [ ] Port set to: 5432
- [ ] Installation completed
- [ ] Tested: `psql -U postgres -c "SELECT version();"`

---

### Step 2: Import Database
- [ ] Copied `medicore_database_COMPLETE.sql` to: `C:\medicore\`
- [ ] Created database: `psql -U postgres -c "CREATE DATABASE medicore_db;"`
- [ ] Imported data: `psql -U postgres -d medicore_db -f medicore_database_COMPLETE.sql`
- [ ] Verified: `psql -U postgres -d medicore_db -c "SELECT COUNT(*) FROM patients;"`
- [ ] Patient count shows: _________ (should be 63,664)

---

### Step 3: Install Go
- [ ] Downloaded Go from https://go.dev/dl/
- [ ] Ran installer
- [ ] Restarted PowerShell
- [ ] Tested: `go version`

---

### Step 4: Build Server
- [ ] Copied `medicore_server` folder to: `C:\medicore\medicore_server`
- [ ] Navigated to folder: `cd C:\medicore\medicore_server`
- [ ] Built server: `go build -o medicore-server.exe .\cmd\server\main.go`
- [ ] File exists: `C:\medicore\medicore_server\medicore-server.exe`

---

### Step 5: Configure Server
- [ ] Created file: `C:\medicore\start_server.bat`
- [ ] Set DB_PASSWORD to match PostgreSQL password
- [ ] Tested server: `C:\medicore\start_server.bat`
- [ ] Server shows: "READY FOR LAN CONNECTIONS"
- [ ] Server IP shown: _____________________ (write it down!)

---

### Step 6: Configure Firewall
- [ ] Ran: `netsh advfirewall firewall add rule name="MediCore Server" dir=in action=allow protocol=TCP localport=50052`
- [ ] Ran: `netsh advfirewall firewall add rule name="MediCore Test Port" dir=in action=allow protocol=TCP localport=50051`

---

### Step 7: Auto-Start on Boot
- [ ] Pressed `Win + R` and typed: `shell:startup`
- [ ] Created shortcut to `C:\medicore\start_server.bat`
- [ ] Shortcut named: "MediCore Server"
- [ ] Tested: Restarted PC and verified server starts automatically

---

### Step 8: Keep PC Awake
- [ ] **Option A:** Set Windows to never sleep (Settings → Power & Sleep)
- [ ] **Option B:** Created `keep_awake.ps1` script and Task Scheduler task

---

### Step 9: Final Server Verification
- [ ] Server running (check console window)
- [ ] Can access: `http://localhost:50052/api/health` (returns `{"status":"ok"}`)
- [ ] Server IP is: _____________________ (same as Step 5)
- [ ] Firewall allows connections
- [ ] Auto-starts on boot
- [ ] PC never sleeps

---

## 💻 CLIENT PC SETUP

### For Each Client Computer:

#### PC 1: ___________________ (write PC name/location)
- [ ] Installed MediCore app
- [ ] Launched app
- [ ] Setup wizard opened
- [ ] Clicked "CLIENT" option
- [ ] Clicked "Scan for Servers"
- [ ] Server found and displayed: _____________________ (server IP)
- [ ] Selected server
- [ ] Connection test successful
- [ ] Logged in with credentials
- [ ] Can see all patients (count: _________)
- [ ] Tested creating/editing patient
- [ ] Tested all main features

#### PC 2: ___________________ (write PC name/location)
- [ ] Installed MediCore app
- [ ] Launched app
- [ ] Setup wizard opened
- [ ] Clicked "CLIENT" option
- [ ] Clicked "Scan for Servers"
- [ ] Server found and displayed: _____________________ (server IP)
- [ ] Selected server
- [ ] Connection test successful
- [ ] Logged in with credentials
- [ ] Can see all patients (count: _________)
- [ ] Tested creating/editing patient
- [ ] Tested all main features

#### PC 3: ___________________ (write PC name/location)
- [ ] Installed MediCore app
- [ ] Launched app
- [ ] Setup wizard opened
- [ ] Clicked "CLIENT" option
- [ ] Clicked "Scan for Servers"
- [ ] Server found and displayed: _____________________ (server IP)
- [ ] Selected server
- [ ] Connection test successful
- [ ] Logged in with credentials
- [ ] Can see all patients (count: _________)
- [ ] Tested creating/editing patient
- [ ] Tested all main features

---

## 🧪 SYSTEM TESTING

### Real-time Sync Test
- [ ] Opened app on 2 different PCs
- [ ] Created patient on PC 1
- [ ] Patient appeared on PC 2 automatically
- [ ] Modified patient on PC 2
- [ ] Changes appeared on PC 1 automatically
- [ ] Real-time sync working! ✅

### All Features Test
- [ ] Patient management (create, edit, search)
- [ ] Visit creation and management
- [ ] Payment recording
- [ ] Appointment scheduling
- [ ] Waiting queue
- [ ] Prescriptions (ordonnances)
- [ ] Medical acts
- [ ] Messaging system
- [ ] User management
- [ ] Reports and statistics

---

## 🚨 TROUBLESHOOTING TESTS

### If Clients Can't Find Server:
- [ ] Verified server is running (check console)
- [ ] Verified both PCs on same network
- [ ] Tested manually: `curl http://[SERVER_IP]:50052/api/health`
- [ ] Checked firewall on server PC
- [ ] Tried manual IP entry in setup wizard

### If Data Not Showing:
- [ ] Verified database: `psql -U postgres -d medicore_db -c "SELECT COUNT(*) FROM patients;"`
- [ ] Checked server logs for errors
- [ ] Restarted server
- [ ] Restarted client app

---

## 📊 FINAL VERIFICATION

### Server PC:
- [ ] PostgreSQL running (check Task Manager)
- [ ] Server running (console shows "READY")
- [ ] Server IP: _____________________ (write it down!)
- [ ] Auto-starts on boot
- [ ] Never sleeps
- [ ] Firewall configured
- [ ] Database has all data (63,664 patients)

### All Client PCs:
- [ ] Can find server automatically
- [ ] Can connect and login
- [ ] See same data on all PCs
- [ ] Real-time sync working
- [ ] All features functional

### Network:
- [ ] All PCs on same network
- [ ] Server reachable from all clients
- [ ] Firewall allows connections
- [ ] No internet exposure (good!)

---

## 📝 IMPORTANT INFORMATION

**Write down and keep safe:**

| Item                    | Value                          |
|-------------------------|--------------------------------|
| Server PC Name          | ______________________________ |
| Server IP Address       | ______________________________ |
| PostgreSQL Password     | ______________________________ |
| Database Location       | C:\medicore\medicore_db        |
| Server Executable       | C:\medicore\medicore_server\medicore-server.exe |
| Startup Script          | C:\medicore\start_server.bat   |
| Number of Patients      | ______________________________ |
| Setup Date              | ______________________________ |

---

## 🎯 SUCCESS CRITERIA

**✅ Setup is complete when:**

1. Server PC:
   - Shows "READY FOR LAN CONNECTIONS" in console
   - Responds to health check
   - Auto-starts on boot
   - Never sleeps

2. All Client PCs:
   - Can scan and find server
   - Can connect and login
   - See all patients
   - Real-time sync works

3. System:
   - All data centralized
   - No sync conflicts
   - Fast and responsive
   - All features working

**If all boxes are checked, you're done! 🎉**

---

## 📞 QUICK REFERENCE

### Check Server Status:
```powershell
curl http://localhost:50052/api/health
```

### Check Database:
```powershell
psql -U postgres -d medicore_db -c "SELECT COUNT(*) FROM patients;"
```

### Restart Server:
1. Close `start_server.bat` window
2. Run: `C:\medicore\start_server.bat`

### Backup Database:
```powershell
pg_dump -U postgres medicore_db > backup_$(Get-Date -Format "yyyyMMdd").sql
```

---

## 📅 MAINTENANCE SCHEDULE

### Daily:
- [ ] Verify server is running
- [ ] Check for any errors in console

### Weekly:
- [ ] Review server logs
- [ ] Check disk space on server PC
- [ ] Verify all clients can connect

### Monthly:
- [ ] Create database backup
- [ ] Test backup restoration
- [ ] Update server if needed
- [ ] Check for app updates

---

**Keep this checklist for reference!**

**Date Completed:** ___________________

**Completed By:** ___________________

**Notes:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
