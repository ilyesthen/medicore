# 🚀 MEDICORE PRODUCTION DEPLOYMENT GUIDE

## 📋 SUMMARY

**Database File Location:** `/Applications/eye/medicore_database_COMPLETE.sql` (240MB)  
**GitHub:** Pushed ✅ (without database - it's local only)  
**Windows Build:** Will happen automatically via GitHub Actions

---

## ✅ WHAT'S DONE

1. ✅ **Database exported** with ALL your data (240MB SQL file)
2. ✅ **All local database code removed** (7600+ lines deleted)
3. ✅ **All repositories use REMOTE ONLY** - NO local database
4. ✅ **REST API converted to PostgreSQL** (114 endpoints)
5. ✅ **App auto-discovers server** in setup wizard
6. ✅ **Code pushed to GitHub** (Windows build will start)

---

## 🖥️ SERVER SETUP (On ONE PC in your clinic)

### Step 1: Install PostgreSQL 14

**On Windows:**
1. Download: https://www.postgresql.org/download/windows/
2. Run installer
3. Set password for `postgres` user (remember it!)
4. Port: 5432 (default)
5. Finish installation

### Step 2: Import Your Database

```powershell
# Open PowerShell as Administrator

# Navigate to where you copied the SQL file
cd C:\Path\To\Database

# Import the database (will take 2-5 minutes)
psql -U postgres -c "CREATE DATABASE medicore_db;"
psql -U postgres -d medicore_db -f medicore_database_COMPLETE.sql

# Verify import
psql -U postgres -d medicore_db -c "SELECT COUNT(*) FROM patients;"
# Should show: 63664
```

### Step 3: Build the Go Server

```powershell
# Install Go: https://go.dev/dl/

# Clone the repo or copy medicore_server folder to the PC

cd medicore_server
go build -o medicore-server.exe .\cmd\server\main.go
```

### Step 4: Configure Server Auto-Start

Create file: `C:\medicore\start_server.bat`

```batch
@echo off
SET DB_HOST=localhost
SET DB_PORT=5432
SET DB_USER=postgres
SET DB_PASSWORD=your_postgres_password
SET DB_NAME=medicore_db
SET DB_SSLMODE=disable
SET SERVER_PORT=50052

cd C:\medicore\medicore_server
medicore-server.exe

pause
```

**Make it run on startup:**
1. Press `Win + R`
2. Type: `shell:startup`
3. Create shortcut to `start_server.bat` in the startup folder
4. Done! Server starts when PC boots

### Step 5: Keep PC Awake

**Option A: Windows Settings**
1. Settings → System → Power & Sleep
2. Set "When plugged in, PC goes to sleep after" → Never
3. Set "When plugged in, turn off screen after" → Never

**Option B: PowerShell (Better)**
Create `C:\medicore\keep_awake.ps1`:

```powershell
# Keep PC awake forever
$myshell = New-Object -com "Wscript.Shell"
while ($true) {
    $myshell.sendkeys("{SCROLLLOCK}")
    Start-Sleep -Seconds 60
    $myshell.sendkeys("{SCROLLLOCK}")
    Start-Sleep -Seconds 60
}
```

Run at startup (add to Task Scheduler):
```powershell
# Task Scheduler → Create Basic Task
# Name: Keep PC Awake
# Trigger: At startup
# Action: Start a program
# Program: powershell.exe
# Arguments: -File "C:\medicore\keep_awake.ps1"
```

### Step 6: Configure Firewall

```powershell
# Allow incoming connections on port 50052
netsh advfirewall firewall add rule name="MediCore Server" dir=in action=allow protocol=TCP localport=50052
```

---

## 💻 CLIENT PCS SETUP

### When Windows Installer is Ready

1. **Download** `MediCore-Setup.exe` from GitHub Releases
2. **Install** on each client PC
3. **Launch** MediCore
4. **Setup Wizard:**
   - Automatically scans network
   - Shows your server
   - Click to select
   - Test connection
   - Login
5. **Done!** App connects to server

---

## 📂 FILE LOCATIONS

### Your Database File (Upload this to server PC):
```
/Applications/eye/medicore_database_COMPLETE.sql
```
**Size:** 240 MB  
**Contains:** 63,664 patients + all data

### Server Files (Copy to server PC):
```
/Applications/eye/medicore_server/
├── cmd/server/main.go
├── internal/
├── database/
└── scripts/
```

### Client App (GitHub will build):
```
Will be at: GitHub → Actions → Windows Build → Artifacts
Download: MediCore-Setup.exe
```

---

## ✅ VERIFICATION CHECKLIST

### Server PC:
- [ ] PostgreSQL 14 installed
- [ ] Database imported (medicore_database_COMPLETE.sql)
- [ ] Go server built (medicore-server.exe)
- [ ] Server auto-starts on boot
- [ ] PC never sleeps
- [ ] Firewall allows port 50052
- [ ] Can access: `http://localhost:50052/api/health`

### Client PCs:
- [ ] MediCore app installed
- [ ] Setup wizard shows server
- [ ] Can connect to server
- [ ] Can login
- [ ] Can see all 63K+ patients
- [ ] All features work

---

## 🔍 HOW AUTO-DISCOVERY WORKS

The setup wizard:
1. Broadcasts UDP packet on local network
2. Server responds with its IP
3. Wizard displays found servers
4. User clicks to select
5. App tests connection
6. If successful, saves configuration
7. Done!

**No manual IP entry needed!**

---

## 🚨 TROUBLESHOOTING

### Server Won't Start

**Check PostgreSQL:**
```powershell
# Check if running
psql -U postgres -c "SELECT version();"
```

**Check server logs:**
```powershell
# Server prints to console
# Look for errors in start_server.bat window
```

### Clients Can't Find Server

**Test server manually:**
```powershell
# On client PC
curl http://SERVER_IP:50052/api/health
# Should return: {"status":"ok"}
```

**If doesn't work:**
1. Check firewall on server PC
2. Verify server is running
3. Verify network connectivity
4. Try manual IP entry in setup wizard

### Data Not Showing

**Verify database:**
```powershell
psql -U postgres -d medicore_db -c "
SELECT 
  (SELECT COUNT(*) FROM patients) as patients,
  (SELECT COUNT(*) FROM visits) as visits;
"
```

---

## 📊 WHAT'S IN THE APP NOW

### ✅ ALL Repositories Use Remote (Server):

- `RemoteUsersRepository` ✅
- `RemotePatientsRepository` ✅
- `RemoteRoomsRepository` ✅
- `RemoteMessagesRepository` ✅
- `RemoteMessageTemplatesRepository` ✅
- `RemoteMedicalActsRepository` ✅
- `RemoteVisitsRepository` ✅
- `RemoteOrdonnancesRepository` ✅
- `RemoteMedicationsRepository` ✅
- `RemotePaymentsRepository` ✅
- `RemoteWaitingQueueRepository` ✅
- `RemoteAppointmentsRepository` ✅
- `RemoteSurgeryPlansRepository` ✅
- `RemoteNursePreferencesRepository` ✅

### ❌ NO Local Database Code:

- ✅ Deleted `app_database.dart`
- ✅ Deleted all table definitions
- ✅ Deleted all local repositories
- ✅ Deleted `grpc_server_launcher.dart`
- ✅ Deleted `admin_broadcast_service.dart`
- ✅ Removed Drift dependencies
- ✅ Removed SQLite dependencies

### 🎯 Result:

**EVERY function, EVERY feature, EVERY operation uses the server!**

---

## 🔐 SECURITY NOTES

### Database Password:
Currently: `medicore_secure_2025`  
**Change this in production!**

Update in `start_server.bat`:
```batch
SET DB_PASSWORD=your_new_secure_password
```

### Network Security:
- Server only accessible on local clinic network
- Not exposed to internet (good!)
- Use VPN for remote access if needed

---

## 🎯 FINAL CHECKLIST

### Before Going Live:

- [ ] Database file copied to server PC
- [ ] PostgreSQL installed and database imported
- [ ] Server built and tested
- [ ] Server auto-starts configured
- [ ] PC set to never sleep
- [ ] Firewall configured
- [ ] Test with one client PC first
- [ ] Verify all features work
- [ ] Then deploy to all client PCs

### After Going Live:

- [ ] Monitor server for first few days
- [ ] Check logs for errors
- [ ] Verify all users can connect
- [ ] Test all features (patients, visits, payments, etc.)
- [ ] Setup automated backups (recommended)

---

## 📞 QUICK COMMANDS

### Check if server is running:
```powershell
curl http://localhost:50052/api/health
```

### Check database:
```powershell
psql -U postgres -d medicore_db -c "SELECT COUNT(*) FROM patients;"
```

### Restart server:
```powershell
# Close start_server.bat window
# Run it again
```

### Backup database:
```powershell
pg_dump -U postgres medicore_db > backup_$(date +%Y%m%d).sql
```

---

## ✅ SUCCESS!

**Your database:** `/Applications/eye/medicore_database_COMPLETE.sql`  
**Your code:** Pushed to GitHub ✅  
**Windows build:** Will be created automatically by GitHub Actions  

**Next:** 
1. Copy database file to server PC
2. Import it
3. Start server
4. Install app on clients
5. Done!

**Everything uses the server - ZERO local database code remaining!** 🎉
