# The Cockpit Design System

## Philosophy

MediCore looks like a **cockpit**, not a magazine. 

Modern apps use floating cards with soft shadows on light backgrounds. MediCore uses **rigid panes with visible borders** on a darker canvas. This creates:

1. **Authority** - Looks like specialized medical equipment
2. **Density** - Maximum information without scrolling  
3. **Timelessness** - Won't look dated in 5 years
4. **Professionalism** - Medical journal aesthetic

---

## Color Palette: Steel & Navy

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Primary** | Deep Navy | `#1B263B` | Sidebar, Top Header, Window Chrome |
| **Accent** | Professional Blue | `#415A77` | Active buttons, highlights |
| **Background** | Canvas Grey | `#E0E1DD` | Main app background (anti-glare) |
| **Surface** | Paper White | `#FFFFFF` | Data input areas ONLY |
| **Borders** | Steel Outline | `#778DA9` | **Key Element** - Every pane has 1px border |

### Status Colors
- **Critical/Error**: `#D32F2F` (Red)
- **Warning/Pending**: `#ED6C02` (Orange)
- **Success/Paid**: `#2E7D32` (Green)
- **Inactive**: `#9E9E9E` (Grey)

---

## Typography: The Editorial Hybrid

### Headings (Serif)
**Merriweather** - Classic, book-like, commands respect
- Page Title: 28px Bold
- Section Header: 20px Bold
- Subsection: 16px Semi-Bold

Effect: Medical journal or legal document aesthetic

### Data/UI (Sans-Serif)
**Roboto** - Clean, mechanical, legible at small sizes
- Grid Headers: 11px Bold ALL CAPS
- Grid Cells: 13px Regular (with tabular figures)
- Buttons: 13px Medium
- Inputs: 14px Regular

Effect: Precise, data-focused, technical

---

## Layout System: Panes & Splitters

### No Floating Cards
❌ Don't use: Cards with shadows floating on grey background  
✅ Do use: Rigid panes with 1px solid borders

### Pane Structure
Every section is a **bordered pane**:

```
┌─────────────────────────────┐ ← 1px Steel Outline border
│ Title Bar (35px height)     │ ← #D3D6DB background
├─────────────────────────────┤ ← 1px bottom border
│                             │
│  Content Area               │ ← Paper White background
│  (Patient list, form, etc)  │
│                             │
└─────────────────────────────┘
```

### Multi-Pane Layouts
Use visible splitters to divide the screen:

```
┌──────────┬──────────────────┐
│          │                  │
│ Patient  │  Patient Details │
│  List    │                  │
│          │                  │
├──────────┴──────────────────┤
│                             │
│      Billing Information    │
│                             │
└─────────────────────────────┘
```

---

## UI Components

### 1. Buttons (Weighty & Tactile)

**Style**: Semi-skeuomorphic
- Subtle vertical gradient (light to dark blue)
- 1px darker border
- 1px bottom shadow for "thickness"
- 4px border radius (very slight)

```dart
CockpitButton(
  label: 'Save Patient',
  icon: Icons.save,
  onPressed: () {},
)
```

### 2. Input Fields (Inset Look)

**Style**: Looks recessed into the surface
- Background: `#F8F9FA` (slightly off-white)
- Border: 1px solid `#A0AAB4`
- Focus: Border becomes 2px Deep Navy `#1B263B`
- No glow, no animation

```dart
CockpitInput(
  label: 'Patient Name',
  hint: 'Enter name...',
)
```

### 3. Data Grid (The Heart)

**Style**: Visible spreadsheet
- Vertical & Horizontal grid lines (1px `#CFD8DC`)
- Header: Deep Navy background, white ALL CAPS text
- Zebra striping: Alternating white / light grey rows
- Dense: 35px row height (NOT touch-friendly, desktop optimized)

```dart
DataGrid(
  headers: ['ID', 'PATIENT NAME', 'DATE', 'STATUS'],
  rows: [
    ['001', 'John Doe', '2024-01-15', 'Paid'],
    ['002', 'Jane Smith', '2024-01-16', 'Pending'],
  ],
)
```

### 4. Panes

Every section has a title bar and border:

```dart
CockpitPane(
  title: 'Appointments',
  child: DataGrid(...),
)
```

---

## Fixed Canvas Scaling (1440x900)

### The Problem
Responsive design = unpredictable layouts. Buttons move, text wraps differently.

### The Solution
**Design for ONE resolution**: 1440 x 900

#### How It Works
1. Designer creates UI at exactly 1440x900 in Figma
2. Developer codes with exact pixel values: `width: 200`, `height: 50`
3. App **scales proportionally** on any screen:
   - Small laptop (1366x768): App zooms out slightly
   - 4K monitor (3840x2160): App zooms in (everything bigger)
   - Layout NEVER shifts, text NEVER reflows

#### Implementation
```dart
// Wrap entire app in CanvasScaler
CanvasScaler(
  child: MaterialApp(...),
)

// Use .w, .h, .sp for responsive values
Container(
  width: 200.w,   // 200px on 1440px screen, scales on other sizes
  height: 50.h,
  child: Text(
    'Button',
    style: TextStyle(fontSize: 14.sp),
  ),
)
```

### Benefits
- ✅ Zero layout bugs ("button moved on large screen")
- ✅ Pixel-perfect designer control
- ✅ Faster development (no flex, wrap, or media queries)
- ✅ Consistent experience on all screens

---

## Desktop-Specific Features

### 1. Custom Window Chrome
Window title bar matches Deep Navy theme:
- Custom close/minimize/maximize buttons
- App title in window bar
- Integrated with OS

### 2. No Bounce Scroll
Standard Flutter scrolls like a phone (bouncy). MediCore uses `ClampingScrollPhysics`:
- Scrolling stops instantly at boundaries
- Feels like Windows/Mac desktop app

### 3. Minimum Window Size
App enforces minimum: 1024 x 600
- Below this, shows warning
- Prevents UI from becoming unusable

---

## Implementation Checklist

### Required Packages
- ✅ `flutter_screenutil` - Fixed canvas scaling
- ✅ `bitsdojo_window` - Custom window chrome
- ✅ `multi_split_view` - Multi-pane splitters
- ✅ `google_fonts` - Merriweather + Roboto

### Core Files Created
- ✅ `lib/src/core/theme/medicore_colors.dart` - Steel & Navy palette
- ✅ `lib/src/core/theme/medicore_typography.dart` - Merriweather + Roboto
- ✅ `lib/src/core/theme/medicore_dimensions.dart` - 1440x900 canvas
- ✅ `lib/src/core/ui/canvas_scaler.dart` - Fixed scaling wrapper
- ✅ `lib/src/core/ui/cockpit_pane.dart` - Bordered pane component
- ✅ `lib/src/core/ui/cockpit_button.dart` - Gradient button
- ✅ `lib/src/core/ui/cockpit_input.dart` - Inset input field
- ✅ `lib/src/core/ui/data_grid.dart` - Dense spreadsheet grid
- ✅ `lib/src/core/ui/window_init.dart` - Custom window setup
- ✅ `lib/src/core/ui/scroll_behavior.dart` - Desktop scroll physics

---

## Example: Building a Patient Screen

```dart
import 'package:flutter/material.dart';
import 'package:medicore_app/src/core/ui/cockpit_pane.dart';
import 'package:medicore_app/src/core/ui/data_grid.dart';
import 'package:medicore_app/src/core/ui/cockpit_button.dart';
import 'package:multi_split_view/multi_split_view.dart';

class PatientScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiSplitView(
      children: [
        // Left: Patient List
        CockpitPane(
          title: 'Patients',
          actions: [
            CockpitButton(
              label: 'New',
              icon: Icons.add,
              onPressed: () {},
            ),
          ],
          child: DataGrid(
            headers: ['ID', 'NAME', 'PHONE', 'LAST VISIT'],
            rows: [
              ['001', 'John Doe', '+1234567890', '2024-01-15'],
              ['002', 'Jane Smith', '+0987654321', '2024-01-16'],
            ],
          ),
        ),
        
        // Right: Patient Details
        CockpitPane(
          title: 'Patient Details',
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CockpitInput(label: 'Full Name'),
                  SizedBox(height: 12),
                  CockpitInput(label: 'Phone Number'),
                  SizedBox(height: 12),
                  CockpitButton(
                    label: 'Save Changes',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

---

## Visual Reference

### Before (Modern App Style)
```
┌─────────────────────────┐
│                         │
│   ┌───────────────┐     │ ← Floating cards
│   │  Card         │     │   with shadows
│   │               │     │
│   └───────────────┘     │
│                         │
│   ┌───────────────┐     │
│   │  Card         │     │
│   └───────────────┘     │
│                         │
└─────────────────────────┘
```

### After (Cockpit Style)
```
┏━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Patients            [+]┃ ← Title bar
┣━━━━━━━━━━━━━━━━━━━━━━━┫
┃ ID │ NAME   │ PHONE   ┃ ← Grid header
┃────┼────────┼─────────┃
┃001 │John Doe│555-0123 ┃ ← Dense rows
┃002 │Jane    │555-0456 ┃   with visible
┃003 │Bob     │555-0789 ┃   grid lines
┗━━━━━━━━━━━━━━━━━━━━━━━┛
```

---

## Summary

The Cockpit design system transforms MediCore from a "modern web app" into **professional medical software**:

✅ **Dense** - Maximum information per screen  
✅ **Rigid** - Panes with visible borders, not floating cards  
✅ **Authoritative** - Steel & Navy colors, Merriweather serif  
✅ **Consistent** - Fixed canvas (1440x900), scales perfectly  
✅ **Desktop-First** - Custom chrome, no bounce, compact layout  

**Result**: Looks expensive, feels fast, commands respect.
