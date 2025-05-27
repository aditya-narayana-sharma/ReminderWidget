//
//  ReminderWidgetExtension.swift
//  ReminderWidgetExtension
//
//  Created by Aditya Sharma on 27.05.25.
//

import WidgetKit
import SwiftUI

struct ReminderWidgetExtension: Widget {
    let kind: String = "ReminderWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ReminderSelectionIntent.self, provider: ReminderTimelineProvider()) { entry in
            ReminderWidgetView(entry: entry)
        }
        .configurationDisplayName("Reminder Widget")
        .description("Shows your next reminder.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}
