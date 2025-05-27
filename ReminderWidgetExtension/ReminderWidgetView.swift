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
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Next Reminder")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let list = entry.selectedList {
                    Text("List: \(list)")
                }
                if entry.showListSummary && !listSummaries.isEmpty {
                    Text("Lists: \(listSummaries.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(.fill, for: .widget)
    }
}
