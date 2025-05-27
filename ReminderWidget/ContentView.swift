//
//  ContentView.swift
//  ReminderWidget
//
//  Created by Aditya Sharma on 27.05.25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var reminders: [ReminderItem]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(reminders) { reminder in
                    NavigationLink {
                        VStack(alignment: .leading) {
                            Text(reminder.title)
                                .font(.title2)
                            if let due = reminder.dueDate {
                                Text("Due: \(due.formatted(date: .numeric, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } label: {
                        Text(reminder.title)
                    }
                }
                .onDelete(perform: deleteItems)
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newReminder = ReminderItem(
                timestamp: Date(),
                title: "New Reminder",
                dueDate: Calendar.current.date(byAdding: .hour, value: 1, to: Date()),
                listName: "General",
                tags: ["#inbox"]
            )
            modelContext.insert(newReminder)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(reminders[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ReminderItem.self, inMemory: true)
}
