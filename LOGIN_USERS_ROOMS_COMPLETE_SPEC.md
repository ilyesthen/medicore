# 🔐 LOGIN, USERS, AND ROOMS - COMPLETE SPECIFICATION

## WHAT THIS COVERS
1. Login System (Authentication)
2. User Creation System
3. Room Creation System
4. Template System (for quick user creation)

---

# 1. LOGIN SYSTEM

## Login Flow

```
User opens app
    ↓
Login Screen shows
    ↓
User enters username + password
    ↓
System checks database for user with that name
    ↓
If user not found → Show error: "Nom d'utilisateur ou mot de passe incorrect"
    ↓
If password doesn't match → Show error: "Nom d'utilisateur ou mot de passe incorrect"
    ↓
If credentials valid:
    - Save current user in memory
    - Check user role
    ↓
If role = "Administrateur" → Go to Admin Dashboard
    ↓
If role = "Médecin" OR "Assistant 1" OR "Assistant 2" → Show Room Selection Screen
    ↓
If role = "Infirmier" OR "Infirmière":
    - Mark nurse as ACTIVE in database (for room exclusivity)
    - Show Room Selection Screen
```

## Database Tables Used

### Users Table Schema
```sql
CREATE TABLE users (
    id TEXT PRIMARY KEY,              -- 'admin' for admin, timestamp for others
    name TEXT NOT NULL,               -- Full name (minimum 2 words)
    role TEXT NOT NULL,               -- See roles below
    password_hash TEXT NOT NULL,      -- Plain text (no hashing currently)
    percentage REAL,                  -- Only for Assistant roles
    is_template_user BOOLEAN DEFAULT 0,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    deleted_at DATETIME,              -- Soft delete
    last_synced_at DATETIME,
    sync_version INTEGER DEFAULT 1,
    needs_sync BOOLEAN DEFAULT 0
);
```

## Valid User Roles
```
- "Administrateur"  → Full system access, no room selection
- "Médecin"         → Doctor, requires room selection
- "Infirmier"       → Male nurse, requires room selection
- "Infirmière"      → Female nurse, requires room selection
- "Assistant 1"     → First assistant type, requires room selection
- "Assistant 2"     → Second assistant type, requires room selection
```

## Default Admin Account
```
Username: admin
Password: 1234
Role: Administrateur
ID: 'admin'
```

## Login Screen UI Requirements

### Layout
- **Screen**: Centered container, 450px width
- **Background**: Canvas Grey (#E0E1DD)
- **Container**: Paper White (#FFFFFF) with 2px Steel Outline (#778DA9) border
- **Shadow**: Black 15% opacity, offset (0, 4), blur 12px

### Elements
1. **Header Section** (Deep Navy background #1B263B):
   - Title: "MediCore" (32px, white, Merriweather)
   - Subtitle: "Medical Management System" (13px, white 70% opacity)

2. **Login Title**: "System Login" (centered)

3. **Username Field**:
   - Label: "Username"
   - Placeholder: "Enter username"
   - Type: Text input
   - Required

4. **Password Field**:
   - Label: "Password"
   - Placeholder: "Enter password"
   - Type: Password (masked)
   - Required

5. **Login Button**:
   - Text: "LOGIN"
   - Icon: Login icon
   - Height: 44px
   - Full width
   - Color: Professional Blue (#415A77)

6. **Hint Box** (for development):
   - Background: Canvas Grey
   - Text: "Default Credentials:\nUsername: admin\nPassword: 1234"
   - Font size: 11px

7. **Error Display** (if login fails):
   - Red background (Critical Red #C5283D at 10% opacity)
   - Red border (Critical Red #C5283D, 1px)
   - Error icon
   - Error message text

### Login Validation Rules
- Username: Cannot be empty
- Password: Cannot be empty, minimum 4 characters
- Both fields required before submit enabled

## Authentication Logic Code Flow

```
function login(username, password):
    1. Query database: SELECT * FROM users WHERE name = username
    
    2. If no user found:
        return error: "Nom d'utilisateur ou mot de passe incorrect"
    
    3. If user found:
        if user.password_hash != password:
            return error: "Nom d'utilisateur ou mot de passe incorrect"
    
    4. If password matches:
        currentUser = user
        
        if user.role == "Infirmière" OR user.role == "Infirmier":
            markNurseActive(user.id)  // See below
        
        if user.role == "Administrateur":
            needsRoomSelection = false
            navigate to AdminDashboard
        else:
            needsRoomSelection = true
            navigate to RoomSelectionScreen
```

### Special: Nurse Activity Tracking

**Purpose**: Only ONE nurse can work in a room at a time (exclusivity)

**Storage**: SharedPreferences (key-value storage)

```
When nurse logs in:
    - Set key: "active_nurse_{userId}" = "true"
    - Set key: "nurse_active_since_{userId}" = current_timestamp

When nurse logs out:
    - Remove key: "active_nurse_{userId}"
    - Remove key: "nurse_active_since_{userId}"

When checking if nurse can enter room:
    - Check if ANY active_nurse_* key exists
    - If exists and it's NOT this nurse → Block entry
    - If exists and it IS this nurse → Allow entry
```

---

# 2. USER CREATION SYSTEM

## Two Ways to Create Users

### Method 1: From Template (Quick Creation)
```
Admin selects template
    ↓
Admin enters user's full name (minimum 2 words)
    ↓
System creates user with:
    - Template's role
    - Template's password
    - Template's percentage
    - Generated ID (timestamp in milliseconds)
    - is_template_user = true
```

### Method 2: Manual Creation
```
Admin enters:
    - Full name (minimum 2 words)
    - Role (dropdown)
    - Password (minimum 4 characters)
    - Percentage (only if role is Assistant 1 or Assistant 2)
    ↓
System creates user with:
    - Generated ID (timestamp in milliseconds)
    - is_template_user = false
```

## User Creation Validation Rules

### Name Validation
```javascript
function validateName(name) {
    const trimmed = name.trim();
    const words = trimmed.split(/\s+/);  // Split by whitespace
    
    if (words.length < 2) {
        return error: "Le nom doit contenir au moins 2 mots"
    }
    
    return valid;
}
```

### Password Validation
```javascript
function validatePassword(password) {
    if (password.length < 4) {
        return error: "Minimum 4 caractères"
    }
    return valid;
}
```

### Percentage Validation
```javascript
function validatePercentage(percentage, role) {
    if (role == "Assistant 1" OR role == "Assistant 2") {
        if (percentage == null) {
            return error: "Pourcentage requis"
        }
        if (percentage < 0 OR percentage > 100) {
            return error: "Entre 0 et 100"
        }
    }
    return valid;
}
```

### Role Restrictions
- Only "Assistant 1" and "Assistant 2" can have percentage
- "Administrateur", "Médecin", "Infirmier", "Infirmière" → percentage must be NULL

## User Creation Database Operation

```sql
INSERT INTO users (
    id,
    name,
    role,
    password_hash,
    percentage,
    is_template_user,
    created_at,
    updated_at,
    needs_sync
) VALUES (
    '{timestamp_in_milliseconds}',
    '{full_name}',
    '{selected_role}',
    '{password_plain_text}',
    {percentage_or_null},
    {true_if_from_template_else_false},
    '{current_datetime}',
    '{current_datetime}',
    true  -- Always needs sync after creation
);
```

## User Management UI Requirements

### User List Display
- **Layout**: Table with columns
- **Columns**:
  1. Name (left-aligned)
  2. Role (centered)
  3. Percentage (centered, only show if role is Assistant)
  4. Actions (right-aligned: Edit, Delete buttons)

### Create User Dialog
- **Size**: 500px width
- **Fields**:
  1. Name input (text)
  2. Role dropdown
  3. Password input (text or password)
  4. Percentage input (number, 0-100, only visible if Assistant role)

### Edit User Dialog
- Same as create, but pre-filled with existing data
- ID cannot be changed
- Update `updated_at` timestamp
- Set `needs_sync = true`

### Delete User
- **Soft Delete**: Set `deleted_at = current_timestamp`
- Do NOT physically delete from database
- Hide from user list where `deleted_at IS NULL`
- Set `needs_sync = true`

---

# 3. TEMPLATE SYSTEM

## What Are Templates?

Templates are **pre-configured role profiles** for quick user creation.

**Example**:
```
Template: "Assistant Consultation"
    Role: "Assistant 1"
    Password: "assist123"
    Percentage: 25.0

When admin creates user "Ahmed Ben Ali" from this template:
    → User "Ahmed Ben Ali" is created with role Assistant 1, password assist123, 25%
```

## Template Table Schema

```sql
CREATE TABLE templates (
    id TEXT PRIMARY KEY,              -- UUID
    role TEXT NOT NULL,               -- Role name
    password_hash TEXT NOT NULL,      -- Default password for this role
    percentage REAL NOT NULL,         -- Commission percentage
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    deleted_at DATETIME,              -- Soft delete
    last_synced_at DATETIME,
    sync_version INTEGER DEFAULT 1,
    needs_sync BOOLEAN DEFAULT 0
);
```

## Template Creation

### Validation
- Role: Must be valid role (from the 6 predefined roles)
- Password: Minimum 4 characters
- Percentage: 0-100

### Database Operation
```sql
INSERT INTO templates (
    id,
    role,
    password_hash,
    percentage,
    created_at,
    updated_at,
    needs_sync
) VALUES (
    '{generate_uuid_v4}',
    '{role}',
    '{password}',
    {percentage},
    '{current_datetime}',
    '{current_datetime}',
    true
);
```

## Creating User from Template

```javascript
function createUserFromTemplate(templateId, userName) {
    // 1. Get template
    const template = getTemplateById(templateId);
    
    // 2. Validate name
    if (!validateName(userName)) {
        throw error;
    }
    
    // 3. Create user
    const user = {
        id: getCurrentTimestampMillis(),
        name: userName,
        role: template.role,
        password_hash: template.password_hash,
        percentage: template.percentage,
        is_template_user: true,
        created_at: now(),
        updated_at: now(),
        needs_sync: true
    };
    
    // 4. Insert to database
    insertUser(user);
    
    return user;
}
```

---

# 4. ROOM CREATION SYSTEM

## What Are Rooms?

Rooms are **consultation spaces** in the clinic. Examples:
- "Cabinet 1"
- "Cabinet 2"
- "Salle d'Urgence"
- "Salle de Consultation"

Doctors and nurses select a room when they log in. This allows:
- Multiple doctors working in different rooms
- Patients sent to specific rooms
- Messages sent to specific rooms

## Room Table Schema

```sql
CREATE TABLE rooms (
    id TEXT PRIMARY KEY,              -- UUID
    name TEXT NOT NULL,               -- Room name
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    needs_sync BOOLEAN DEFAULT 1
);
```

## Room Creation

### Validation
- Name: Cannot be empty
- Name: Must be unique (check if room with same name exists)

### Database Operation
```sql
INSERT INTO rooms (
    id,
    name,
    created_at,
    updated_at,
    needs_sync
) VALUES (
    '{generate_uuid_v4}',
    '{room_name}',
    '{current_datetime}',
    '{current_datetime}',
    true
);
```

## Room Management UI Requirements

### Room List Display
- **Layout**: Simple list or grid of cards
- **Each Room Shows**:
  - Room name
  - Actions (Edit, Delete buttons)

### Create Room Dialog
- **Size**: 400px width
- **Fields**:
  1. Room name input (text, required)
- **Buttons**:
  - Cancel
  - Create

### Edit Room
- Same dialog as create
- Pre-filled with room name
- Update `updated_at` timestamp
- Set `needs_sync = true`

### Delete Room
- **Hard Delete**: Physically remove from database
  ```sql
  DELETE FROM rooms WHERE id = '{room_id}';
  ```
- **Warning**: Should check if room is currently in use before deleting

## Room Selection After Login

### When Room Selection Is Required
- User role is "Médecin"
- User role is "Assistant 1"
- User role is "Assistant 2"
- User role is "Infirmier" or "Infirmière"

### Room Selection Screen

**Layout**:
- **Header**: Shows user name and role
- **Title**: "Sélection de salle"
- **Room List**: Cards/buttons for each room

**Each Room Card**:
- Radio button (selected/unselected)
- Room name
- Checkmark icon if selected

**Confirm Button**:
- Text: "CONFIRMER LA SALLE"
- Disabled until room is selected
- Height: 50px

**Room Selection Logic**:
```javascript
function selectRoom(room) {
    // 1. Remove user from previous room (if any)
    if (currentRoom != null) {
        removeUserFromRoom(currentRoom.id, currentUser.name);
    }
    
    // 2. Add user to new room
    addUserToRoom(room.id, currentUser.name);
    
    // 3. Save selected room to state
    currentRoom = room;
    needsRoomSelection = false;
    
    // 4. Navigate to main dashboard
    navigate to Dashboard;
}
```

## Room Presence Tracking (In-Memory)

**Purpose**: Track which users are in which rooms in real-time.

**Data Structure** (stored in memory, NOT database):
```javascript
// Map of roomId → Set of userNames
const roomPresence = {
    "room-uuid-1": ["Dr. Ahmed", "Infirmière Sara"],
    "room-uuid-2": ["Dr. Mohamed"],
};
```

**Operations**:
```javascript
function addUserToRoom(roomId, userName) {
    if (!roomPresence[roomId]) {
        roomPresence[roomId] = new Set();
    }
    roomPresence[roomId].add(userName);
}

function removeUserFromRoom(roomId, userName) {
    if (roomPresence[roomId]) {
        roomPresence[roomId].delete(userName);
    }
}

function removeUserFromAllRooms(userName) {
    for (const roomId in roomPresence) {
        roomPresence[roomId].delete(userName);
    }
}

function getUsersInRoom(roomId) {
    return Array.from(roomPresence[roomId] || []);
}
```

**When to Update**:
- User selects room → `addUserToRoom`
- User changes room → `removeUserFromRoom` then `addUserToRoom`
- User logs out → `removeUserFromAllRooms`
- App closes → Clear all (it's in-memory only)

---

# 5. COMPLETE DATA MODELS

## User Model
```javascript
class User {
    id: string;                    // 'admin' or timestamp
    name: string;                  // Full name (min 2 words)
    role: string;                  // One of 6 predefined roles
    password: string;              // Plain text password
    percentage: number | null;     // Only for Assistants
    isTemplateUser: boolean;       // Created from template?
    createdAt: DateTime;
    updatedAt: DateTime;
    deletedAt: DateTime | null;    // Soft delete
    lastSyncedAt: DateTime | null;
    syncVersion: number;
    needsSync: boolean;
}
```

## Template Model
```javascript
class UserTemplate {
    id: string;                    // UUID
    role: string;                  // Role name
    password: string;              // Default password
    percentage: number;            // Commission %
    createdAt: DateTime;
    updatedAt: DateTime;
    deletedAt: DateTime | null;
    lastSyncedAt: DateTime | null;
    syncVersion: number;
    needsSync: boolean;
}
```

## Room Model
```javascript
class Room {
    id: string;                    // UUID
    name: string;                  // Room name
    createdAt: DateTime;
    updatedAt: DateTime;
    needsSync: boolean;
}
```

## Auth State Model
```javascript
class AuthState {
    isAuthenticated: boolean;      // Is user logged in?
    user: User | null;            // Current user
    selectedRoom: Room | null;    // Selected room (if applicable)
    needsRoomSelection: boolean;  // Should show room selection?
    isLoading: boolean;           // Loading state
    errorMessage: string | null;  // Error message
}
```

---

# 6. REPOSITORIES (Database Access Layer)

## Users Repository

```javascript
class UsersRepository {
    // Get user by name (for login)
    async getUserByName(name: string): Promise<User | null> {
        return await db.query("SELECT * FROM users WHERE name = ? AND deleted_at IS NULL", [name]);
    }
    
    // Get user by ID
    async getUserById(id: string): Promise<User | null> {
        return await db.query("SELECT * FROM users WHERE id = ? AND deleted_at IS NULL", [id]);
    }
    
    // Get all users (exclude deleted)
    async getAllUsers(): Promise<User[]> {
        return await db.query("SELECT * FROM users WHERE deleted_at IS NULL ORDER BY name");
    }
    
    // Create user
    async createUser(user: User): Promise<void> {
        await db.insert("users", user);
    }
    
    // Update user
    async updateUser(user: User): Promise<void> {
        user.updatedAt = now();
        user.needsSync = true;
        await db.update("users", user);
    }
    
    // Soft delete user
    async deleteUser(id: string): Promise<void> {
        await db.update("users", {
            id: id,
            deletedAt: now(),
            needsSync: true
        });
    }
    
    // Create user from template
    async createUserFromTemplate(templateId: string, userName: string): Promise<User> {
        const template = await getTemplateById(templateId);
        if (!template) throw new Error("Template not found");
        
        const nameParts = userName.trim().split(/\s+/);
        if (nameParts.length < 2) {
            throw new Error("Name must contain at least 2 words");
        }
        
        const user = {
            id: Date.now().toString(),
            name: userName,
            role: template.role,
            password: template.password,
            percentage: template.percentage,
            isTemplateUser: true,
            createdAt: now(),
            updatedAt: now(),
            needsSync: true
        };
        
        await createUser(user);
        return user;
    }
}
```

## Templates Repository

```javascript
class TemplatesRepository {
    // Get all templates
    async getAllTemplates(): Promise<UserTemplate[]> {
        return await db.query("SELECT * FROM templates WHERE deleted_at IS NULL ORDER BY role");
    }
    
    // Get template by ID
    async getTemplateById(id: string): Promise<UserTemplate | null> {
        return await db.query("SELECT * FROM templates WHERE id = ? AND deleted_at IS NULL", [id]);
    }
    
    // Create template
    async createTemplate(template: UserTemplate): Promise<void> {
        await db.insert("templates", template);
    }
    
    // Update template
    async updateTemplate(template: UserTemplate): Promise<void> {
        template.updatedAt = now();
        template.needsSync = true;
        await db.update("templates", template);
    }
    
    // Soft delete template
    async deleteTemplate(id: string): Promise<void> {
        await db.update("templates", {
            id: id,
            deletedAt: now(),
            needsSync: true
        });
    }
}
```

## Rooms Repository

```javascript
class RoomsRepository {
    // Get all rooms
    async getAllRooms(): Promise<Room[]> {
        return await db.query("SELECT * FROM rooms ORDER BY name");
    }
    
    // Get room by ID
    async getRoomById(id: string): Promise<Room | null> {
        return await db.query("SELECT * FROM rooms WHERE id = ?", [id]);
    }
    
    // Create room
    async createRoom(name: string): Promise<Room> {
        const room = {
            id: generateUUID(),
            name: name,
            createdAt: now(),
            updatedAt: now(),
            needsSync: true
        };
        await db.insert("rooms", room);
        return room;
    }
    
    // Update room
    async updateRoom(room: Room): Promise<void> {
        room.updatedAt = now();
        room.needsSync = true;
        await db.update("rooms", room);
    }
    
    // Delete room
    async deleteRoom(id: string): Promise<void> {
        await db.delete("rooms", id);
    }
}
```

## Auth Repository

```javascript
class AuthRepository {
    private currentUser: User | null = null;
    private usersRepository: UsersRepository;
    
    constructor(usersRepository: UsersRepository) {
        this.usersRepository = usersRepository;
    }
    
    // Login
    async login(username: string, password: string): Promise<AuthResult> {
        const user = await this.usersRepository.getUserByName(username);
        
        if (!user) {
            return {
                success: false,
                errorMessage: "Nom d'utilisateur ou mot de passe incorrect"
            };
        }
        
        if (user.password !== password) {
            return {
                success: false,
                errorMessage: "Nom d'utilisateur ou mot de passe incorrect"
            };
        }
        
        this.currentUser = user;
        return {
            success: true,
            user: user
        };
    }
    
    // Logout
    async logout(): Promise<void> {
        this.currentUser = null;
    }
    
    // Check if authenticated
    isAuthenticated(): boolean {
        return this.currentUser !== null;
    }
    
    // Check if admin
    isAdmin(): boolean {
        return this.currentUser?.id === 'admin';
    }
    
    // Get current user
    getCurrentUser(): User | null {
        return this.currentUser;
    }
}
```

---

# 7. CONSTANTS & CONFIGURATION

## App Constants
```javascript
class AppConstants {
    // Predefined user roles
    static userRoles = [
        "Médecin",
        "Infirmier",
        "Infirmière",
        "Assistant 1",
        "Assistant 2",
        "Administrateur"
    ];
    
    // Roles that can have templates and percentages
    static assistantRoles = [
        "Assistant 1",
        "Assistant 2"
    ];
    
    // Admin user ID
    static adminUserId = "admin";
    
    // Validation
    static minNameWords = 2;
    static minPasswordLength = 4;
    static minPercentage = 0;
    static maxPercentage = 100;
}
```

## Database Configuration
```javascript
class DatabaseConfig {
    static dbName = "medicore.db";
    static schemaVersion = 14;
    
    // Database path depends on OS
    static async getDbPath(): Promise<string> {
        const appSupportDir = await getApplicationSupportDirectory();
        return path.join(appSupportDir, this.dbName);
    }
}
```

---

# 8. CRITICAL BUSINESS RULES

## User Management Rules

1. **Name Requirement**: Users MUST have at least 2 words in their name
2. **Role Restriction**: Only 6 predefined roles are allowed
3. **Percentage Rule**: ONLY "Assistant 1" and "Assistant 2" can have percentage
4. **Admin Protection**: User with id='admin' cannot be deleted or modified
5. **Password Minimum**: 4 characters minimum
6. **Soft Delete**: Users are soft-deleted (deleted_at timestamp), not physically deleted

## Room Rules

1. **Room Selection Required**: Médecin, Infirmier/Infirmière, Assistant 1, Assistant 2 MUST select room
2. **Admin No Room**: Administrateur does NOT select room
3. **Unique Names**: Room names should be unique (recommended, not enforced)
4. **Room Presence**: Track in memory, lost on app restart

## Authentication Rules

1. **Case Sensitive**: Usernames and passwords are case-sensitive
2. **Generic Error**: Same error message for wrong username or wrong password (security)
3. **No Auto-Login**: Users must login each time app starts
4. **Nurse Exclusivity**: Only one nurse can be active at a time (tracked in SharedPreferences)

## Template Rules

1. **Pre-Configuration**: Templates define role + password + percentage
2. **Quick Creation**: When creating from template, only name is required
3. **Template Inheritance**: Users created from template inherit ALL template properties
4. **Template Marker**: `is_template_user = true` marks users created this way

---

# 9. UUID GENERATION

Use UUID v4 for:
- Room IDs
- Template IDs

Example implementations:
```javascript
// JavaScript/TypeScript
import { v4 as uuidv4 } from 'uuid';
const id = uuidv4();  // "550e8400-e29b-41d4-a716-446655440000"

// Python
import uuid
id = str(uuid.uuid4())

// Java
import java.util.UUID;
String id = UUID.randomUUID().toString();

// C#
using System;
string id = Guid.NewGuid().ToString();
```

---

# 10. COMPLETE IMPLEMENTATION CHECKLIST

## Phase 1: Database Setup
- [ ] Create SQLite database file
- [ ] Create `users` table with all columns
- [ ] Create `templates` table with all columns
- [ ] Create `rooms` table with all columns
- [ ] Insert default admin user (id='admin', password='1234')
- [ ] Test database queries

## Phase 2: User System
- [ ] Implement UsersRepository with all methods
- [ ] Implement user creation validation (name, password, percentage)
- [ ] Implement user creation (manual)
- [ ] Implement user creation (from template)
- [ ] Implement user update
- [ ] Implement user soft delete
- [ ] Implement user list retrieval
- [ ] Create User Management UI
- [ ] Test all user operations

## Phase 3: Template System
- [ ] Implement TemplatesRepository with all methods
- [ ] Implement template creation validation
- [ ] Implement template CRUD operations
- [ ] Create Template Management UI
- [ ] Test template creation and user generation from template

## Phase 4: Room System
- [ ] Implement RoomsRepository with all methods
- [ ] Implement room creation validation
- [ ] Implement room CRUD operations
- [ ] Create Room Management UI
- [ ] Implement room presence tracking (in-memory)
- [ ] Test room operations

## Phase 5: Authentication System
- [ ] Implement AuthRepository
- [ ] Implement login logic with database lookup
- [ ] Implement password validation
- [ ] Create Login Screen UI
- [ ] Implement nurse activity tracking (SharedPreferences)
- [ ] Test login with admin account
- [ ] Test login with different role types

## Phase 6: Room Selection
- [ ] Create Room Selection Screen UI
- [ ] Implement room selection logic
- [ ] Implement user-to-room assignment
- [ ] Test room selection flow

## Phase 7: Navigation Flow
- [ ] Implement app startup logic
- [ ] Implement login → admin dashboard routing
- [ ] Implement login → room selection routing
- [ ] Implement room selection → dashboard routing
- [ ] Implement logout flow
- [ ] Test complete navigation flow

---

# 11. TESTING SCENARIOS

## Test Scenario 1: Admin Login
```
1. Start app
2. Enter username: "admin"
3. Enter password: "1234"
4. Click LOGIN
5. Expected: Navigate to Admin Dashboard (no room selection)
```

## Test Scenario 2: Doctor Login
```
1. Create user: name="Dr. Ahmed Ben Ali", role="Médecin", password="test123"
2. Logout if logged in
3. Enter username: "Dr. Ahmed Ben Ali"
4. Enter password: "test123"
5. Click LOGIN
6. Expected: Navigate to Room Selection Screen
7. Select a room
8. Click CONFIRMER
9. Expected: Navigate to Dashboard with selected room
```

## Test Scenario 3: User Creation from Template
```
1. Login as admin
2. Go to Template Management
3. Create template: role="Assistant 1", password="assist", percentage=25
4. Go to User Management
5. Click "Create from Template"
6. Select created template
7. Enter name: "Ahmed Ben Said"
8. Click CREATE
9. Expected: New user created with template's role, password, and percentage
10. Verify in user list
```

## Test Scenario 4: Name Validation
```
1. Login as admin
2. Go to User Management
3. Click CREATE
4. Enter name: "Ahmed" (only 1 word)
5. Enter other fields
6. Click CREATE
7. Expected: Error "Le nom doit contenir au moins 2 mots"
```

## Test Scenario 5: Room Creation
```
1. Login as admin
2. Go to Room Management
3. Click CREATE ROOM
4. Enter name: "Cabinet 1"
5. Click CREATE
6. Expected: Room created and appears in list
7. Logout
8. Login as doctor
9. Expected: Room "Cabinet 1" appears in room selection
```

---

# END OF SPECIFICATION

This document contains EVERYTHING needed to implement:
- Login system
- User creation (manual and from template)
- Room creation
- Template system
- All related UI, validation, and business logic

NO other features are documented here. Build these first before moving to other features.
