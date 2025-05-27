//
//  TimelineProvider.swift
//  ReminderWidget
//
//  Created by Aditya Sharma on 27.05.25.
//

import WidgetKit
import Foundation
import AppIntents


/// TimelineProvider responsible for supplying entries to the widget.
struct ReminderTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = ReminderEntry
    typealias Configuration = ReminderSelectionIntent

    func placeholder(in context: Context) -> ReminderEntry {
        ReminderEntry.placeholder
    }

    func snapshot(for configuration: ReminderSelectionIntent, in context: Context) async -> ReminderEntry {
        ReminderEntry.placeholder
    }

    func timeline(for configuration: ReminderSelectionIntent, in context: Context) async -> Timeline<ReminderEntry> {
        let currentDate = Date()
        let selectedList = configuration.reminderList?.value

        let (title, dueDate) = await ReminderFetcher.fetchNextReminderAsync(fromList: selectedList)
        let reminderTitle = title ?? "No upcoming reminders"

        let entry = ReminderEntry(
            date: currentDate,
            title: reminderTitle,
            dueTime: dueDate,
            selectedList: configuration.reminderList?.title ?? "Default",
            tags: configuration.tags ?? [],
            showURL: configuration.showURL ?? true,
            showListSummary: configuration.showListSummary ?? true
        )

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

