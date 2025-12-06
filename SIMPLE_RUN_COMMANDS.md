# 🚀 Run MediCore App - SIMPLE Commands

## ✅ **Option 1: One Command (Easiest)**

Open Terminal and run:

```bash
cd /Applications/eye && ./FIX_AND_RUN.sh
```

This does everything:
- Fixes permissions
- Installs CocoaPods
- Sets up the app
- Launches it

Enter your password when asked, then wait for the app to launch!

---

## ✅ **Option 2: Manual Steps**

If the script doesn't work, run these commands one by one:

### **Step 1: Fix Homebrew Permissions**
```bash
sudo chown -R $(whoami) /usr/local/Homebrew /usr/local/var/homebrew
```

### **Step 2: Install CocoaPods**
```bash
brew install cocoapods
```

### **Step 3: Setup App Dependencies**
```bash
cd /Applications/eye/medicore_app/macos
pod install
```

### **Step 4: Run the App**
```bash
cd /Applications/eye/medicore_app
flutter run -d macos
```

---

## 🎯 **What Happens When App Launches**

1. **Build process** (~2-3 minutes first time)
2. **App window opens**
3. **French login screen appears**

### **Login as Admin:**
- Username: `Administrateur`
- Password: `1234`

---

## 🐛 **If Something Goes Wrong**

### "pod: command not found"
```bash
# After running brew install cocoapods, run:
export PATH="/usr/local/bin:$PATH"
pod --version
```

### "CocoaPods not installed"
```bash
# Check if installed:
which pod

# If not found:
brew install cocoapods
```

### "Permission denied"
```bash
# Fix all permissions at once:
sudo chown -R $(whoami) /usr/local
```

### "Build failed"
```bash
cd /Applications/eye/medicore_app
flutter clean
flutter pub get
cd macos && pod install
cd ..
flutter run -d macos
```

---

## 📝 **Quick Reference**

```bash
# Run app (from correct directory)
cd /Applications/eye/medicore_app
flutter run -d macos

# Check Flutter status
flutter doctor

# Rebuild from scratch
flutter clean && flutter pub get && flutter run -d macos

# Stop running app
# Press 'q' in the terminal or close the app window
```

---

## ✅ **What's Working**

The app has:
- ✅ **Drift/SQLite database** - Full persistence
- ✅ **User management** - CRUD operations
- ✅ **Template management** - 4 roles
- ✅ **French UI** - Cockpit design
- ✅ **Admin dashboard** - Complete features

**The database is at:** `~/Documents/medicore.db`

---

## 🎯 **Just Run This**

```bash
cd /Applications/eye && ./FIX_AND_RUN.sh
```

**That's it! The app will launch.** 🚀
