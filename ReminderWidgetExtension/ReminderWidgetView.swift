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
    let entry: ReminderEntry

    @State private var listSummaries: [String] = []

    var body: some View {
        Link(destination: URL(string: "x-apple-reminderkit://")!) {
            ZStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Reminder")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("List: \(entry.selectedList ?? "None")")
                        .accessibilityLabel("Reminder List: \(entry.selectedList ?? "None")")
                    if entry.showListSummary && !listSummaries.isEmpty {
                        Text("Lists: \(listSummaries.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            .containerBackground(.fill, for: .widget)
        }
    }
}
