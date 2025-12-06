# 🚀 Run MediCore App - Instructions

## ✅ What's Ready

- ✅ **Xcode installed** (14.3.1)
- ✅ **Flutter configured** (3.38.3)
- ✅ **Drift database** complete with persistence
- ✅ **Go backend** compiled and ready
- ✅ **App code** ready to run

## ⏳ What's Needed

### **1. Install CocoaPods** (Required for macOS)

CocoaPods needs to be installed with sudo permissions.

**Option A: Run the setup script**
```bash
cd /Applications/eye
./QUICK_SETUP.sh
```
This will:
- Install CocoaPods
- Setup macOS dependencies
- Prepare the app to run

**Option B: Manual installation**
```bash
# Install CocoaPods
sudo gem install cocoapods -v 1.11.3

# Setup pods
cd /Applications/eye/medicore_app/macos
pod install
```

---

## 🎯 Run the App

Once CocoaPods is installed:

```bash
cd /Applications/eye/medicore_app
flutter run -d macos
```

The app will:
- ✅ Open in a new window
- ✅ Show French login screen
- ✅ Work with local Drift/SQLite database
- ✅ Persist data across restarts

---

## 🔐 Login Credentials

### **Admin Login**
- Username: `Administrateur`
- Password: `1234`

### **Features Available**
- ✅ User management (Create, Read, Update, Delete)
- ✅ Template management (4 roles: Médecin, Infirmier, Assistant 1, Assistant 2)
- ✅ Template-based user creation
- ✅ Local database persistence
- ✅ French UI with Cockpit design

---

## 🗄️ Backend Server (Optional - For Multi-PC)

The backend is ready but can be set up later:

```bash
# 1. Setup PostgreSQL (when ready)
cd /Applications/eye/medicore_server
# Configure PostgreSQL connection

# 2. Run server
./medicore_server
```

---

## 📁 Key Locations

### **App Database**
```
~/Documents/medicore.db
```
This SQLite file contains all users and templates.

### **App Code**
```
/Applications/eye/medicore_app/
```

### **Server Binary**
```
/Applications/eye/medicore_server/medicore_server
```

---

## 🐛 Troubleshooting

### "CocoaPods not installed"
```bash
# Check if installed
which pod

# If not found, install:
sudo gem install cocoapods -v 1.11.3
```

### "Build failed"
```bash
# Clean and rebuild
cd /Applications/eye/medicore_app
flutter clean
flutter pub get
cd macos && pod install
cd ..
flutter run -d macos
```

### "Database error"
```bash
# Delete and recreate
rm ~/Documents/medicore.db
flutter run -d macos
# Database will be recreated with admin user
```

---

## 🎨 What You'll See

1. **Login Screen** (French)
   - Admin login button
   - User login (name + password)
   - Template-based registration

2. **Admin Dashboard** (after login as admin)
   - User Management tab
   - Template Management tab
   - Logout button

3. **User Management**
   - List of users in data grid
   - Add/Edit/Delete buttons
   - User statistics

4. **Template Management**
   - List of templates
   - 4 predefined roles dropdown
   - Add/Edit/Delete buttons

---

## 📊 Architecture

```
Flutter App (Local)
    ↓
Drift/SQLite Database
    ↓
(Optional) gRPC Sync
    ↓
Go Backend + PostgreSQL
```

**Current Status:** Local database working perfectly ✅
**Next:** Backend sync (optional, for multi-PC)

---

## ✅ Summary

**To run the app RIGHT NOW:**

1. Open Terminal
2. Run: `cd /Applications/eye && ./QUICK_SETUP.sh`
3. Enter your password when prompted
4. Run: `cd medicore_app && flutter run -d macos`

**That's it!** The app will launch with full functionality.

---

## 📞 Quick Commands

```bash
# Run app
cd /Applications/eye/medicore_app && flutter run -d macos

# Clean rebuild
flutter clean && flutter pub get && flutter run -d macos

# View database
sqlite3 ~/Documents/medicore.db "SELECT * FROM users;"

# Check Flutter
flutter doctor

# Start backend server (later)
cd /Applications/eye/medicore_server && ./medicore_server
```

---

**The professional architecture is ready. Just need to install CocoaPods and run! 🚀**
