//
//  ClockCommand.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

enum DayOfWeek: UInt8 {
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
    let month: UInt8
    let day: UInt8
    let year: UInt8 // Years since 1900
    let hour: UInt8
    let minute: UInt8
    let second: UInt8
    let daylightSavingsTime: Bool
}

extension ClockCommand: UVSGEncodableDataCommand {
    var payload: Bytes {
        // To be tested
        // I think the last byte is always 0 and is unused, but should be confirmed in disassembly
        return [dayOfWeek.rawValue, month, day, year, hour, minute, second, daylightSavingsTime.asByte(), 0x00]
    }
}
