# 🚀 Quick Start: PostgreSQL Migration

## ⚡ 5-Minute Setup

### Step 1: Install PostgreSQL (if not installed)

```bash
# macOS
brew install postgresql@14
brew services start postgresql@14

# Ubuntu/Debian
sudo apt update
sudo apt install postgresql-14
sudo systemctl start postgresql

# Windows
# Download from: https://www.postgresql.org/download/windows/
```

### Step 2: Create Database & User

```bash
# Create user
sudo -u postgres createuser -P medicore
# Enter password: medicore

# Create database
sudo -u postgres createdb -O medicore medicore_db
```

### Step 3: Run Migration Script

```bash
cd medicore_server/scripts
./migrate.sh
```

### Step 4: Import Existing Data (Optional)

If you have an existing SQLite database:

```bash
cd medicore_server/scripts
python3 import_from_sqlite.py /path/to/medicore.db
```

### Step 5: Test Server

```bash
cd medicore_server/cmd/server
go run main.go
```

Expected output:
```
🚀 MediCore REST API Server Starting...
📊 Connecting to PostgreSQL: medicore@localhost:5432/medicore_db
✅ PostgreSQL connection established successfully
📋 Database schema version: 5.0.0
✅ MEDICORE SERVER READY FOR LAN CONNECTIONS
```

---

## ✅ Success!

Your PostgreSQL database is ready! 

**Next:** Run Phase 2 to clean up Flutter app (remove local SQLite code)

---

## 🔧 Troubleshooting

### Issue: "psql: command not found"
```bash
# Add PostgreSQL to PATH
export PATH="/usr/local/opt/postgresql@14/bin:$PATH"
```

### Issue: "connection refused"
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql  # Linux
brew services list                # macOS

# Start PostgreSQL
sudo systemctl start postgresql   # Linux
brew services start postgresql@14 # macOS
```

### Issue: "database does not exist"
```bash
# Create database manually
createdb -U medicore medicore_db
```

### Issue: "role does not exist"
```bash
# Create user manually
sudo -u postgres createuser -P medicore
```

---

## 📊 Verify Installation

```bash
# Connect to database
psql -U medicore -d medicore_db

# Check tables (should show 18 tables)
\dt

# Check schema version
SELECT value_text FROM app_metadata WHERE key = 'schema_version';
# Expected: 5.0.0

# Exit
\q
```

---

## 🎯 What's Next?

After successful PostgreSQL setup:

1. ✅ Phase 1.1 Complete - Database migrated
2. 🔜 Phase 2 - Clean up Flutter app (remove SQLite code)
3. 🔜 Phase 3 - Test all features
4. 🔜 Phase 4 - Deploy to production

See `MIGRATION_PHASE_1_COMPLETE.md` for detailed information.
