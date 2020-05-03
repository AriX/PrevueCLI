//
//  ClockCommand.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation

enum DayOfWeek: UInt8, CaseIterable {
    case Sunday = 0
    case Monday = 1
    case Tuesday = 2
    case Wednesday = 3
    case Thursday = 4
    case Friday = 5
    case Saturday = 6
}

struct ClockCommand: DataCommand {
    let commandMode = DataCommandMode.clock
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
    init?(with date: Date) {
        let calendar =  NSCalendar.current
        let daylightSavingsTime = calendar.timeZone.isDaylightSavingTime(for: date)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .weekday], from: date)
        
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
}

extension ClockCommand {
    var payload: Bytes {
        // To be tested
        // I think the last byte is always 0 and is unused, but should be confirmed in disassembly
        // Last bit goes to 1 to reset Julian day
        return [dayOfWeek.rawValue, month, day, year, hour, minute, second, daylightSavingsTime.asByte(), 0x00]
    }
}

// For readability, encode DayOfWeek as a string (e.g. "Friday") instead of an integer
extension DayOfWeek: Codable {
    init(from decoder: Decoder) throws {
        let stringValue = try decoder.singleValueContainer().decode(String.self)
        guard let matchingDay = DayOfWeek.allCases.first(where: { $0.stringValue == stringValue }) else {
            throw DecodingError.typeMismatch(DayOfWeek.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid day of week specified"))
        }
        
        self = matchingDay
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.stringValue)
    }
    var stringValue: String {
        String(describing: self)
    }
}
