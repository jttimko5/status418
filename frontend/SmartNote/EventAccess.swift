//
//  EventAccess.swift
//  SmartNote
//
//  Created by Tim Stauder on 4/4/23.
//
import Foundation
import EventKit


// works only with properly formatted iso dates
// examples: ["2022-02-14T00:00:00", "2022-09-26T00:00:00"]

func getDate(date_str: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    dateFormatter.timeZone = TimeZone.current
    dateFormatter.locale = Locale.current
    return dateFormatter.date(from: date_str) // replace Date String
}

func pullEvents(dates: Array<String>?) -> [String]? {
    // start code: https://developer.apple.com/documentation/eventkit/retrieving_events_and_reminders
    // Create list of items for return
    var list: [String] = []
    // Create event store object
    let store = EKEventStore()
    // Request access to calendar
    store.requestAccess(to: .event) { granted, error in
        if error != nil {
             print(error!)
        }
    }
    let calendar = Calendar.current
    for d in dates ?? [] {
        let date = getDate(date_str: d) ?? nil
        // Create a yesterday date
        var back_win = DateComponents()
        back_win.day = -1
        let start = calendar.date(byAdding: back_win, to: date!, wrappingComponents: false)
        
        // Create a date 1 month in the future
        var for_win = DateComponents()
        for_win.day = 1
        let end = calendar.date(byAdding: for_win, to: date!, wrappingComponents: false)
        
        // Create a predicate for query
        let predicate = store.predicateForEvents(withStart: start!, end: end!, calendars: nil)
        
        // Run actual query to get matching events
        let events = store.events(matching: predicate)
        
        // Loop thru event
        for event in events {
            let t: String = event.title
            list.append(t)
//            var e = EKEvent()
//            e.title = event.title
//            list.append(e)
        }
    }
    return list
}

