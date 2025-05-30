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
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)! // Standard update interval

        // Extract configuration values
        let selectedListTitle = configuration.reminderList?.title // This is String?
        let selectedTags = configuration.tags?.map { $0.name ?? "" } ?? [] // Assuming tags are AppEntities with a 'name'
        let showURLPreview = configuration.showURLPreview // This was named showURLPreview in the intent definition.
        let showListSummaryConfig = configuration.showListSummary

        // 1. Fetch upcoming reminders
        // Using 24 hours for a broader view.
        // Handle potential errors by defaulting to an empty array.
        let upcomingReminders: [ReminderFetcher.UpcomingReminderInfo] = (try? await ReminderFetcher.fetchAllUpcomingReminders(
            forNextHours: 24,
            fromListNamed: selectedListTitle
        )) ?? []

        // 2. Fetch all reminder lists and their sample reminders
        var enrichedReminderLists: [ReminderFetcher.ReminderListInfo] = []
        let rawReminderLists: [ReminderFetcher.ReminderListInfo] = (try? await ReminderFetcher.fetchAllReminderLists()) ?? []

        for rawListInfo in rawReminderLists {
            var listWithSamples = rawListInfo
            // Fetch top 3 incomplete reminders for this list
            // Note: fetchReminders currently gets all. We'll filter and take top 3 incomplete.
            let itemsForThisList: [ReminderFetcher.ReminderItemInfo] = (try? await ReminderFetcher.fetchReminders(
                forListIdentifier: rawListInfo.id
            )) ?? []
            
            listWithSamples.sampleReminders = itemsForThisList
                .filter { !$0.isCompleted } // Only incomplete ones
                .sorted(by: { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }) // Sort by due date, soonest first
                .prefix(3) // Take top 3
                .map { $0 } // Convert ArraySlice back to Array if needed, though often not required
            
            enrichedReminderLists.append(listWithSamples)
        }
        
        // Determine title and dueTime for the .simple view or as a fallback
        // This can be based on the first upcoming reminder or kept generic
        let simpleViewTitle: String
        let simpleViewDueTime: Date?
        if let firstUpcoming = upcomingReminders.first(where: { $0.listName == selectedListTitle || selectedListTitle == nil }) {
            simpleViewTitle = firstUpcoming.title
            simpleViewDueTime = firstUpcoming.dueDate
        } else if let firstAnyUpcoming = upcomingReminders.first {
            simpleViewTitle = firstAnyUpcoming.title
            simpleViewDueTime = firstAnyUpcoming.dueDate
        }
        else {
            simpleViewTitle = "No upcoming reminders"
            simpleViewDueTime = nil
        }

        // 3. Create the ReminderEntry
        // For now, detailedReminderList and itemsForDetailedList are not populated in the main timeline update.
        // currentViewType defaults to .upcomingTimeline. This might be changed by widget interaction later.
        let entry = ReminderEntry(
            date: currentDate,
            currentViewType: .upcomingTimeline, // Default view for this timeline
            title: simpleViewTitle, // For the .simple view or as a general title
            dueTime: simpleViewDueTime,   // For the .simple view
            selectedList: selectedListTitle, // Keep passing this through
            tags: selectedTags,               // Keep passing this through
            showURL: showURLPreview,          // Pass from config
            showListSummary: showListSummaryConfig, // Pass from config
            
            upcomingReminders: upcomingReminders,
            allReminderLists: enrichedReminderLists, // Use the enriched list
            detailedReminderList: nil, // Not loading detailed list in generic timeline
            itemsForDetailedList: [],  // Not loading items in generic timeline
            configuration: configuration // Pass the whole configuration
        )

        return Timeline(entries: [entry], policy: .after(nextUpdateDate))
    }
}

