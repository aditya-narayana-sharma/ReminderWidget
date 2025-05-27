//
//  Entry.swift
//  ReminderWidget
//
//  Created by Aditya Sharma on 27.05.25.
//

import WidgetKit
import Foundation

/// The timeline entry model used by the widget.
struct ReminderEntry: TimelineEntry {
    /// The date when this entry is valid (required by WidgetKit).
    let date: Date

    /// Optional title of the next reminder to display.
    let title: String

    /// Optional due time of the reminder.
    let dueTime: Date?

    /// Optional selected reminder list name.
    let selectedList: String?

    /// Optional list of selected tags.
    let tags: [String]

    /// Determines whether to show the URL preview.
    let showURL: Bool

    /// Controls whether list summaries should be shown in the widget.
    let showListSummary: Bool
}

// Example placeholder for preview purposes.
extension ReminderEntry {
    static var placeholder: ReminderEntry {
        ReminderEntry(
            date: Date(),
            title: "Upcoming Reminder",
            dueTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date()),
            selectedList: "Default",
            tags: ["#work", "#urgent"],
            showURL: true,
            showListSummary: true
        )
    }
}
