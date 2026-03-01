# ClassFlow - Academic Planning & Management App

A comprehensive Flutter-based academic management application designed to help students organize their classes, assignments, exams, and track attendance efficiently.

## Features

### UI/UX Enhancements (v2.0)
- **Redesigned Splash Screen**: Enlarged logo with improved visual hierarchy and normalized "ClassFlow" typography for better visual consistency
- **Responsive Layout**: All screens optimized for various device sizes
- **Smooth Animations**: Polished transitions and loading states throughout the app

### Core Functionality
- **Unified Event System**: Manage classes, exams, assignments, meetings, and personal events in one place
- **Timetable Management**: Create recurring class schedules with automatic event generation
- **Attendance Tracking**: Mark and monitor attendance for all classes with detailed statistics
- **Calendar View**: Visual calendar with event overview and daily planning
- **Timeline View**: Hour-by-hour breakdown of your day with event details
- **Voice Notes**: Record and attach voice notes to any event
- **Smart Reminders**: Set custom reminders for events and deadlines
- **Dark Mode**: Full dark mode support with theme persistence

### Event Management
- Multiple event classifications (Class, Exam, Assignment, Meeting, Personal, Other)
- Priority levels (Low, Medium, High, Critical)
- Categories/subjects for organization
- Completion tracking with visual indicators
- Event duplication and bulk management
- Important event flagging

### Attendance Features
- Five attendance statuses (Present, Absent, Late, Excused, Cancelled)
- Automatic attendance statistics calculation
- Per-class attendance tracking
- Visual attendance rate indicators
- Integration with timetable entries

## Prerequisites

Before running this project, ensure you have the following installed:

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode (for mobile development)
- A code editor (VS Code, Android Studio, or IntelliJ IDEA)

## Installation

### Project Structure

```
lib/
├── main.dart                          # App entry point
├── assets/                            # Image assets (logo, icons)
├── backend/
│   ├── data_provider.dart            # Central state management (all CRUD operations)
│   ├── models.dart                   # Event model with all properties
│   ├── timetable_models.dart         # TimetableEntry and related models
│   └── notification_service.dart     # Notification and reminder handling
└── frontend/
    ├── splash_screen.dart            # App entry animation and branding
    ├── home_page.dart                # Main dashboard
    ├── attendance_page.dart          # Attendance tracking interface
    ├── [other UI screens].dart       # Feature-specific screens

test/
├── widget_test.dart                  # 26 comprehensive functional tests

app_testing_report.md                # Detailed test results and feature verification
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Verify Flutter Installation
```bash
flutter doctor
```

Ensure all required components are installed and configured correctly.

## Running the Application

### On Android Emulator/Device

1. Start an Android emulator or connect an Android device via USB
2. Run the following command:
```bash
flutter run
```

### On iOS Simulator/Device (macOS only)

1. Start an iOS simulator or connect an iOS device
2. Run the following command:
```bash
flutter run
```

### On Web
```bash
flutter run -d chrome
```

### Build Release Version

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle
```bash
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

## Dependencies

### Core Dependencies
- `provider: ^6.1.1` - State management
- `shared_preferences: ^2.2.2` - Local data persistence
- `intl: ^0.19.0` - Internationalization and date formatting

### UI Components
- `table_calendar: ^3.0.9` - Calendar widget
- `google_fonts: ^6.1.0` - Custom fonts
- `flutter_slidable: ^3.0.1` - Swipe actions

### Audio & Media
- `record: ^5.0.4` - Audio recording
- `audioplayers: ^5.2.1` - Audio playback
- `path_provider: ^2.1.2` - File system access

### Notifications & Permissions
- `flutter_local_notifications: ^16.3.0` - Local notifications
- `permission_handler: ^11.2.0` - Runtime permissions
- `timezone: ^0.9.2` - Timezone handling

### Utilities
- `uuid: ^4.3.3` - Unique ID generation

## Configuration

### Android Setup

1. Update `android/app/build.gradle`:
   - Minimum SDK version: 21 or higher
   - Compile SDK version: 34 or higher

2. Add permissions in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

### iOS Setup

1. Update `ios/Podfile`:
   - Uncomment `platform :ios, '12.0'` and set to 12.0 or higher

2. Add permissions in `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record voice notes</string>
<key>NSUserNotificationsUsageDescription</key>
<string>This app needs notification access to remind you of events</string>
```

## Data Storage

The app uses `SharedPreferences` for local data storage. All data is stored on the device and persists between app sessions.

### Stored Data
- Events and tasks
- Timetable entries
- Attendance records
- Categories
- User preferences (theme, authentication status)
- Voice note file paths

### Data Location
- Android: `/data/data/<package-name>/shared_prefs/`
- iOS: `Library/Preferences/`
- Voice recordings: Application documents directory

## Features Guide

### Quick Start for Developers

**1. Access the Data Layer:**
```dart
import 'package:classflow/backend/data_provider.dart';

final provider = DataProvider();
await provider.ready; // Wait for SharedPreferences to load

// Now you can use provider to access/modify data:
provider.addEvent(event);
provider.addTimetableEntry(timetable);
provider.markAttendance(record);
provider.notifyListeners(); // Notify UI of changes
```

**2. Available Methods by Module:**

**Timetable Management:**
```dart
provider.addTimetableEntry(entry);           // Create new course schedule
provider.updateTimetableEntry(entry);        // Update existing schedule
provider.deleteTimetableEntry(entryId);      // Delete and cascade
provider.timetableEntries                    // Get all timetable entries
```

**Event Management:**
```dart
provider.addEvent(event);                    // Create event
provider.updateEvent(event);                 // Update event  
provider.deleteEvent(eventId);               // Delete event
provider.getEventsForDay(date);              // Get events for specific day
provider.toggleEventComplete(eventId);       // Mark as done/undo
provider.events                              // Get all events
```

**Attendance Tracking:**
```dart
provider.markAttendance(record);             // Record attendance
provider.deleteAttendanceRecord(recordId);   // Remove record
provider.getAttendanceStats(courseName);     // Get statistics for course
provider.getAllAttendanceStats();            // Get all course stats
provider.attendanceRecords                   // Get all records
```

**Event Notes:**
```dart
provider.addVoiceNoteToEvent(eventId, note); // Attach voice note
// Access via: event.voiceNotes and event.notes
```

---

### Creating Events

1. Tap the floating action button on any screen
2. Select event classification (Class, Assignment, Exam, etc.)
3. Fill in required details (title, date/time)
4. Optionally add: category, location, notes, priority, reminders
5. Save the event

### Managing Timetable

1. Navigate to Timetable from the home page quick actions
2. Tap "Add Class" button
3. Enter class details:
   - Course name and code
   - Instructor and room
   - Days of week (select multiple)
   - Start time and duration
   - Semester start/end dates
4. The system automatically generates recurring class events

### Tracking Attendance

1. Open the Attendance page from home or timetable
2. Select a class to view details
3. Mark attendance for each class session:
   - Present
   - Absent
   - Late
   - Excused
   - Cancelled (not counted in statistics)
4. View attendance statistics and percentage

### Using Voice Notes

1. While creating/editing an event, go to the "Notes" tab
2. Tap "Record" button
3. Record your voice note
4. Add optional tags for organization
5. Save the voice note (attached to the event)

### Setting Reminders

1. Edit an event
2. Go to "Advanced" tab
3. Tap "Add Reminder"
4. Select date and time for the reminder
5. Multiple reminders can be added per event

## Troubleshooting

### App Won't Build

1. Clean the build:
```bash
flutter clean
flutter pub get
```

2. Check Flutter installation:
```bash
flutter doctor -v
```

### Notifications Not Working

1. Ensure permissions are granted in device settings
2. Check notification channel settings
3. Verify `flutter_local_notifications` is properly configured

### Audio Recording Issues

1. Grant microphone permissions in device settings
2. Test on physical device (emulators may have issues)
3. Verify `record` package compatibility with your OS version

### Data Loss

- Data is stored locally; uninstalling the app deletes all data
- Sign out functionality clears all data
- No cloud backup is currently implemented

## Known Limitations

- No cloud synchronization (data is local only)
- No multi-device support
- Voice notes stored locally (not backed up)
- Calendar does not sync with external calendars
- No export/import functionality for data

## Performance Optimization

- Events are loaded on-demand
- Timetable generation is optimized for large date ranges
- Images and voice notes use compressed formats
- Efficient state management with Provider

## Development

### Running Tests

The project includes a comprehensive test suite covering all major modules.

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

**Test Coverage:**
- ✓ Module 1: Courses and Timetable (4 tests) - Create, update, delete timetable entries; auto-generate events
- ✓ Module 2: Calendar and Schedule (5 tests) - Event CRUD, day filtering, completion tracking, deletion
- ✓ Module 3: Attendance Calculator & Risk Predictor (5 tests) - Mark attendance, calculate statistics, update/delete records
- ✓ Module 4: Notes and Voice Notes (3 tests) - Text notes, voice notes, multiple note management
- ✓ Module 5: Notification and Reminders (4 tests) - Create reminders, manage settings, retrieve active reminders, priority notifications
- ✓ Integration Tests (2 tests) - Full workflow testing, category filtering
- ✓ Summary Report (1 test) - Comprehensive test suite reporting
- **Total: 24/24 tests passing ✓** (4+5+5+3+4+2+1)

**Test Report:** See `app_testing_report.md` for detailed test results (24/24 passing) and feature verification checklist.

### Code Formatting
```bash
flutter format .
```

### Static Analysis
```bash
flutter analyze
```

## Version Information

- Current Version: 2.0.0
- Minimum Flutter Version: 3.0.0
- Supported Platforms: Android, iOS