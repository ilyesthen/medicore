# MediCore Ophthalmology

<div align="center">
  <h3>Professional Ophthalmology Practice Management</h3>
  <p>Complete medical software for eye doctors - Patient management, consultations, prescriptions, and more</p>
</div>

---

## 🚀 Quick Start

### Windows Installation

Download the latest installer from [Releases](https://github.com/ilyesthen/medicore/releases):

| Version | Architecture | Download |
|---------|-------------|----------|
| **Server/Admin** | 64-bit | `MediCore_Setup_vX.X.X_x64.exe` |
| **Client** | 64-bit | Same installer, select "Client Mode" |

### Installation Modes

#### 🖥️ **Server Mode (Admin)**
- Installs the database server
- Other computers on LAN can connect
- Configure database location and network settings

#### 💻 **Client Mode (Workstations)**
- Connects to the admin server via LAN
- Enter the server IP address during setup
- All data synced from central server

---

## 📋 Features

- **Patient Management** - Full patient records with age calculation
- **Consultation History** - Complete visit tracking with eye measurements
- **Prescriptions** - Optical, lenses, and medication prescriptions
- **Waiting Queue** - Real-time patient flow management
- **Multi-Room Support** - Manage multiple consultation rooms
- **PDF Generation** - Professional prescriptions and certificates
- **LAN Networking** - Multiple workstations, one database

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ADMIN WORKSTATION                        │
│  ┌─────────────────┐    ┌─────────────────────────────────┐ │
│  │  MediCore App   │◄──►│  MediCore Server (Go + SQLite)  │ │
│  └─────────────────┘    └─────────────────────────────────┘ │
│                                    ▲                        │
└────────────────────────────────────│────────────────────────┘
                                     │ LAN (TCP/8080)
         ┌───────────────────────────┼───────────────────────┐
         │                           │                       │
         ▼                           ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Client Station  │    │ Client Station  │    │ Client Station  │
│  (Reception)    │    │   (Doctor 1)    │    │   (Doctor 2)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 🔧 Development

### Prerequisites
- Flutter 3.24+
- Go 1.21+
- SQLite

### Build from Source

```bash
# Clone repository
git clone https://github.com/ilyesthen/medicore.git
cd medicore

# Build Flutter app
cd medicore_app
flutter pub get
flutter build windows --release

# Build Go server
cd ../medicore_server
go build -o medicore_server.exe ./cmd/server
```

---

## 📜 License

MIT License - See [LICENSE](LICENSE) for details.

---

# MediCore Medical Management System

## Design Philosophy: "The Cockpit"

MediCore uses a professional, desktop-first design inspired by cockpits and control panels. No floating cards, no trendy aesthetics - just dense, rigid panes with visible borders for maximum information density and authority.

## Tech Stack Overview

### Frontend
- **Flutter** (Dart) - Cross-platform desktop app with pixel-perfect rendering
- **Drift** - Type-safe SQLite ORM for local database
- **Riverpod** - State management

### Backend
- **Go** (Golang) - Single binary API server
- **gRPC** (Protobuf) - Type-safe API communication
- **PostgreSQL** - Server database

### Architecture
- **Sync-First**: Local SQLite first, sync to PostgreSQL
- **Feature-First**: Each feature is isolated in its own folder

## Project Structure

```
/Applications/eye/
├── medicore_app/          # Flutter Desktop Application
│   ├── lib/
│   │   ├── src/
│   │   │   ├── core/      # Theme, Database, Shared Components
│   │   │   └── features/  # Feature modules (isolated)
│   │   └── main.dart
│   └── pubspec.yaml
│
└── medicore_server/       # Go Backend Server
    ├── cmd/server/        # Entry point
    ├── internal/          # Business logic
    ├── proto/             # gRPC Protobuf definitions
    └── go.mod
```

## Setup Instructions

### Flutter App Setup
1. Install Flutter SDK (3.0+)
2. Navigate to `medicore_app/`
3. Run: `flutter pub get`
4. Run: `dart run build_runner build` (generates Drift database code)
5. Run: `flutter run -d windows` (or macos/linux)

### Go Backend Setup
1. Install Go 1.21+
2. Navigate to `medicore_server/`
3. Run: `go mod download`
4. Run: `go run cmd/server/main.go`

## Design System: "The Cockpit"

### Color Palette: Steel & Navy
- **Deep Navy** (#1B263B) - Sidebar, headers, anchors
- **Professional Blue** (#415A77) - Active buttons, highlights
- **Canvas Grey** (#E0E1DD) - Main background (anti-glare)
- **Steel Outline** (#778DA9) - Borders on every pane

### Typography: Editorial Hybrid
- **Merriweather** (Serif) - Headings (medical journal feel)
- **Roboto** (Sans-Serif) - Data/UI (mechanical, precise)

### Layout: Fixed Canvas (1440x900)
- Single design resolution
- Scales proportionally on all screens
- No reflowing, no layout shifts
- Pixel-perfect consistency

See `techstackbrandkit .md` for complete specifications.
