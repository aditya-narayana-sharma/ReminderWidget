//
//  OpenRemindersAppIntent.swift
//  ReminderWidgetExtension
//

import AppIntents
import Foundation

struct OpenRemindersAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Reminders App"
    static var description = IntentDescription("Launches the Apple Reminders app.")

    func perform() async throws -> some IntentResult {
        return .result()
    }

    var url: URL {
        return URL(string: "x-apple-reminderkit://")!
    }
}
