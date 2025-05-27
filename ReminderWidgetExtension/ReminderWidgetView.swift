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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Reminder")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let list = entry.selectedList {
                Text("List: \(list)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(entry.title)
                .font(.headline)
                .bold()

            if let due = entry.dueTime {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(due, style: .time)
                        .font(.caption)
                }
            }
            
            if !entry.tags.isEmpty {
                Text("Tags: \(entry.tags.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .widgetURL(entry.showURL ? URL(string: "x-apple-reminder://") : nil)
        .background(Color(.black)) // Or .black for dark
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct ReminderWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderWidgetView(entry: .placeholder)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
