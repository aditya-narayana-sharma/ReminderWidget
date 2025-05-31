import Foundation
import EventKit

class RemindersService: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var reminders: [EKReminder] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
    }
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14.0, iOS 17.0, *) {
            eventStore.requestFullAccessToReminders { granted, error in
                DispatchQueue.main.async {
                    self.authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .reminder) { granted, error in
                DispatchQueue.main.async {
                    self.authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
                    completion(granted)
                }
            }
        }
    }
    
    func fetchReminders(completion: @escaping ([EKReminder]) -> Void) {
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        eventStore.fetchReminders(matching: predicate) { reminders in
            DispatchQueue.main.async {
                self.reminders = reminders ?? []
                completion(reminders ?? [])
            }
        }
    }
    
    func addReminder(title: String, dueDate: Date?, list: EKCalendar? = nil, completion: @escaping (Bool) -> Void) {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.calendar = list ?? eventStore.defaultCalendarForNewReminders()
        if let dueDate = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        }
        do {
            try eventStore.save(reminder, commit: true)
            fetchReminders { _ in completion(true) }
        } catch {
            print("Error saving reminder: \(error)")
            completion(false)
        }
    }
    
    func updateReminder(_ reminder: EKReminder, newTitle: String, newDueDate: Date?, completion: @escaping (Bool) -> Void) {
        reminder.title = newTitle
        if let newDueDate = newDueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: newDueDate)
        } else {
            reminder.dueDateComponents = nil
        }
        do {
            try eventStore.save(reminder, commit: true)
            fetchReminders { _ in completion(true) }
        } catch {
            print("Error updating reminder: \(error)")
            completion(false)
        }
    }
    
    func deleteReminder(_ reminder: EKReminder, completion: @escaping (Bool) -> Void) {
        do {
            try eventStore.remove(reminder, commit: true)
            fetchReminders { _ in completion(true) }
        } catch {
            print("Error deleting reminder: \(error)")
            completion(false)
        }
    }
    
    func fetchReminderLists() -> [EKCalendar] {
        return eventStore.calendars(for: .reminder)
    }
} 