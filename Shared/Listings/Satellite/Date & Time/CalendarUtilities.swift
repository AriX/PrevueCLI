//
//  CalendarUtilities.swift
//  PrevuePackage
//
//  Created by Ari on 9/26/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

extension Calendar {
    func date(bySettingJulianDay day: JulianDay, of date: Date, timeZone: TimeZone) -> Date? {
        var components = dateComponents(in: timeZone, from: date)
        components.month = 1
        components.day = 1
        
        guard let startOfYear = self.date(from: components) else { return nil }
        return self.date(byAdding: .day, value: Int(day.dayOfYear), to: startOfYear)
    }
    func date(for year: Int, timeZone: TimeZone) -> Date? {
        var yearComponents = DateComponents()
        yearComponents.timeZone = timeZone
        yearComponents.year = year
        
        return self.date(from: yearComponents)
    }
    func startOfListingsDay(for date: Date) -> Date {
        return self.date(bySettingHour: 5, minute: 0, second: 0, of: date)! // Listings start at 5 AM
    }
}
