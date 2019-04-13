//
//  ChannelTypes.swift
//  PrevueApp
//
//  Created by Ari on 4/6/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation

struct JulianDay {
    let dayOfYear: UInt8
}

// These flags are possibly incomplete or incorrect; should be confirmed in Amiga disassembly.
struct ChannelFlags: OptionSet {
    let rawValue: UInt8
    
    static let none = ChannelFlags(rawValue: 0x01)
    static let hiliteSrc = ChannelFlags(rawValue: 0x02)
    static let sumbySrc = ChannelFlags(rawValue: 0x04)
    static let videoTagDisable = ChannelFlags(rawValue: 0x08)
    static let cafPPVSrc = ChannelFlags(rawValue: 0x10)
    static let ditto = ChannelFlags(rawValue: 0x20)
    static let altHiliteSrc = ChannelFlags(rawValue: 0x40)
    static let stereo = ChannelFlags(rawValue: 0x80)
}

// These flags are possibly incomplete or incorrect; should be confirmed in Amiga disassembly.
struct ProgramFlags: OptionSet {
    let rawValue: UInt8
    
    static let none = ProgramFlags(rawValue: 0x01)
    static let movie = ProgramFlags(rawValue: 0x02)
    static let altHiliteProg = ProgramFlags(rawValue: 0x04)
    static let tagProg = ProgramFlags(rawValue: 0x08)
    static let sportsProg = ProgramFlags(rawValue: 0x10)
    static let dViewUsed = ProgramFlags(rawValue: 0x20)
    static let repeatProg = ProgramFlags(rawValue: 0x40)
    static let prevDaysData = ProgramFlags(rawValue: 0x80)
}

extension JulianDay {
    init(with date: Date) {
        let calendar = NSCalendar(identifier: .gregorian)!
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date)
        let julianDay = UInt8(dayOfYear % 256)
        
        self.init(dayOfYear: julianDay)
    }
    
    static var now: JulianDay {
        get {
            return JulianDay(with: Date())
        }
    }
}
