//
//  ClockCommand.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation

enum DayOfWeek: UInt8, BinaryCodable {
    case Sunday = 0
    case Monday = 1
    case Tuesday = 2
    case Wednesday = 3
    case Thursday = 4
    case Friday = 5
    case Saturday = 6
}

struct ClockCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.clock
    let dayOfWeek: DayOfWeek
    let month: UInt8 // Zero-indexed month
    let day: UInt8 // Zero-indexed day
    let year: UInt8 // Years since 1900
    let hour: UInt8
    let minute: UInt8
    let second: UInt8
    let daylightSavingsTime: Bool
}

extension ClockCommand {
    init?(with date: Date, timeZone: TimeZone = .current) {
        let calendar =  Calendar.current
        let daylightSavingsTime = timeZone.isDaylightSavingTime(for: date)
        let components = calendar.dateComponents(in: timeZone, from: date)
        
        guard let weekday = components.weekday,
            let month = components.month,
            let day = components.day,
            let year = components.year,
            let hour = components.hour,
            let minute = components.minute,
            let second = components.second,
            let dayOfWeek = DayOfWeek(rawValue: UInt8(weekday - 1)) else { return nil }
        
        self.init(dayOfWeek: dayOfWeek, month: UInt8(month - 1), day: UInt8(day - 1), year: UInt8(year - 1900), hour: UInt8(hour), minute: UInt8(minute), second: UInt8(second), daylightSavingsTime: daylightSavingsTime)
    }
    init?(withJulianDay day: JulianDay, date: Date, timeZone: TimeZone = .current) {
        guard let julianDate = Calendar.current.date(bySettingJulianDay: day, of: date, timeZone: timeZone) else { return nil }
        self.init(with: julianDate, timeZone: timeZone)
    }
}

// MARK: Encoding

extension ClockCommand {
    var footerBytes: Bytes {
        // Encode terminator byte
        return [0x00]
    }
}

// MARK: Current clock command

struct CurrentClockCommand: MetaCommand {
    let dayOfYear: Int?
    
    var commands: [DataCommand] {
        if let dayOfYear = dayOfYear {
            let command = ClockCommand(withJulianDay: JulianDay(dayOfYear: dayOfYear), date: Date(), timeZone: .tulsa)!
            return [command]
        } else {
            let command = ClockCommand(with: Date(), timeZone: .tulsa)!
            return [command]
        }
    }
}
