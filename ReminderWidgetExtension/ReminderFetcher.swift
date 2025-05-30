//
//  ReminderFetcher.swift
//  ReminderWidgetExtensionExtension
//
//  Created by Aditya Sharma on 27.05.25.
//

import Foundation
import EventKit

// MARK: - Custom Errors

enum ReminderAccessError: Error {
    case denied
    case restricted // EKAuthorizationStatus restricted
    case fullAccessRequired // EKAuthorizationStatus fullAccessRequired (iOS 17+)
    case unknownAuthorizationStatus
    case failedWithError(Error) // To wrap underlying errors from the framework
}

enum ReminderOperationError: Error {
    case saveFailed(Error)
    case invalidInput(reason: String)
    case listNotFound(identifier: String)
    case cannotFindDefaultList
    case other(Error) // For unexpected errors during operations
}


/// Struct to hold detailed information about an upcoming reminder.
struct UpcomingReminderInfo: Identifiable {
    let id = UUID() // Make it Identifiable for ForEach
    let title: String
    let dueDate: Date
    let listName: String
    let notes: String?
    let primaryURL: String? // EKReminder often has a URL field
}

/// Struct to hold reminder list (EKCalendar) details.
struct ReminderListInfo: Identifiable { // Conform to Identifiable if it's useful for UI lists
    let id: String // Use calendarIdentifier for id
    let title: String
    var sampleReminders: [ReminderItemInfo] = [] // To store a few sample reminders for overview

    // Custom initializer if direct mapping isn't desired or additional logic is needed
    init(id: String, title: String, sampleReminders: [ReminderItemInfo] = []) {
        self.id = id
        self.title = title
        self.sampleReminders = sampleReminders
    }
}

/// Struct to hold detailed information for a reminder item.
struct ReminderItemInfo: Identifiable {
    let id = UUID() // Make it Identifiable for ForEach
    let title: String
    let dueDate: Date?
    let notes: String?
    let primaryURL: String?
    let isCompleted: Bool
    // listName is not needed as it's implied by the fetch context
}

/// A simple helper to fetch reminders using EventKit
struct ReminderFetcher {

    // MARK: - Permission Helper
    private static func requestReminderAccess(for store: EKEventStore) async throws {
        // Check current authorization status first to avoid unnecessary prompts
        // or to handle specific statuses like .restricted or .denied proactively.
        let currentStatus = EKEventStore.authorizationStatus(for: .reminder)

        switch currentStatus {
        case .authorized, .fullAccess: // .fullAccess is iOS 14+ for specific list access
            return // Already authorized
        case .denied:
            throw ReminderAccessError.denied
        case .restricted:
            throw ReminderAccessError.restricted
        case .notDetermined:
            // This is where we request access.
            break // Continue to request access
        case .writeOnly: // iOS 17+
             // For adding reminders, writeOnly might be sufficient.
             // However, if we later need to read for duplicate checks or something,
             // this might need adjustment. For now, assume writeOnly is okay for adding.
            if #available(iOS 17.0, *) { // Ensure this case is only considered on iOS 17+
                 print("Access is write-only. Proceeding with adding reminder.")
                 return
            } else {
                // Should not happen on older OS versions
                throw ReminderAccessError.unknownAuthorizationStatus
            }
        @unknown default:
            throw ReminderAccessError.unknownAuthorizationStatus
        }

        // Requesting access
        var granted = false
        var accessError: Error?

        if #available(iOS 17.0, macOS 14.0, *) {
            // For iOS 17+, requestFullAccessToReminders is preferred if you might also read.
            // If only adding, requestWriteOnlyAccessToReminders could be used.
            // Let's stick to full access for consistency with other functions for now.
            do {
                granted = try await store.requestFullAccessToReminders()
            } catch {
                accessError = error
            }
        } else {
            // Fallback for older OS versions
            granted = await withCheckedContinuation { continuation in
                store.requestAccess(to: .reminder) { result, err in
                    if let err = err {
                        accessError = err
                        continuation.resume(returning: false) // Resume with false on error
                    } else {
                        continuation.resume(returning: result)
                    }
                }
            }
        }

        if let accessError = accessError {
            // If there was an error during the request itself
            print("Error during reminder access request: \(accessError.localizedDescription)")
            throw ReminderAccessError.failedWithError(accessError)
        }

        if !granted {
            // This path is taken if requestAccess (older OS) returns false without error,
            // or requestFullAccessToReminders (newer OS) returns false or throws.
            // Re-check status to throw a more specific error if possible.
            let newStatus = EKEventStore.authorizationStatus(for: .reminder)
            switch newStatus {
            case .denied: throw ReminderAccessError.denied
            case .restricted: throw ReminderAccessError.restricted
            default: throw ReminderAccessError.denied // Default to denied if not granted and status isn't more specific
            }
        }
    }
    
    // MARK: - Fetching Reminders (Existing Functions)

    static func fetchNextReminder(fromList listName: String?, completion: @escaping (String?, Date?) -> Void) {
        let store = EKEventStore()

        // Widget cannot prompt for permissions. You must run the main app first.
        // EKEventStore.requestFullAccessToReminders is the modern way for just reminders
        store.requestFullAccessToReminders { granted, error in
            guard granted, error == nil else {
                print("Reminder access not granted or failed: \(String(describing: error))")
                completion(nil, nil)
                return
            }
            
            let allCalendars = store.calendars(for: .reminder)
            let selectedCalendars: [EKCalendar]? = {
                guard let identifier = listName, !identifier.isEmpty else { return nil } // Use nil for all calendars if listName is empty or nil
                return allCalendars.filter { $0.title == identifier }
            }()
            
            let predicate = store.predicateForIncompleteReminders(
                withDueDateStarting: Date(), // Start from now
                ending: nil, // No specific end date, effectively "all future"
                calendars: selectedCalendars
            )
            store.fetchReminders(matching: predicate) { reminders in
                let now = Date()
                // The original logic for fetchNextReminder had a 3-hour window.
                // We keep this behavior for this specific function.
                let threeHoursFromNow = Calendar.current.date(byAdding: .hour, value: 3, to: now)!

                let upcomingReminders: [(String, Date)] = reminders?
                    .filter { !$0.isCompleted } // Ensure reminder is not completed
                    .compactMap { reminder in
                        guard let title = reminder.title, // Title is non-optional
                              let dueComponents = reminder.dueDateComponents,
                              let dueDate = Calendar.current.date(from: dueComponents),
                              dueDate >= now && dueDate <= threeHoursFromNow else { // Check due date within window
                            return nil
                        }
                        return (title, dueDate)
                    }
                    .sorted { $0.1 < $1.1 } ?? [] // Sort by due date

                if let next = upcomingReminders.first {
                    completion(next.0, next.1)
                    return
                }

                // Fallback: get the earliest reminder if no reminders are found in the 3-hour window
                // This part of the logic might need adjustment based on how strictly "next" reminder is defined.
                // For now, it mirrors the original behavior.
                if let reminders = reminders?.filter({ !$0.isCompleted }) { // Ensure not completed for fallback too
                    print("No matching reminders found in 3-hour window for fetchNextReminder, falling back to earliest incomplete reminder.")
                    let fallback: (String, Date)? = reminders
                        .compactMap { reminder in
                            guard let title = reminder.title,
                                  let dueComponents = reminder.dueDateComponents,
                                  let dueDate = Calendar.current.date(from: dueComponents) else {
                                return nil
                            }
                            return (title, dueDate)
                        }
                        .sorted { $0.1 < $1.1 } // Sort by due date
                        .first

                    completion(fallback?.0, fallback?.1)
                } else {
                    completion(nil, nil)
                }
            }
        })
    }

    static func fetchNextReminderAsync(fromList listName: String?) async -> (String?, Date?) {
        await withCheckedContinuation { continuation in
            fetchNextReminder(fromList: listName) { title, dueDate in
                continuation.resume(returning: (title, dueDate))
            }
        }
    }

    static func fetchAllUpcomingReminders(forNextHours hours: Int, fromListNamed listName: String?) async -> [UpcomingReminderInfo] {
        let store = EKEventStore()

        // Request access to reminders
        // Note: In a real app, you'd handle the 'false' case more gracefully,
        // perhaps by informing the user or returning a specific error type.
        let hasAccess = await withCheckedContinuation { continuation in
            // EKEventStore.requestFullAccessToReminders is available from iOS 17, macOS 14
            // For broader compatibility, you might need to use requestAccess(to: .reminder, completion:)
            // However, the original code used requestFullAccessToEvents, which is also a newer API.
            // Sticking to a similar pattern for now.
            if #available(iOS 17.0, macOS 14.0, *) {
                store.requestFullAccessToReminders { granted, error in
                    if let error = error {
                        print("Error requesting reminder access: \(error.localizedDescription)")
                        continuation.resume(returning: false)
                        return
                    }
                    continuation.resume(returning: granted)
                }
            } else {
                // Fallback for older OS versions
                store.requestAccess(to: .reminder) { granted, error in
                    if let error = error {
                        print("Error requesting reminder access (legacy): \(error.localizedDescription)")
                        continuation.resume(returning: false)
                        return
                    }
                    continuation.resume(returning: granted)
                }
            }
        }

        guard hasAccess else {
            print("Reminder access not granted.")
            return []
        }

        // Determine the end date for the predicate
        let endDate = Calendar.current.date(byAdding: .hour, value: hours, to: Date())!

        // Fetch appropriate EKCalendars
        let allCalendars = store.calendars(for: .reminder)
        let selectedCalendars: [EKCalendar]?
        if let listName = listName, !listName.isEmpty {
            selectedCalendars = allCalendars.filter { $0.title.localizedCaseInsensitiveCompare(listName) == .orderedSame }
            if selectedCalendars?.isEmpty ?? true {
                 print("No calendar found with name '\(listName)'. Fetching from all lists instead if any reminder matches criteria.")
                // If no specific calendar found, it might be better to return empty or fetch from all.
                // For now, let's allow predicate to use nil (all calendars) if specific list not found.
                // Or, strictly return [] if listName is provided but not found.
                // Current choice: if list provided but not found, effectively searches 0 calendars matching criteria.
                // This means the predicate below will correctly return no reminders if that list doesn't exist.
            }
        } else {
            selectedCalendars = nil // Fetch from all lists
        }
        
        // Create the predicate for incomplete reminders
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: Date(), // Start from the current date
            ending: endDate,             // End at the calculated future date
            calendars: selectedCalendars // Filter by selected calendars, or nil for all
        )

        // Fetch EKReminder objects
        // This part needs to be asynchronous.
        let fetchedReminders: [EKReminder] = await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
        
        var upcomingRemindersInfo: [UpcomingReminderInfo] = []

        for reminder in fetchedReminders {
            // Ensure reminder is not completed (though predicate should handle this)
            guard !reminder.isCompleted else { continue }

            // Extract title (non-optional)
            guard let title = reminder.title, !title.isEmpty else { continue }

            // Extract and convert dueDateComponents to Date
            guard let dueDateComponents = reminder.dueDateComponents,
                  let dueDate = Calendar.current.date(from: dueDateComponents) else {
                continue // Skip if no valid due date
            }

            // Extract listName (calendar title)
            let reminderListName = reminder.calendar.title

            // Extract notes
            let notes = reminder.notes

            // Extract primaryURL (from reminder.url first)
            let primaryURL = reminder.url?.absoluteString
            
            //Less common: check structuredLocation for a URL. This might require more specific logic if needed.
            // let primaryURL = reminder.url?.absoluteString ?? reminder.structuredLocation?.url?.absoluteString


            let info = UpcomingReminderInfo(
                title: title,
                dueDate: dueDate,
                listName: reminderListName,
                notes: notes,
                primaryURL: primaryURL
            )
            upcomingRemindersInfo.append(info)
        }

        // Sort the resulting array by dueDate in ascending order
        upcomingRemindersInfo.sort { $0.dueDate < $1.dueDate }

        return upcomingRemindersInfo
    }

    static func fetchAllReminderLists() async -> [ReminderListInfo] {
        let store = EKEventStore()

        let hasAccess = await withCheckedContinuation { continuation in
            if #available(iOS 17.0, macOS 14.0, *) {
                store.requestFullAccessToReminders { granted, error in
                    if let error = error {
                        print("Error requesting reminder access for lists: \(error.localizedDescription)")
                        continuation.resume(returning: false)
                        return
                    }
                    continuation.resume(returning: granted)
                }
            } else {
                // Fallback for older OS versions
                store.requestAccess(to: .reminder) { granted, error in
                    if let error = error {
                        print("Error requesting reminder access for lists (legacy): \(error.localizedDescription)")
                        continuation.resume(returning: false)
                        return
                    }
                    continuation.resume(returning: granted)
                }
            }
        }

        guard hasAccess else {
            print("Reminder access not granted for fetching lists.")
            return []
        }

        let ekCalendars = store.calendars(for: .reminder)
        
        var reminderLists: [ReminderListInfo] = ekCalendars.map { calendar in
            ReminderListInfo(title: calendar.title, identifier: calendar.calendarIdentifier)
        }

        // Sort by title in ascending order
        reminderLists.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        
        return reminderLists
    }

    static func fetchReminders(forListIdentifier listIdentifier: String) async -> [ReminderItemInfo] {
        let store = EKEventStore()

        // Request access to reminders
        let hasAccess = await withCheckedContinuation { continuation in
            if #available(iOS 17.0, macOS 14.0, *) {
                store.requestFullAccessToReminders { granted, error in
                    if let error = error {
                        print("Error requesting reminder access for list items: \(error.localizedDescription)")
                        continuation.resume(returning: false)
                        return
                    }
                    continuation.resume(returning: granted)
                }
            } else {
                store.requestAccess(to: .reminder) { granted, error in
                    if let error = error {
                        print("Error requesting reminder access for list items (legacy): \(error.localizedDescription)")
                        continuation.resume(returning: false)
                        return
                    }
                    continuation.resume(returning: granted)
                }
            }
        }

        guard hasAccess else {
            print("Reminder access not granted for fetching items from list \(listIdentifier).")
            return []
        }

        // Fetch the specific EKCalendar
        guard let calendar = store.calendar(withIdentifier: listIdentifier) else {
            print("Calendar with identifier \(listIdentifier) not found.")
            return []
        }

        // Create a predicate to fetch all reminders for the specified calendar
        let predicate = store.predicateForReminders(in: [calendar])

        // Fetch EKReminder objects
        let fetchedReminders: [EKReminder] = await withCheckedContinuation { continuation in
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }

        var reminderItems: [ReminderItemInfo] = []
        for reminder in fetchedReminders {
            guard let title = reminder.title, !title.isEmpty else {
                // Optionally log or handle reminders without titles, though EKReminder.title is non-optional.
                // However, it could be an empty string. For this example, we skip empty titles.
                continue
            }

            var dueDate: Date? = nil
            if let dueDateComponents = reminder.dueDateComponents {
                dueDate = Calendar.current.date(from: dueDateComponents)
            }

            let itemInfo = ReminderItemInfo(
                title: title,
                dueDate: dueDate,
                notes: reminder.notes,
                primaryURL: reminder.url?.absoluteString,
                isCompleted: reminder.isCompleted
            )
            reminderItems.append(itemInfo)
        }

        // Sort the array:
        // 1. Incomplete reminders first, then completed.
        // 2. Within each group (incomplete/completed), sort by due date (earliest first).
        //    Reminders without a due date can be placed after those with due dates.
        reminderItems.sort { (item1, item2) -> Bool in
            if item1.isCompleted != item2.isCompleted {
                return !item1.isCompleted // Incomplete (false) comes before completed (true)
            }

            // Both are either complete or incomplete, sort by due date
            // Handle nil due dates: items with due dates come before items without.
            switch (item1.dueDate, item2.dueDate) {
            case (let date1?, let date2?):
                return date1 < date2 // Both have due dates, sort normally
            case (nil, _?):
                return false // item1 has no due date, item2 does; item2 comes first
            case (_?, nil):
                return true  // item1 has a due date, item2 doesn't; item1 comes first
            case (nil, nil):
                // If both are completed or both incomplete, and neither has a due date, sort by title.
                return item1.title.localizedCaseInsensitiveCompare(item2.title) == .orderedAscending
            }
        }
        
        return reminderItems
    }

    // MARK: - Adding Reminders

    static func addReminder(title: String, dueDate: Date?, notes: String?, listIdentifier: String?) async throws {
        let store = EKEventStore()

        // 1. Request Access (using the new helper)
        try await requestReminderAccess(for: store)

        // 2. Validate Title
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReminderOperationError.invalidInput(reason: "Title cannot be empty.")
        }

        // 3. Create EKReminder instance
        let reminder = EKReminder(eventStore: store)
        reminder.title = title

        // 4. Set DueDateComponents
        if let dueDate = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: dueDate)
        }

        // 5. Set Notes
        if let notes = notes, !notes.isEmpty {
            reminder.notes = notes
        }

        // 6. Assign to Calendar/List
        var targetCalendar: EKCalendar? = nil
        if let listIdentifier = listIdentifier, !listIdentifier.isEmpty {
            targetCalendar = store.calendar(withIdentifier: listIdentifier)
            if targetCalendar == nil {
                throw ReminderOperationError.listNotFound(identifier: listIdentifier)
            }
        } else {
            targetCalendar = store.defaultCalendarForNewReminders()
            if targetCalendar == nil {
                // This can happen if no default list is set, or if multiple sources (e.g., iCloud, Exchange)
                // exist and none is explicitly marked as default for Reminders.
                // Or if the user has zero reminder lists.
                print("Default calendar for new reminders not found. Attempting to use any available list.")
                // As a fallback, try to pick the first available modifiable list.
                // This might not be what the user expects, so throwing an error is often safer.
                // For this implementation, let's stick to the requirement of throwing if default is not found.
                throw ReminderOperationError.cannotFindDefaultList
            }
        }
        reminder.calendar = targetCalendar! // Force unwrap is safe due to checks above

        // 7. Save Reminder
        do {
            try await store.save(reminder, commit: true)
            print("Reminder saved successfully: \(reminder.title ?? "Untitled")")
        } catch {
            print("Failed to save reminder: \(error.localizedDescription)")
            throw ReminderOperationError.saveFailed(error)
        }
    }
}
