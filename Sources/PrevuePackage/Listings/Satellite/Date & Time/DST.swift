//
//  DST.swift
//  PrevuePackage
//
//  Created by Ari on 9/26/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

typealias DSTPeriod = (start: Date, end: Date)

extension TimeZone {
    func nextDaylightSavingsTimePeriod(for date: Date) -> DSTPeriod? {
        let calendar = Calendar.current
        let isDST = isDaylightSavingTime(for: date)
        
        let year = calendar.component(.year, from: date)
        let previousYear = year - 1
        let nextYear = year + 1
        
        for year in [previousYear, year, nextYear] {
            if let startOfYear = calendar.date(for: year, timeZone: self),
               let transition = nextDaylightSavingsTimePeriodAfter(date: startOfYear) {
                if isDST {
                    if transition.start < date && transition.end > date {
                        return transition
                    }
                } else {
                    if transition.start > date {
                        return transition
                    }
                }
            }
        }
        
        return nil
    }
    func nextDaylightSavingsTimePeriodAfter(date: Date) -> DSTPeriod? {
        guard let nextChangeDate = nextDaylightSavingTimeTransition(after: date) else { return nil }
        
        var startDate: Date
        if isDaylightSavingTime(for: date) {
            guard let nextNextChangeDate = nextDaylightSavingTimeTransition(after: nextChangeDate) else { return nil }
            startDate = nextNextChangeDate
        } else {
            startDate = nextChangeDate
        }
        
        guard let endDate = nextDaylightSavingTimeTransition(after: startDate) else { return nil }
        return (startDate, endDate)
    }
}
