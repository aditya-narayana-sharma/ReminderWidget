//
//  ReminderSelectionIntent.swift
//  ReminderWidgetExtension
//
//  Created by Aditya Sharma on 27.05.25.
//

import AppIntents
import EventKit

struct ReminderSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configure Reminder Widget"
    static var description = IntentDescription("Select your Reminder list and filtering options.")

    @Parameter(
        title: "Reminder List"
    )
    var reminderList: ReminderListIntentOption?
    @Parameter(
        title: "Tags",
        optionsProvider: ReminderTagsOptionsProvider()
    )
    var tags: [String]?

    @Parameter(title: "Show URL Preview")
    var showURL: Bool?

    @Parameter(title: "Show List Summary")
    var showListSummary: Bool?

    init() {
        self.showURL = true
        self.showListSummary = true
    }
}
