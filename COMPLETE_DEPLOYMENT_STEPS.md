# 🎯 COMPLETE DEPLOYMENT - STEP BY STEP

**Your Situation:** 
- You have 1 PC that will be the SERVER (currently this Mac)
- Multiple client PCs will connect to it
- Your production database: `/Applications/eye/medicore.db` (90MB, 63K+ patients)

---

## 📋 STEP-BY-STEP GUIDE

### ✅ PART 1: SET UP SERVER (On This Mac - 10 minutes)

#### Step 1.1: Install PostgreSQL
```bash
cd /Applications/eye
./INSTALL_SERVER.sh
```

**What this does:**
- Installs PostgreSQL 14 via Homebrew
- Creates `medicore_db` database  
- Creates `medicore` user with password `medicore_secure_2025`
- Applies database schema (18 tables)

**Expected Output:**
```
✅ PostgreSQL installed and configured
✅ Database schema created
```

---

#### Step 1.2: Migrate Your Data
```bash
cd /Applications/eye
./MIGRATE_DATA.sh
```

**What this does:**
- Reads `/Applications/eye/medicore.db` (your SQLite database)
- Imports ALL data to PostgreSQL:
  - 63,664 patients
  - 119,349 visits
  - 88,231 ordonnances
  - 118,550 payments
  - All other tables

**Expected Output:**
```
✅ patients: 63664 rows migrated
✅ visits: 119349 rows migrated  
✅ ordonnances: 88231 rows migrated
✅ payments: 118550 rows migrated
...
✅ Migration completed successfully!
```

**Time:** 2-5 minutes

---

#### Step 1.3: Setup Auto-Start
```bash
cd /Applications/eye
./SETUP_AUTO_START.sh
```

**What this does:**
- Builds the Go server binary
- Configures macOS to start server automatically when Mac boots
- Starts the server immediately

**Expected Output:**
```
✅ Auto-Start Configured!
The MediCore server will now:
  ✓ Start automatically when this Mac boots
  ✓ Restart automatically if it crashes
  ✓ Keep running in the background
```

---

#### Step 1.4: Verify Server is Running
```bash
# Check if server is running
launchctl list | grep medicore

# Should output:
# 12345  0  com.medicore.server

# Test health endpoint
curl http://localhost:50052/api/health

# Should return:
# {"status":"ok"}
```

**Get Your Server IP:**
```bash
ipconfig getifaddr en0
# Example output: 192.168.1.100
```

**Write this down! Your clients will need it.**

---

### ✅ PART 2: PREPARE CLIENT APP (Windows Installer)

Since there are some minor compilation errors to fix, here's what to do:

#### Option A: Fix and Build Yourself

1. **Fix the compilation errors:**
   ```bash
   cd /Applications/eye/medicore_app
   
   # The main issue is Message type conflicts
   # I'll create a quick fix...
   ```

2. **Build for Windows:**
   ```bash
   flutter build windows --release
   ```

3. **Create installer** (using Inno Setup - I'll provide the script)

#### Option B: Use GitHub Actions (Easier!)

I'll create a GitHub Actions workflow that builds the Windows installer automatically.

---

### ✅ PART 3: DEPLOY TO CLIENT PCS

Once you have the Windows installer:

1. **Copy installer to client PC**
   - File: `MediCore-Setup.exe`

2. **Run installer**
   - Double-click `MediCore-Setup.exe`
   - Click "Next" through installation
   - Installs to: `C:\Program Files\MediCore\`

3. **Launch MediCore**
   - Desktop shortcut created
   - Or Start Menu → MediCore

4. **Setup Wizard Appears:**
   ```
   Step 1: Server Selection
   ┌─────────────────────────────────┐
   │  🔍 Auto-Discover Servers        │
   ├─────────────────────────────────┤
   │  ✓ MediCore Server               │
   │    192.168.1.100                 │
   └─────────────────────────────────┘
   
   [Click the server]
   ```

5. **Test Connection:**
   ```
   Testing connection to 192.168.1.100...
   ✅ Connection successful!
   ```

6. **Save and Login:**
   - Configuration saved automatically
   - Login screen appears
   - Enter your credentials
   - Done!

---

## 🔧 QUICK REFERENCE

### Server Commands

**Check if server is running:**
```bash
launchctl list | grep medicore
```

**View server logs:**
```bash
tail -f /Applications/eye/medicore_server/logs/server.log
```

**Stop server:**
```bash
launchctl unload ~/Library/LaunchAgents/com.medicore.server.plist
```

**Start server:**
```bash
launchctl load ~/Library/LaunchAgents/com.medicore.server.plist
```

**Restart server:**
```bash
launchctl unload ~/Library/LaunchAgents/com.medicore.server.plist
launchctl load ~/Library/LaunchAgents/com.medicore.server.plist
```

---

### Database Commands

**Connect to database:**
```bash
psql -U medicore -d medicore_db
```

**Check patient count:**
```bash
psql -U medicore -d medicore_db -c "SELECT COUNT(*) FROM patients;"
```

**Check all data:**
```bash
psql -U medicore -d medicore_db -c "
SELECT 
  (SELECT COUNT(*) FROM patients) as patients,
  (SELECT COUNT(*) FROM visits) as visits,
  (SELECT COUNT(*) FROM ordonnances) as ordonnances,
  (SELECT COUNT(*) FROM payments) as payments;
"
```

**Backup database:**
```bash
pg_dump -U medicore medicore_db > ~/Desktop/medicore_backup_$(date +%Y%m%d).sql
```

---

### Network Info

**Get server IP:**
```bash
ipconfig getifaddr en0
```

**Test from client:**
```bash
# On Windows client:
curl http://192.168.1.100:50052/api/health
```

**Server URLs:**
- Local: `http://localhost:50052`
- Network: `http://YOUR_IP:50052`
- Health check: `http://YOUR_IP:50052/api/health`

---

## 🚨 Troubleshooting

### Server won't start

**Check PostgreSQL:**
```bash
brew services list | grep postgresql
```

**If not started:**
```bash
brew services start postgresql@14
```

**Check logs:**
```bash
tail -50 /Applications/eye/medicore_server/logs/server_error.log
```

---

### Clients can't find server

**1. Check Firewall:**
- System Preferences → Security & Privacy → Firewall
- Click "Firewall Options"
- Add `medicore-server`
- Allow incoming connections

**2. Verify server is accessible:**
```bash
# On server Mac:
curl http://localhost:50052/api/health

# Should work
```

**3. Try manual IP entry:**
- In client setup wizard
- Click "Enter Manually"
- Enter server IP: `192.168.1.100`
- Port: `50052`

---

### Data not showing

**Verify data was migrated:**
```bash
psql -U medicore -d medicore_db -c "SELECT COUNT(*) FROM patients;"
# Should show: 63664
```

**If wrong count, re-migrate:**
```bash
cd /Applications/eye
./MIGRATE_DATA.sh
```

---

## 📁 File Locations

### On Server Mac:

```
/Applications/eye/
├── medicore.db                          # Original SQLite (BACKUP)
├── medicore_BACKUP_XXXXXX.db            # Timestamped backup
├── INSTALL_SERVER.sh                    # Step 1: Install
├── MIGRATE_DATA.sh                      # Step 2: Import data
├── SETUP_AUTO_START.sh                  # Step 3: Auto-start
├── START_SERVER.sh                      # Manual start
├── DEPLOYMENT_GUIDE.md                  # Full guide
└── medicore_server/
    ├── medicore-server                  # Server binary
    ├── logs/
    │   ├── server.log                   # Server output
    │   └── server_error.log             # Errors
    └── scripts/
        ├── migrate.sh                   # Schema migration
        └── migrate_production_data.py   # Data import
```

### On Client PCs:

```
C:\Program Files\MediCore\
└── MediCore.exe

C:\Users\{username}\AppData\Local\MediCore\
└── config/                              # Saved configuration
```

---

## ✅ SUCCESS CHECKLIST

### Server Setup Complete When:

- [ ] PostgreSQL installed and running
- [ ] Database `medicore_db` created
- [ ] All 63K+ patients migrated
- [ ] Server starts on boot
- [ ] Health endpoint responds
- [ ] Accessible from network

### Client Setup Complete When:

- [ ] App installed on PC
- [ ] Setup wizard completed
- [ ] Can connect to server
- [ ] Can login
- [ ] Can see all patients
- [ ] All features work

---

## 🎯 NEXT STEPS

1. **Right now - Set up server:**
   ```bash
   cd /Applications/eye
   ./INSTALL_SERVER.sh     # 5 min
   ./MIGRATE_DATA.sh       # 2-5 min
   ./SETUP_AUTO_START.sh   # 1 min
   ```

2. **Get your server IP:**
   ```bash
   ipconfig getifaddr en0
   # Write it down!
   ```

3. **I'll fix the Flutter compilation errors and create Windows installer**

4. **You deploy to client PCs**

---

**Current Status:**
- ✅ PostgreSQL schema ready
- ✅ Migration scripts ready
- ✅ Server auto-start ready
- ✅ Your data backed up
- ⏳ Flutter app - minor fixes needed
- ⏳ Windows installer - will create

**Time to Production:** ~20 minutes (server) + fixing Flutter (~30 min) = ~1 hour total
