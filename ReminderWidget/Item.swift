//
//  ReminderItem.swift
//  ReminderWidget
//
//  Created by Aditya Sharma on 27.05.25.
//
//  SwiftData model representing a locally stored reminder.
//

import Foundation
import SwiftData

@Model
final class ReminderItem {
    var timestamp: Date
    var title: String
    var dueDate: Date?
    var listName: String?
    var tags: [String]
    
    init(timestamp: Date, title: String, dueDate: Date? = nil, listName: String? = nil, tags: [String] = []) {
        self.timestamp = timestamp
        self.title = title
        self.dueDate = dueDate
        self.listName = listName
        self.tags = tags
    }
}
