//
//  ReminderWidgetApp.swift
//  ReminderWidget
//
//  Created by Aditya Sharma on 27.05.25.
//

import SwiftUI
import SwiftData

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
        }
        .modelContainer(sharedModelContainer)
    }
}
