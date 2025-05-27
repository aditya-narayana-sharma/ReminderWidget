//
//  ReminderWidgetApp.swift
//  ReminderWidget
//
//  Created by Aditya Sharma on 27.05.25.
//

import SwiftUI
import SwiftData
import EventKit

@main
struct ReminderWidgetApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ReminderItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    requestReminderPermission()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

func requestReminderPermission() {
    let store = EKEventStore()

    if #available(macOS 14.0, iOS 17.0, *) {
        store.requestFullAccessToReminders { granted, error in
            if granted {
                print("✅ Full access to Reminders granted.")
            } else {
                print("❌ Access denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    } else {
        store.requestAccess(to: .reminder) { granted, error in
            if granted {
                print("✅ Reminder access granted (legacy).")
            } else {
                print("❌ Access denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
