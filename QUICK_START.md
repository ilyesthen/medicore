# Quick Start Guide

## What's Been Set Up

✅ **Flutter App** (`/Applications/eye/medicore_app/`) - "The Cockpit" Design
- **Steel & Navy** color palette (Deep Navy, Professional Blue, Canvas Grey)
- **Merriweather + Roboto** typography (Editorial hybrid)
- **Fixed Canvas** scaler (1440x900 - scales perfectly on all screens)
- **Cockpit UI Components** (Panes, Buttons, Inputs, Data Grids)
- **Custom Window Chrome** (Deep Navy title bar with integrated controls)
- Drift database boilerplate
- gRPC client configuration
- Feature-first folder structure (empty, ready for features)

✅ **Go Backend** (`/Applications/eye/medicore_server/`)
- Go modules configured
- gRPC server boilerplate
- PostgreSQL connection setup
- Proto directory ready for service definitions

✅ **Documentation**
- README.md - Project overview
- SETUP_GUIDE.md - Detailed setup instructions
- COCKPIT_DESIGN.md - Complete Cockpit design system guide
- techstackbrandkit .md - Your original design specs

## Quick Commands

### Start Flutter App
```bash
cd /Applications/eye/medicore_app
flutter pub get
dart run build_runner build
flutter run -d macos  # or windows/linux
```

### Start Go Server
```bash
cd /Applications/eye/medicore_server
go mod download
go run cmd/server/main.go
```

## Project Structure Overview

```
/Applications/eye/
│
├── medicore_app/                 # Flutter Desktop App (Cockpit Design)
│   ├── lib/src/
│   │   ├── core/
│   │   │   ├── theme/           # ✅ Steel & Navy palette, Merriweather+Roboto
│   │   │   ├── ui/              # ✅ Cockpit components (Pane, Button, Grid, etc)
│   │   │   ├── database/        # ✅ Drift configured
│   │   │   └── api/             # ✅ gRPC client ready
│   │   └── features/            # 📁 Add features here
│   ├── assets/                  # 📁 Add images/logos here
│   └── pubspec.yaml             # ✅ Dependencies configured
│
├── medicore_server/             # Go Backend
│   ├── cmd/server/              # ✅ Entry point ready
│   ├── internal/
│   │   └── database/            # ✅ PostgreSQL setup
│   ├── proto/                   # 📁 Add .proto files here
│   └── go.mod                   # ✅ Dependencies configured
│
└── docs/
    ├── README.md                # ✅ Project overview
    ├── SETUP_GUIDE.md           # ✅ Detailed instructions
    └── techstackbrandkit .md    # ✅ Your design specs
```

## Ready to Build Features!

### To Add a New Feature (e.g., "Patients"):

1. **Define the API** (`medicore_server/proto/patients.proto`)
2. **Generate code** (protoc commands in SETUP_GUIDE.md)
3. **Create Flutter feature** (`medicore_app/lib/src/features/patients/`)
4. **Create Go service** (`medicore_server/internal/services/patients_service.go`)

See SETUP_GUIDE.md for detailed examples.

## What's NOT Included

- No UI screens (except empty home)
- No database tables
- No API endpoints
- No business logic
- No test data

This is intentional - you have a clean slate to build features independently!

## Cockpit Components Usage

```dart
// Build UI with pre-made Cockpit components:
import 'package:medicore_app/src/core/ui/cockpit_pane.dart';
import 'package:medicore_app/src/core/ui/cockpit_button.dart';
import 'package:medicore_app/src/core/ui/data_grid.dart';

// Pane with title bar and borders
CockpitPane(
  title: 'Patients',
  actions: [
    CockpitButton(label: 'New', icon: Icons.add, onPressed: () {}),
  ],
  child: DataGrid(
    headers: ['ID', 'NAME', 'PHONE'],
    rows: [
      ['001', 'John Doe', '+1234567890'],
      ['002', 'Jane Smith', '+0987654321'],
    ],
  ),
)
```

See **COCKPIT_DESIGN.md** for complete design system documentation.

## Next Steps

1. ✅ Read SETUP_GUIDE.md
2. ✅ Install prerequisites (Flutter, Go, PostgreSQL)
3. ✅ Run `flutter pub get` and `go mod download`
4. ✅ Start building your first feature!
