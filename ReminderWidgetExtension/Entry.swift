//
//  Entry.swift
//  ReminderWidget
//
//  Created by Aditya Sharma on 27.05.25.
//

import WidgetKit
import Foundation

// Assuming ReminderFetcher structs are accessible from this target.
// If not, equivalent Displayable... structs would need to be defined here.
// For example:
// struct DisplayableReminder { let title: String, let dueDate: Date, let listName: String }
// struct DisplayableReminderList { let title: String, let identifier: String, let reminders: [DisplayableReminderItem] }
// struct DisplayableReminderItem { let title: String, let dueTime: Date?, let notes: String?, let url: String?, let isCompleted: Bool }


enum WidgetViewType {
    case upcomingTimeline // Shows a timeline of upcoming reminders
    case specificList     // Shows items from a single, specific list
    case allListsOverview // Shows an overview of all reminder lists
    case simple           // The existing simple view (if retained)
    // Potentially .noPermission, .emptyState etc. could be added later
}

/// The timeline entry model used by the widget.
struct ReminderEntry: TimelineEntry {
    // Required by TimelineEntry
    let date: Date

    // View configuration
    var currentViewType: WidgetViewType = .simple // Default to simple or upcomingTimeline

    // Data for 'simple' or a single next reminder view (existing fields)
    // These might be deprecated or refactored if .simple view is removed or changed.
    var title: String = "No Upcoming Reminders"
    var dueTime: Date? = nil
    var selectedList: String? = nil // Could be list name for the 'simple' reminder
    var tags: [String] = []
    var showURL: Bool = false
    var showListSummary: Bool = false // This might relate to how upcoming reminders are displayed

    // Data for '.upcomingTimeline' view
    var upcomingReminders: [ReminderFetcher.UpcomingReminderInfo] = []

    // Data for '.allListsOverview' view
    var allReminderLists: [ReminderFetcher.ReminderListInfo] = []

    // Data for '.specificList' view
    var detailedReminderList: ReminderFetcher.ReminderListInfo? = nil // Info of the list being viewed
    var itemsForDetailedList: [ReminderFetcher.ReminderItemInfo] = [] // Items for that list
    
    // Configuration or context for the entry, could be expanded
    var configuration: ReminderWidgetConfigurationIntent? // To store widget settings if needed
}

// Example placeholder for preview purposes.
extension ReminderEntry {
    static var placeholder: ReminderEntry {
        let now = Date()
        let oneHourFromNow = Calendar.current.date(byAdding: .hour, value: 1, to: now)!
        let twoHoursFromNow = Calendar.current.date(byAdding: .hour, value: 2, to: now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!

        // Dummy items for the detailed list view
        let placeholderItems: [ReminderFetcher.ReminderItemInfo] = [
            .init(title: "Task 1 in Details", dueDate: oneHourFromNow, notes: "Detailed notes for task 1", primaryURL: "http://example.com/task1", isCompleted: false),
            .init(title: "Task 2 in Details (No Due Date)", dueDate: nil, notes: "No specific due date here.", primaryURL: nil, isCompleted: false),
            .init(title: "Completed Task in Details", dueDate: now, notes: "This one is done.", primaryURL: nil, isCompleted: true)
        ]

        // Dummy list for detailed view
        let detailedListPlaceholder = ReminderFetcher.ReminderListInfo(title: "Work Projects", identifier: "work-projects-list-id")
        
        // Dummy upcoming reminders
        let upcomingPlaceholders: [ReminderFetcher.UpcomingReminderInfo] = [
            .init(title: "Project Deadline", dueDate: tomorrow, listName: "Work Projects", notes: "Finalize report", primaryURL: "http://example.com/report"),
            .init(title: "Team Meeting", dueDate: oneHourFromNow, listName: "Work Projects", notes: "Discuss Q3 goals", primaryURL: nil),
            .init(title: "Grocery Shopping", dueDate: twoHoursFromNow, listName: "Personal Errands", notes: "Milk, Eggs, Bread", primaryURL: nil)
        ]

        // Dummy list overview
        let allListsPlaceholders: [ReminderFetcher.ReminderListInfo] = [
            detailedListPlaceholder, // Re-use the one from above
            .init(title: "Personal Errands", identifier: "personal-errands-list-id"),
            .init(title: "Groceries", identifier: "groceries-list-id")
        ]


        return ReminderEntry(
            date: now,
            currentViewType: .upcomingTimeline, // Default placeholder view
            title: "Placeholder Reminder", // For .simple view
            dueTime: oneHourFromNow,       // For .simple view
            selectedList: "Work Projects", // For .simple view context
            tags: ["#placeholder"],        // For .simple view
            showURL: false,                // For .simple view
            showListSummary: true,         // For .simple view context
            
            upcomingReminders: upcomingPlaceholders,
            allReminderLists: allListsPlaceholders,
            detailedReminderList: detailedListPlaceholder, // Show one list in detail for placeholder
            itemsForDetailedList: placeholderItems,
            configuration: nil // No specific intent configuration for placeholder initially
        )
    }
}
