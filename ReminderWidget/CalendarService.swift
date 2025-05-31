import Foundation
import EventKit

class CalendarService: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var events: [EKEvent] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: .event)
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
    }
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14.0, iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    completion(granted)
                }
            }
        }
    }
    
    func fetchEvents(startDate: Date, endDate: Date, completion: @escaping ([EKEvent]) -> Void) {
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        DispatchQueue.main.async {
            self.events = events
            completion(events)
        }
    }
    
    func addEvent(title: String, startDate: Date, endDate: Date, calendar: EKCalendar? = nil, notes: String? = nil, completion: @escaping (Bool) -> Void) {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = calendar ?? eventStore.defaultCalendarForNewEvents
        event.notes = notes
        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            fetchEvents(startDate: startDate, endDate: endDate) { _ in completion(true) }
        } catch {
            print("Error saving event: \(error)")
            completion(false)
        }
    }
    
    func updateEvent(_ event: EKEvent, newTitle: String, newStartDate: Date, newEndDate: Date, newCalendar: EKCalendar?, newNotes: String?, completion: @escaping (Bool) -> Void) {
        event.title = newTitle
        event.startDate = newStartDate
        event.endDate = newEndDate
        if let newCalendar = newCalendar {
            event.calendar = newCalendar
        }
        event.notes = newNotes
        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            fetchEvents(startDate: newStartDate, endDate: newEndDate) { _ in completion(true) }
        } catch {
            print("Error updating event: \(error)")
            completion(false)
        }
    }
    
    func deleteEvent(_ event: EKEvent, completion: @escaping (Bool) -> Void) {
        do {
            try eventStore.remove(event, span: .thisEvent, commit: true)
            // Refresh events for the current month
            let now = Date()
            let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now
            let end = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? now
            fetchEvents(startDate: start, endDate: end) { _ in completion(true) }
        } catch {
            print("Error deleting event: \(error)")
            completion(false)
        }
    }
    
    func fetchCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event)
    }
} 