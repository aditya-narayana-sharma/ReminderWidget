//
//  ReminderSelectionIntentHandler.swift
//  ReminderWidgetExtension
//
//  Created by Aditya Sharma on 27.05.25.
//

import AppIntents
import EventKit

struct ReminderListOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [ReminderListIntentOption] {
        let eventStore = EKEventStore()
        let granted = try await eventStore.requestAccess(to: .reminder)

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

struct ReminderListIntentOption: AppEntity, Identifiable {
    var id: String { value }

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Reminder List"
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: .init(stringLiteral: title))
    }

    static var defaultQuery = ReminderListQuery()

    let title: String
    let value: String
}

struct ReminderListQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ReminderListIntentOption] {
        let store = EKEventStore()
        let calendars = store.calendars(for: .reminder)
        return calendars
            .filter { identifiers.contains($0.calendarIdentifier) }
            .map { ReminderListIntentOption(title: $0.title, value: $0.calendarIdentifier) }
    }

    func suggestedEntities() async throws -> [ReminderListIntentOption] {
        let store = EKEventStore()
        let calendars = store.calendars(for: .reminder)
        return calendars.map {
            ReminderListIntentOption(title: $0.title, value: $0.calendarIdentifier)
        }
    }
}
