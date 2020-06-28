//
//  ChannelTypes.swift
//  PrevueApp
//
//  Created by Ari on 4/6/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation

typealias SourceIdentifier = String // Limited to 6 characters
typealias Timeslot = UInt8 // 1 to 48

struct Channel: Codable {
    let sourceIdentifier: SourceIdentifier
    let channelNumber: String
    let callLetters: String // Limited to 5 characters on EPG Jr., 6 on Amiga
    let flags: ChannelAttributes
}

struct Program: Codable {
    let timeslot: Timeslot
    let sourceIdentifier: SourceIdentifier // Channel source
    let programName: String
    let flags: ProgramAttributes
}

struct JulianDay: Codable, UVSGDocumentable {
    let dayOfYear: UInt8
}

struct ChannelAttributes: OptionSetCodableAsOptionNames {
    let rawValue: UInt8
    
    static let none = ChannelAttributes(rawValue: 0x01) // No attribute (prevents sending NULL)
    static let hiliteSrc = ChannelAttributes(rawValue: 0x02) // Red highlight in grid
    static let sumbySrc = ChannelAttributes(rawValue: 0x04) // Summary-by-source (SBS) enabled
    static let videoTagDisable = ChannelAttributes(rawValue: 0x08) // Promotional tagging disabled
    static let cafPPVSrc = ChannelAttributes(rawValue: 0x10) // PPV source
    static let ditto = ChannelAttributes(rawValue: 0x20) // Ditto enabled
    static let althiliteSrc = ChannelAttributes(rawValue: 0x40) // Lt. blue highlight in grid
    static let stereo = ChannelAttributes(rawValue: 0x80) // Stereo source
    
    enum Options: CaseIterable {
        case none, hiliteSrc, sumbySrc, videoTagDisable, cafPPVSrc, ditto, althiliteSrc, stereo
    }
}

struct ProgramAttributes: OptionSetCodableAsOptionNames {
    let rawValue: UInt8
    
    static let none = ProgramAttributes(rawValue: 0x01) // No attribute, always set
    static let movie = ProgramAttributes(rawValue: 0x02) // Movie
    static let altHiliteProg = ProgramAttributes(rawValue: 0x04) // Alternate highlight
    static let tagProg = ProgramAttributes(rawValue: 0x08) // Tag program
    static let sportsProg = ProgramAttributes(rawValue: 0x10) // Sports program
    static let dViewUsed = ProgramAttributes(rawValue: 0x20) // Not used?
    static let repeatProg = ProgramAttributes(rawValue: 0x40) // Repeat program ("this attribute is stored, but not used for anything")
    static let prevDaysData = ProgramAttributes(rawValue: 0x80) // Previous day's data ("this attribute is only used internally by the CG software and is therefore an implementation detail")
    
    enum Options: CaseIterable {
        case none, movie, altHiliteProg, tagProg, sportsProg, dViewUsed, repeatProg, prevDaysData
    }
}

extension JulianDay {
    init(with date: Date) {
        let calendar = NSCalendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date)!
        let julianDay = UInt8(dayOfYear % 256)
        
        self.init(dayOfYear: julianDay)
    }
    
    static var now: JulianDay {
        get {
            return JulianDay(with: Date())
        }
    }
}

extension ChannelAttributes {
    init(from decoder: Decoder) throws {
        try self.init(asNamesFrom: decoder)
    }
    func encode(to encoder: Encoder) throws {
        try encode(asNamesTo: encoder)
    }
}

extension ProgramAttributes {
    init(from decoder: Decoder) throws {
        try self.init(asNamesFrom: decoder)
    }
    func encode(to encoder: Encoder) throws {
        try encode(asNamesTo: encoder)
    }
}
