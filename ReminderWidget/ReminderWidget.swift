//
//  ReminderWidget.swift
//  ReminderWidgetExtension
//
//  Created by Aditya Sharma on 27.05.25.
//

import WidgetKit
import SwiftUI
import AppIntents

struct ReminderWidget: Widget {
    let kind: String = "ReminderWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ReminderSelectionIntent.self, provider: ReminderTimelineProvider()) { entry in
            ReminderWidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming Reminder")
        .description("Shows reminders from a selected list.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
