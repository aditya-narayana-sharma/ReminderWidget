//
//  ReminderFetcher.swift
//  ReminderWidgetExtensionExtension
//
//  Created by Aditya Sharma on 27.05.25.
//


import Foundation
import EventKit

/// A simple helper to fetch reminders using EventKit
struct ReminderFetcher {
    static func fetchNextReminder(fromList listName: String?, completion: @escaping (String?, Date?) -> Void) {
        let store = EKEventStore()

        // Widget cannot prompt for permissions. You must run the main app first.
        store.requestFullAccessToEvents(completion: { granted, error in
            guard granted, error == nil else {
                print("Reminder access not granted or failed: \(String(describing: error))")
                completion(nil, nil)
                return
            }
            
            let allCalendars = store.calendars(for: .reminder)
            let selectedCalendars: [EKCalendar]? = {
                guard let name = listName, !name.isEmpty else { return nil }
                return allCalendars.filter { $0.title == name }
            }()
            
            let predicate = store.predicateForIncompleteReminders(
                withDueDateStarting: Date(),
                ending: nil,
                calendars: selectedCalendars
            )
            store.fetchReminders(matching: predicate) { reminders in
                let now = Date()
                let threeHoursFromNow = Calendar.current.date(byAdding: .hour, value: 3, to: now)!

                let upcomingReminders: [(String, Date)] = reminders?
                    .compactMap { reminder in
                        guard let title = reminder.title,
                              let dueComponents = reminder.dueDateComponents,
                              let dueDate = Calendar.current.date(from: dueComponents),
                              dueDate >= now && dueDate <= threeHoursFromNow else {
                            return nil
                        }
                        return (title, dueDate)
                    }
                    .sorted { $0.1 < $1.1 } ?? []

                if let next = upcomingReminders.first {
                    completion(next.0, next.1)
                    return
                }

                // fallback: get first reminder from the default list
                let fallback: (String, Date)? = reminders?
                    .compactMap { reminder in
                        guard let title = reminder.title,
                              let dueComponents = reminder.dueDateComponents,
                              let dueDate = Calendar.current.date(from: dueComponents) else {
                            return nil
                        }
                        return (title, dueDate)
                    }
                    .sorted { $0.1 < $1.1 }
                    .first

                completion(fallback?.0, fallback?.1)
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
}
