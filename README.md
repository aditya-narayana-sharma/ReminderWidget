# ReminderWidget for macOS and iOS

## Overview

ReminderWidget is a native Swift-based widget extension for iOS 17 and macOS 14+ that integrates seamlessly with the Apple Reminders app. It provides a customizable glanceable interface that lets users view their upcoming tasks filtered by specific lists, tags, and time constraints. Built using SwiftUI, AppIntents, and WidgetKit, this widget offers support for interactive configuration directly from the widget gallery or Shortcuts app.

This widget project is ideal for developers looking to:

* Learn how to integrate WidgetKit with Apple's Reminders.
* Filter and preview upcoming reminders within the next 3 hours.
* Provide users with the option to toggle URL previews.
* Select reminder lists and tags dynamically.

---

## Features

* ⏳ **Upcoming Reminder Filter:** Displays reminders that are due within the next 3 hours from the Apple Reminders app.
* 📅 **Reminder List Selector:** Allows users to filter reminders by selecting a specific Reminder List from those already created in the Apple Reminders app.
* 🏷️ **Tag Selector:** Supports optional filtering by tags (hashtags from Reminders).
* 🔍 **URL Preview Toggle:** Lets users choose whether to show or hide URLs associated with reminder notes.
* 🌐 **Multi-platform:** Compatible with iOS 17+ and macOS 14+.
* ⚖️ **SwiftData-Ready:** Architecture supports migration to SwiftData or EventKit APIs for extended logic.
* 📋 **Interactive AppIntent Configuration:** Select widget preferences (List, Tags, URL Display) directly from the widget's edit mode.

---

## Project Structure

```
ReminderWidget/
├── ReminderWidgetApp/           # Main App Target
│   ├── ContentView.swift
│   ├── ReminderWidget.swift
│   └── ReminderWidgetApp.swift
│
├── ReminderWidgetExtension/    # Widget Extension Target
│   ├── Assets.xcassets/
│   ├── AppIntent.swift
│   ├── Entry.swift
│   ├── Info.plist
│   ├── Intent.swift
│   ├── ReminderFetcher.swift
│   ├── ReminderSelectionIntent.swift
│   ├── ReminderSelectionIntentHandler.swift
│   ├── ReminderWidgetExtension.swift
│   ├── ReminderWidgetExtensionBundle.swift
│   ├── ReminderWidgetView.swift
│   └── TimelineProvider.swift
│
├── ReminderWidgetTests/
├── ReminderWidgetUITests/
└── README.md
```

---

## Setup Instructions

### Requirements

* Xcode 15+
* macOS 14+ / iOS 17+
* Swift 5.9+

### Steps to Run:

1. **Clone the repository:**

   ```bash
   git clone https://github.com/yourname/ReminderWidget.git
   ```

2. **Open Xcode Project:**
   Open `ReminderWidget.xcodeproj` or `ReminderWidget.xcworkspace` if using packages.

3. **Set Widget Target Permissions:**

   * Navigate to `ReminderWidgetExtension` target.
   * Ensure it has access to the Reminders entitlement (configured via App Sandbox and Privacy).

4. **Build & Run:**

   * Select either the `ReminderWidgetApp` or `ReminderWidgetExtension` and run on a simulator or device.

5. **Deploy Widget:**

   * Long press on your Home Screen or Desktop.
   * Tap `+`, choose `ReminderWidget`, and add to view.
   * Long-press on widget → Tap "Edit Widget" → Configure Reminder List, Tags, and URL Display.

---

## Intent Parameters Explained

### `reminderList`

* **Type:** `String?`
* **Purpose:** Filters reminders to only show those from the selected list.
* **Configuration:** Uses `ReminderListOptionsProvider` to offer predefined options (e.g., Personal, Work, Groceries).

### `tags`

* **Type:** `[String]?`
* **Purpose:** Optional filtering of reminders containing specific tags (e.g., `#urgent`, `#home`).

### `showURL`

* **Type:** `Bool`
* **Default:** `true`
* **Purpose:** Toggles whether the note's URL should be visible in the widget.

---

## Widget Sizes Supported

* 📏 Small: Title and time of next due reminder.
* 🔄 Medium: Next two reminders with due times.
* 🌐 Accessory Inline & Rectangular: For iOS Lockscreen or macOS Notification Center.

> ⚠️ Note: `accessoryRectangular` is not available on macOS. Proper conditional compilation is used.

---

## Known Issues

* AppIntent preview URL launching may not work in macOS due to `openURL` limitation.
* The tag filtering logic is basic and can be improved by parsing `EKReminder` structured notes.
* If no reminder is due in the next 3 hours, a fallback reminder is shown from the default list.

---

## Planned Enhancements

* [ ] Enable dynamic list and tag population via `EventKit`.
* [ ] Integrate SwiftData for local persistence and caching.
* [ ] Add Deep Link support for each reminder item.
* [ ] Add Siri Suggestions for individual tags or lists.
* [ ] Custom colors and themes per list.

---

## GitHub Commit Message ✅

```text
✨ Add ReminderWidget for iOS/macOS with dynamic AppIntent configuration

- Implements TimelineProvider and ReminderEntry with support for WidgetKit
- Integrates SwiftUI-based widget for Apple Reminders filtering by list & tags
- Adds custom AppIntent for Reminder List, Tags, and URL toggle
- Includes fallback logic if no reminders due in next 3 hours
- Adds support for rectangular, inline, and system widget families
- Fixes cross-platform compatibility and event permission management
```

---

## License

This project is licensed under the MIT License - see the [LICENSE.txt](./LICENSE.txt) file for details.

---

## Author

**Aditya Sharma**

> Swift Developer | Analytics Engineer | Automation Enthusiast

If you find this useful, consider giving a star ⭐ and contributing!

---

## Contribution

Want to extend this widget?

* Fork this repo → Create a branch → Add new widget styles or settings → Pull Request

We welcome improvements like:

* SwiftData integration
* More flexible tag parsing
* Localization support
* WatchOS compatibility

Thanks for exploring ReminderWidget!

