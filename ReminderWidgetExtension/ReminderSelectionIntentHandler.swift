//
//  ReminderSelectionIntentHandler.swift
//  ReminderWidgetExtension
//
//  Created by Aditya Sharma on 27.05.25.
//

import AppIntents
import EventKit

public struct ReminderListOptionsProvider: DynamicOptionsProvider {
    public func results() async throws -> [ReminderListIntentOption] {
        let eventStore = EKEventStore()
        let granted = try await eventStore.requestFullAccessToReminders()

        guard granted else {
            return []
        }

        let lists = eventStore.calendars(for: .reminder)
        let options: [ReminderListIntentOption] = lists.map {
            ReminderListIntentOption(
                title: $0.title,
                value: $0.calendarIdentifier
            )
        }

        return options
    }
}

public struct ReminderTagsOptionsProvider: DynamicOptionsProvider {
    public func results() async throws -> [String] {
        let store = EKEventStore()
        let granted = try await store.requestFullAccessToReminders()

        guard granted else {
            return []
        }

        let allReminders = try await withCheckedThrowingContinuation { continuation in
            let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }

        let tags = allReminders
            .compactMap { $0.notes }
            .flatMap { $0.components(separatedBy: .whitespacesAndNewlines) }
            .filter { $0.starts(with: "#") }
            .map { String($0.dropFirst()) }

        return Array(Set(tags)).sorted()
    }
}

public struct ReminderListIntentOption: AppEntity, Identifiable {
    public var id: String { value }

    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Reminder List"
    
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: .init(stringLiteral: title))
    }

    public static var defaultQuery = ReminderListQuery()

    let title: String
    let value: String
}

public struct ReminderListQuery: EntityQuery {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [ReminderListIntentOption] {
        let store = EKEventStore()
        let calendars = store.calendars(for: .reminder)
        return calendars
            .filter { identifiers.contains($0.calendarIdentifier) }
            .map { ReminderListIntentOption(title: $0.title, value: $0.calendarIdentifier) }
    }

    public func suggestedEntities() async throws -> [ReminderListIntentOption] {
        let store = EKEventStore()
        let calendars = store.calendars(for: .reminder)
        return calendars.map {
            ReminderListIntentOption(title: $0.title, value: $0.calendarIdentifier)
        }
    }
}
