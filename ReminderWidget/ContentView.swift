//
//  ContentView.swift
//  ReminderWidget
//
//  Created by Aditya Sharma on 27.05.25.
//

#if canImport(UIKit)
import UIKit
#endif

import SwiftUI
import EventKit

extension EKReminder: Identifiable {
    public var id: String { self.calendarItemIdentifier }
}

struct ContentView: View {
    @StateObject private var remindersService = RemindersService()
    @StateObject private var calendarService = CalendarService()
    @State private var showAddEventSheet = false
    @State private var showEditEventSheet = false
    @State private var selectedEvent: EKEvent?
    @State private var calendarRange: (Date, Date) = {
        let now = Date()
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? now
        return (start, end)
    }()

    var body: some View {
        TabView {
            // Reminders Tab
            RemindersTab(remindersService: remindersService)
                .tabItem {
                    Label("Reminders", systemImage: "checkmark.circle")
                }
            // Calendar Tab
            NavigationView {
                Group {
                    switch calendarService.authorizationStatus {
                    case .authorized:
                        List {  
                            ForEach(calendarService.events, id: \._eventIdentifier) { event in
                                Button(action: {
                                    selectedEvent = event
                                    showEditEventSheet = true
                                }) {
                                    CalendarEventRow(event: event)
                                }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let event = calendarService.events[index]
                                    calendarService.deleteEvent(event) { _ in }
                                }
                            }
                        }
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: { showAddEventSheet = true }) {
                                    Label("Add Event", systemImage: "plus")
                                }
                            }
                        }
                        .sheet(isPresented: $showAddEventSheet) {
                            EventEditView(calendarService: calendarService, isPresented: $showAddEventSheet, range: calendarRange)
                        }
                        .sheet(item: $selectedEvent) { event in
                            EventEditView(calendarService: calendarService, isPresented: $showEditEventSheet, eventToEdit: event, range: calendarRange)
                        }
                        .onAppear {
                            calendarService.fetchEvents(startDate: calendarRange.0, endDate: calendarRange.1) { _ in }
                        }
                    case .notDetermined:
                        VStack {
                            Text("This app needs access to your Calendar.")
                            Button("Grant Access") {
                                calendarService.requestAccess { granted in
                                    if granted {
                                        calendarService.fetchEvents(startDate: calendarRange.0, endDate: calendarRange.1) { _ in }
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    case .denied, .restricted:
                        VStack {
                            Text("Access to Calendar is denied or restricted. Please enable access in Settings.")
                                .multilineTextAlignment(.center)
                            Button("Open Settings") {
                                #if canImport(UIKit)
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                                #endif
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    @unknown default:
                        Text("Unknown authorization status.")
                    }
                }
                .navigationTitle("Calendar")
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
        }
    }
}

// MARK: - Reminders Tab (existing advanced UI)
struct RemindersTab: View {
    @ObservedObject var remindersService: RemindersService
    @State private var showAddSheet = false
    @State private var showEditSheet = false
    @State private var selectedReminder: EKReminder? = nil
    @State private var selectedList: EKCalendar? = nil
    
    var body: some View {
        NavigationView {
            Group {
                switch remindersService.authorizationStatus {
                case .authorized:
                    List {
                        ForEach(remindersService.reminders, id: \.id) { reminder in
                            Button(action: {
                                selectedReminder = reminder
                                showEditSheet = true
                            }) {
                                ReminderRow(reminder: reminder)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let reminder = remindersService.reminders[index]
                                remindersService.deleteReminder(reminder) { _ in }
                            }
                        }
                    }
                    .toolbar {
                        #if os(iOS)
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showAddSheet = true }) {
                                Label("Add Reminder", systemImage: "plus")
                            }
                        }
                        #else
                        ToolbarItem {
                            Button(action: { showAddSheet = true }) {
                                Label("Add Reminder", systemImage: "plus")
                            }
                        }
                        #endif
                    }
                    .sheet(isPresented: $showAddSheet) {
                        ReminderEditView(remindersService: remindersService, isPresented: $showAddSheet)
                    }
                    .sheet(item: $selectedReminder) { reminder in
                        ReminderEditView(remindersService: remindersService, isPresented: $showEditSheet, reminderToEdit: reminder)
                    }
                    .onAppear {
                        remindersService.fetchReminders { _ in }
                    }
                case .notDetermined:
                    VStack {
                        Text("This app needs access to your Reminders.")
                        Button("Grant Access") {
                            remindersService.requestAccess { granted in
                                if granted {
                                    remindersService.fetchReminders { _ in }
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                case .denied, .restricted:
                    VStack {
                        Text("Access to Reminders is denied or restricted. Please enable access in Settings.")
                            .multilineTextAlignment(.center)
                        Button("Open Settings") {
                            #if canImport(UIKit)
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                            #endif
                        }
                        .buttonStyle(.borderedProminent)
                    }
                @unknown default:
                    Text("Unknown authorization status.")
                }
            }
            .navigationTitle("Reminders")
        }
    }
}

// MARK: - Reminder Edit/Add Sheet

struct ReminderEditView: View {
    @ObservedObject var remindersService: RemindersService
    @Binding var isPresented: Bool
    var reminderToEdit: EKReminder?
    
    @State private var title: String = ""
    @State private var dueDate: Date? = nil
    @State private var selectedList: EKCalendar? = nil
    @State private var showDatePicker = false
    
    var isEditing: Bool { reminderToEdit != nil }
    
    var body: some View {
        NavigationView {
            Form {
                ReminderTitleSection(title: $title)
                ReminderDueDateSection(dueDate: $dueDate)
                ReminderListPickerSection(remindersService: remindersService, selectedList: $selectedList)
            }
            .navigationTitle(isEditing ? "Edit Reminder" : "Add Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Add") {
                        if isEditing, let reminder = reminderToEdit {
                            remindersService.updateReminder(reminder, newTitle: title, newDueDate: dueDate) { _ in
                                isPresented = false
                            }
                        } else {
                            remindersService.addReminder(title: title, dueDate: dueDate, list: selectedList) { _ in
                                isPresented = false
                            }
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let reminder = reminderToEdit {
                    title = reminder.title
                    dueDate = reminder.dueDateComponents?.date
                    selectedList = reminder.calendar
                }
            }
        }
    }
}

struct ReminderTitleSection: View {
    @Binding var title: String
    var body: some View {
        Section {
            TextField("Reminder Title", text: $title)
        } header: {
            Text("Title")
        }
    }
}

struct ReminderDueDateSection: View {
    @Binding var dueDate: Date?
    var body: some View {
        Section {
            Toggle("Set Due Date", isOn: Binding(
                get: { dueDate != nil },
                set: { newValue in dueDate = newValue ? (dueDate ?? Date()) : nil }
            ))
            if dueDate != nil {
                DatePicker("Due Date", selection: Binding($dueDate, Date()), displayedComponents: [.date, .hourAndMinute])
            }
        } header: {
            Text("Due Date")
        }
    }
}

struct ReminderListPickerSection: View {
    @ObservedObject var remindersService: RemindersService
    @Binding var selectedList: EKCalendar?
    var body: some View {
        Section {
            Picker("List", selection: $selectedList) {
                ForEach(remindersService.fetchReminderLists(), id: \.self) { list in
                    Text(list.title).tag(list as EKCalendar?)
                }
            }
        } header: {
            Text("List")
        }
    }
}

// MARK: - Event Edit/Add Sheet
struct EventEditView: View {
    @ObservedObject var calendarService: CalendarService
    @Binding var isPresented: Bool
    var eventToEdit: EKEvent? = nil
    var range: (Date, Date)
    
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    @State private var selectedCalendar: EKCalendar? = nil
    @State private var notes: String = ""
    
    var isEditing: Bool { eventToEdit != nil }
    
    var body: some View {
        NavigationView {
            Form {
                EventTitleSection(title: $title)
                EventStartDateSection(startDate: $startDate)
                EventEndDateSection(endDate: $endDate)
                EventCalendarSection(calendarService: calendarService, selectedCalendar: $selectedCalendar)
                EventNotesSection(notes: $notes)
            }
            .navigationTitle(isEditing ? "Edit Event" : "Add Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Add") {
                        if isEditing, let event = eventToEdit {
                            calendarService.updateEvent(event, newTitle: title, newStartDate: startDate, newEndDate: endDate, newCalendar: selectedCalendar, newNotes: notes) { _ in
                                isPresented = false
                            }
                        } else {
                            calendarService.addEvent(title: title, startDate: startDate, endDate: endDate, calendar: selectedCalendar, notes: notes) { _ in
                                isPresented = false
                            }
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || endDate <= startDate)
                }
            }
            .onAppear {
                if let event = eventToEdit {
                    title = event.title
                    startDate = event.startDate
                    endDate = event.endDate
                    selectedCalendar = event.calendar
                    notes = event.notes ?? ""
                }
            }
        }
    }
}

struct EventTitleSection: View {
    @Binding var title: String
    var body: some View {
        Section {
            TextField("Event Title", text: $title)
        } header: {
            Text("Title")
        }
    }
}

struct EventStartDateSection: View {
    @Binding var startDate: Date
    var body: some View {
        Section {
            DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
        } header: {
            Text("Start Date")
        }
    }
}

struct EventEndDateSection: View {
    @Binding var endDate: Date
    var body: some View {
        Section {
            DatePicker("End", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
        } header: {
            Text("End Date")
        }
    }
}

struct EventCalendarSection: View {
    @ObservedObject var calendarService: CalendarService
    @Binding var selectedCalendar: EKCalendar?
    var body: some View {
        Section {
            Picker("Calendar", selection: $selectedCalendar) {
                ForEach(calendarService.fetchCalendars(), id: \.self) { cal in
                    Text(cal.title).tag(cal as EKCalendar?)
                }
            }
        } header: {
            Text("Calendar")
        }
    }
}

struct EventNotesSection: View {
    @Binding var notes: String
    var body: some View {
        Section {
            TextField("Notes", text: $notes)
        } header: {
            Text("Notes")
        }
    }
}

// Helper to convert DateComponents to Date
private extension DateComponents {
    var date: Date? {
        Calendar.current.date(from: self)
    }
}

struct CalendarEventRow: View {
    let event: EKEvent
    var body: some View {
        VStack(alignment: .leading) {
            Text(event.title)
                .font(.headline)
            Text("\(event.startDate.formatted(date: .abbreviated, time: .shortened)) - \(event.endDate.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let calendar = event.calendar {
                Text("Calendar: \(calendar.title)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ReminderRow: View {
    let reminder: EKReminder
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(reminder.title)
                    .font(.headline)
                if let due = reminder.dueDateComponents?.date {
                    Text("Due: \(due.formatted(date: .numeric, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let list = reminder.calendar?.title {
                    Text("List: \(list)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}

#Preview {
    ContentView()
}
