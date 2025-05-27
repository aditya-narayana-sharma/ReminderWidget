//
//  ReminderSelectionIntent.swift
//  ReminderWidgetExtensionExtension
//
//  Created by Aditya Sharma on 27.05.25.
//

import Foundation
import AppIntents

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
struct ReminderSelectionIntent: AppIntent, WidgetConfigurationIntent, CustomIntentMigratedAppIntent, PredictableIntent {
    static let intentClassName = "ReminderSelectionIntent"

    static var title: LocalizedStringResource = "Reminder Selection Intent"
    static var description = IntentDescription("")

    @Parameter(title: "Reminder List", optionsProvider: ReminderListOptionsProvider())
    var reminderList: String?

    struct ReminderListOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [String] {
            return ["Personal", "Work", "Groceries"]
        }
    }

    @Parameter(title: "Select Tags", optionsProvider: ReminderTagsOptionsProvider())
    var tags: [String]?

    struct ReminderTagsOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [String] {
            return ["#urgent", "#home", "#call"]
        }
    }

    @Parameter(title: "Show URL Preview")
    var showURL: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Advanced Reminders") {
            \.$reminderList
            \.$tags
            \.$showURL
        }
    }

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction(parameters: (\.$reminderList, \.$tags, \.$showURL)) { reminderList, tags, showURL in
            DisplayRepresentation(
                title: "Advanced Reminders",
                subtitle: ""
            )
        }
    }

    func perform() async throws -> some IntentResult {
        // TODO: Place your refactored intent handler code here.
        return .result()
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static func reminderListParameterDisambiguationIntro(count: Int, reminderList: String) -> Self {
        "There are \(count) options matching ‘\(reminderList)’."
    }
    static func reminderListParameterConfirmation(reminderList: String) -> Self {
        "Just to confirm, you wanted ‘\(reminderList)’?"
    }
    static func tagsParameterDisambiguationIntro(count: Int, tags: String) -> Self {
        "There are \(count) options matching ‘\(tags)’."
    }
    static func tagsParameterConfirmation(tags: String) -> Self {
        "Just to confirm, you wanted ‘\(tags)’?"
    }
    static var showURLParameterPrompt: Self {
        "Do you want to show the link?"
    }
}
