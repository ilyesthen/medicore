# MediCore Server - Go Backend with gRPC

Professional backend server for MediCore medical management application.

## 🏗️ Architecture

```
Flutter Client (Drift/SQLite)
    ↓ gRPC
Go Server (PostgreSQL)
    ↓
Database (Users, Templates)
```

## 📋 Prerequisites

- **Go 1.21+** ✅ (Installed)
- **PostgreSQL 13+** (Need to install)
- **protoc** ✅ (Installed)

## 🚀 Quick Start

### 1. Install PostgreSQL

**macOS:**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Linux:**
```bash
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**Windows:**
Download from: https://www.postgresql.org/download/windows/

### 2. Create Database

```bash
# Connect to PostgreSQL
psql postgres

# Create user and database
CREATE USER medicore WITH PASSWORD 'medicore';
CREATE DATABASE medicore_db OWNER medicore;
\q

# Run schema
psql -U medicore -d medicore_db -f database/schema.sql
```

### 3. Configure Server

```bash
# Copy example config
cp .env.example .env

# Edit .env if needed (defaults are fine for local)
```

### 4. Build & Run

```bash
# Build
go build -o medicore_server ./cmd/server

# Run
./medicore_server
```

You should see:
```
🚀 Starting MediCore Server...
📊 Connecting to PostgreSQL at localhost:5432...
✅ Database connected successfully
✅ UsersService registered
🎯 MediCore gRPC Server listening on :50051
📡 Ready to accept client connections...
```

## 🌐 Multi-PC Setup

### Server PC (Admin)

```bash
# 1. Install PostgreSQL
# 2. Run schema.sql
# 3. Start server
DB_HOST=0.0.0.0 ./medicore_server
```

### Client PCs

Update Flutter app config to point to server IP:
```dart
// lib/src/core/config/app_config.dart
static const String serverHost = '192.168.1.10'; // Admin PC IP
static const int serverPort = 50051;
```

## 🗂️ Project Structure

```
medicore_server/
├── cmd/
│   └── server/
│       └── main.go              ← Entry point
├── internal/
│   ├── database/
│   │   └── postgres.go          ← DB connection
│   ├── models/
│   │   └── user.go              ← Data models
│   ├── repository/
│   │   ├── users_repository.go  ← User CRUD
│   │   └── templates_repository.go
│   └── service/
│       └── users_service.go     ← gRPC handlers
├── proto/
│   ├── users.proto              ← gRPC contract
│   ├── users.pb.go              ← Generated
│   └── users_grpc.pb.go         ← Generated
├── database/
│   └── schema.sql               ← PostgreSQL schema
├── .env.example                 ← Config template
└── medicore_server              ← Compiled binary ✅
```

## 🔧 Development

### Regenerate gRPC Code

```bash
./protoc-install/bin/protoc \
  --go_out=. --go_opt=paths=source_relative \
  --go-grpc_out=. --go-grpc_opt=paths=source_relative \
  proto/users.proto
```

### Run Tests

```bash
go test ./...
```

### Build for Production

```bash
# Linux
GOOS=linux GOARCH=amd64 go build -o medicore_server_linux ./cmd/server

# Windows
GOOS=windows GOARCH=amd64 go build -o medicore_server.exe ./cmd/server
```

## 🌍 Deployment

### Option 1: LAN (Local Network)

1. **Server PC:**
   - Install PostgreSQL
   - Run `medicore_server`
   - Note IP address: `ifconfig` or `ipconfig`

2. **Client PCs:**
   - Configure Flutter app with server IP
   - Run Flutter app

### Option 2: Cloud (AWS, DigitalOcean, etc.)

1. **Server:**
   ```bash
   # Install PostgreSQL
   sudo apt update
   sudo apt install postgresql postgresql-contrib
   
   # Create database
   sudo -u postgres psql -f database/schema.sql
   
   # Run server
   nohup ./medicore_server &
   ```

2. **Firewall:**
   ```bash
   sudo ufw allow 50051/tcp
   ```

3. **Client Apps:**
   - Configure with server domain/IP
   - Use TLS in production

## 📊 Database Schema

### Users Table
- `id` - Unique identifier
- `name` - Full name
- `role` - Médecin, Infirmier, Assistant 1, Assistant 2
- `password_hash` - Hashed password
- `percentage` - Optional percentage
- `is_template_user` - Created from template
- Timestamps: `created_at`, `updated_at`, `deleted_at`
- Sync fields: `sync_version`, `last_synced_at`, `needs_sync`

### Templates Table
- `id` - Unique identifier
- `role` - Template role
- `password_hash` - Default password
- `percentage` - Default percentage
- Timestamps and sync fields

## 🔒 Security Notes

⚠️ **For Production:**
- Hash passwords (currently plain text for development)
- Use TLS/SSL for gRPC connections
- Set `DB_SSLMODE=require`
- Use strong database passwords
- Implement authentication tokens

## 🐛 Troubleshooting

### "Failed to connect to database"
- Check PostgreSQL is running: `pg_isready`
- Verify credentials in `.env`
- Check database exists: `psql -l`

### "Port 50051 already in use"
- Change port in `cmd/server/main.go`
- Or kill existing process: `lsof -ti:50051 | xargs kill`

### "Permission denied"
- Make binary executable: `chmod +x medicore_server`

## 📝 API Documentation

### gRPC Methods

- `SyncUsers` - Sync users from client to server
- `SyncTemplates` - Sync templates
- `CreateUser` - Create new user
- `UpdateUser` - Update existing user
- `DeleteUser` - Soft delete user
- `GetAllUsers` - Retrieve all users
- `CreateTemplate` - Create template
- `UpdateTemplate` - Update template
- `DeleteTemplate` - Delete template
- `GetAllTemplates` - Get all templates

See `proto/users.proto` for full API specification.

## ✅ Status

- ✅ gRPC server implemented
- ✅ PostgreSQL repository layer
- ✅ All CRUD operations
- ✅ Sync endpoints ready
- ✅ Compiled binary ready
- ⏳ PostgreSQL needs installation
- ⏳ Flutter sync client (next step)

## 📞 Support

For issues or questions, check:
1. PostgreSQL logs: `/var/log/postgresql/`
2. Server logs (stdout)
3. Network connectivity: `ping <server-ip>`
