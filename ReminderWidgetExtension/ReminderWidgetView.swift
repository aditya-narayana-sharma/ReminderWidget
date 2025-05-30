//
//  ReminderWidgetView.swift
//  ReminderWidget
//
//  Created by Aditya Sharma on 27.05.25.
//


import SwiftUI
import WidgetKit

/// SwiftUI view used by the widget to render the ReminderEntry.
struct ReminderWidgetView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: ReminderEntry

    // Helper function to format due dates
    private func formatDueDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short // e.g., "5:00 PM"
            return formatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "Tomorrow, \(formatter.string(from: date))"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
             // If in the current week, show weekday and time
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, h:mm a" // e.g., "Monday, 5:00 PM"
            return formatter.string(from: date)
        }
        else {
            // For dates further out, show relative or a short date format
            let formatter = DateFormatter()
            formatter.dateStyle = .medium // e.g., "Nov 23, 2023"
            formatter.timeStyle = .short // e.g., "5:00 PM"
            // Or use RelativeDateTimeFormatter for "in 2 days", "next week" etc. for closer dates
            // For simplicity, using a fixed format for dates beyond tomorrow for now.
            return formatter.string(from: date)
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) { // Outer VStack
            // Main content area, still tappable to open the Reminders app (or a specific view)
            Link(destination: URL(string: "x-apple-reminderkit://view?type=\(entry.currentViewType.hashValue)")!) {
                VStack(alignment: .leading, spacing: 8) { // Main content VStack
                    switch entry.currentViewType {
                    case .upcomingTimeline:
                        Text("Upcoming Reminders")
                            .font(.headline)
                            .padding(.bottom, 4)

                        if entry.upcomingReminders.isEmpty {
                            Text("No upcoming reminders in the next 24 hours.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer() // Use spacer to push content to top if list is empty
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(entry.upcomingReminders) { reminderInfo in
                                        VStack(alignment: .leading) {
                                            Text(reminderInfo.title)
                                                .font(.subheadline)
                                                .foregroundStyle(.primary)
                                            HStack {
                                                Text(formatDueDate(reminderInfo.dueDate))
                                                    .font(.caption)
                                                    .foregroundStyle(.orange) // Use a distinct color for due date
                                                Text("(\(reminderInfo.listName))")
                                                    .font(.caption2) // Slightly smaller for list name
                                                    .foregroundStyle(.secondary)
                                            }
                                            if let notes = reminderInfo.notes, !notes.isEmpty, entry.showListSummary { // Assuming showListSummary can toggle notes visibility for now
                                                Text(notes)
                                                    .font(.caption2)
                                                    .foregroundStyle(.gray)
                                                    .lineLimit(1) // Show only one line of notes
                                            }
                                        }
                                        .padding(.bottom, 5) // Add a little space between items
                                    }
                                }
                            }
                        }
                    case .simple: // Placeholder for the original simple view
                        Text(entry.title)
                            .font(.headline)
                        if let dueTime = entry.dueTime {
                            Text("Due: \(formatDueDate(dueTime))")
                                .font(.subheadline)
                        }
                        Text("List: \(entry.selectedList ?? "None")")
                            .font(.caption)
                        if entry.showListSummary, let firstUpcoming = entry.upcomingReminders.first {
                             Text("Notes: \(firstUpcoming.notes ?? "")").lineLimit(1).font(.caption2)
                        }
                        Spacer()
                    
                    case .allListsOverview:
                        Text("All Reminder Lists")
                            .font(.headline)
                            .padding(.bottom, 4)

                        if entry.allReminderLists.isEmpty {
                            Text("No reminder lists found.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 15) { // Spacing between list sections
                                    ForEach(entry.allReminderLists) { listInfo in
                                        VStack(alignment: .leading, spacing: 5) { // Spacing within a list section
                                            Text(listInfo.title)
                                                .font(.title3).bold() // Make list title more prominent
                                                .padding(.bottom, 2)
                                            
                                            if listInfo.sampleReminders.isEmpty {
                                                Text("No upcoming items in this list.")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                    .padding(.leading) // Indent a bit
                                            } else {
                                                ForEach(listInfo.sampleReminders) { reminderItem in
                                                    HStack {
                                                        VStack(alignment: .leading) {
                                                            Text(reminderItem.title)
                                                                .font(.body)
                                                            
                                                            HStack {
                                                                if let dueDate = reminderItem.dueDate, !reminderItem.isCompleted {
                                                                    Text(formatDueDate(dueDate))
                                                                        .font(.caption)
                                                                        .foregroundStyle(.orange)
                                                                } else if reminderItem.isCompleted {
                                                                    Text("Completed")
                                                                        .font(.caption)
                                                                        .foregroundStyle(.green)
                                                                }
                                                                
                                                                if let url = reminderItem.primaryURL, !url.isEmpty, entry.showURL {
                                                                    Image(systemName: "link")
                                                                        .font(.caption)
                                                                        .foregroundColor(.blue)
                                                                    Text(url.count > 30 ? "\(url.prefix(30))..." : url) // Display shortened URL
                                                                        .font(.caption2) // Smaller font for URL
                                                                        .foregroundColor(.blue)
                                                                        .lineLimit(1)
                                                                }
                                                            }
                                                        }
                                                        Spacer() // Pushes content to left, check if needed
                                                        if reminderItem.isCompleted {
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .foregroundColor(.green)
                                                        } else if reminderItem.dueDate != nil {
                                                            Image(systemName: "circle") // Placeholder for incomplete
                                                                .foregroundColor(.gray)
                                                        }
                                                    }
                                                    .padding(.leading) // Indent reminder items under list title
                                                    .padding(.vertical, 2) // Small vertical padding for each item
                                                }
                                            }
                                        }
                                        Divider().padding(.top, 5) // Divider after each list section
                                    }
                                }
                            }
                        }

                    case .specificList:
                        Text("Specific List View (Placeholder)")
                            .font(.headline)
                        // Implementation for this view will come in a later step.
                        // if let list = entry.detailedReminderList { Text("Content of \(list.title)")}
                        Spacer()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure main content area takes available space
            }
            .widgetURL(URL(string: "x-apple-reminderkit://view?type=\(entry.currentViewType.hashValue)")) // Keep this for the main content Link

            // "Add New Reminder" Button/Link, shown only for non-small widgets
            if widgetFamily != .systemSmall {
                // Divider to separate button from main content, if desired
                // Divider() 
                
                Link(destination: URL(string: "reminderwidgetapp://add-reminder")!) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("New Reminder")
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    // .background(Color.accentColor) // Use accent color for background
                    .background(Color.blue.opacity(0.9)) // Example styling
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .font(.callout) // Make text slightly smaller if needed
                }
                .padding(.bottom, 10) // Padding at the bottom of the widget
                .padding(.top, 5) // Padding between main content and button
            }
        }
        .containerBackground(.fill, for: .widget) // Apply container background to the outer VStack
    }
}
