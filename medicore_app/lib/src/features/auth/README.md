# Authentication Feature

## Overview
Professional login system with hardcoded admin credentials using Cockpit design system.

## Credentials
- **Username**: `admin`
- **Password**: `ophfares2016`

## Architecture

### Data Layer
- `auth_repository.dart` - Handles login/logout logic with hardcoded credentials

### Presentation Layer
- `auth_provider.dart` - Riverpod state management for authentication
- `login_screen.dart` - Professional login UI with Cockpit design

## Features

✅ **Professional Login Screen**
- Deep Navy header with MediCore branding
- Cockpit-styled input fields (inset look)
- Gradient login button with icon
- Error handling with visual feedback
- Loading state with spinner
- Credential hint box

✅ **State Management**
- Riverpod StateNotifier for auth state
- Loading states during login
- Error message handling
- Automatic navigation on successful login

✅ **Security**
- Password field obscured
- Username trimmed and case-insensitive
- Simulated network delay for professional feel

## Usage

The app automatically shows:
- **Login Screen** when user is not authenticated
- **Dashboard Screen** after successful login

Login flow is automatic - just enter credentials and press LOGIN or hit Enter.

## Design System

Uses complete Cockpit design:
- ✅ Steel & Navy color palette
- ✅ Merriweather headings
- ✅ Roboto data/UI text
- ✅ Bordered containers with steel outline
- ✅ Inset input fields
- ✅ Gradient buttons with shadow
- ✅ Professional error handling
