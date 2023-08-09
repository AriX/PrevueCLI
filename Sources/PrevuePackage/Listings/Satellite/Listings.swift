//
//  Listings.swift
//  PrevueApp
//
//  Created by Ari on 4/6/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation

public struct Listings {
    typealias ProgramsDay = (julianDay: JulianDay, programs: [Program])
    
    var channels: [Channel]
    var days: [ProgramsDay]
    
    typealias SourceIdentifier = String // Limited to 6 characters

    struct Channel: Codable, UVSGDocumentable, Equatable {
        var sourceIdentifier: SourceIdentifier
        var channelNumber: String?
        var timeslotMask: TimeslotMask?
        var callLetters: String? // Limited to 5 characters on EPG Jr., 7 on Amiga
        var flags: Attributes
        
        struct Attributes: BinaryCodableOptionSet {
            let rawValue: UInt8
            
            static let none = Attributes(rawValue: 0x01) // No attribute (prevents sending NULL)
            static let hiliteSrc = Attributes(rawValue: 0x02) // Red highlight in grid
            static let sumbySrc = Attributes(rawValue: 0x04) // Summary-by-source (SBS) enabled
            static let videoTagDisable = Attributes(rawValue: 0x08) // Promotional tagging disabled
            static let cafPPVSrc = Attributes(rawValue: 0x10) // PPV source
            static let ditto = Attributes(rawValue: 0x20) // Ditto enabled
            static let althiliteSrc = Attributes(rawValue: 0x40) // Lt. blue highlight in grid
            static let stereo = Attributes(rawValue: 0x80) // Stereo source
            
            enum Options: CaseIterable {
                case none, hiliteSrc, sumbySrc, videoTagDisable, cafPPVSrc, ditto, althiliteSrc, stereo
            }
        }
    }

    struct Program: Codable, UVSGDocumentable, Equatable {
        var timeslot: Timeslot
        var sourceIdentifier: SourceIdentifier // Channel source
        var programName: SpecialCharacterString
        var flags: Attributes
        
        struct Attributes: BinaryCodableOptionSet {
            let rawValue: UInt8
            
            static let none = Attributes(rawValue: 0x01) // No attribute, always set
            static let movie = Attributes(rawValue: 0x02) // Movie
            static let altHiliteProg = Attributes(rawValue: 0x04) // Alternate highlight
            static let tagProg = Attributes(rawValue: 0x08) // Tag program
            static let sportsProg = Attributes(rawValue: 0x10) // Sports program
            static let dViewUsed = Attributes(rawValue: 0x20) // Not used?
            static let repeatProg = Attributes(rawValue: 0x40) // Repeat program ("this attribute is stored, but not used for anything")
            static let prevDaysData = Attributes(rawValue: 0x80) // Previous day's data ("this attribute is only used internally by the CG software and is therefore an implementation detail")
            
            enum Options: CaseIterable {
                case none, movie, altHiliteProg, tagProg, sportsProg, dViewUsed, repeatProg, prevDaysData
            }
        }
    }
}

extension Listings {
    var allPrograms: [Program] {
        days.flatMap { $0.programs }
    }
    
    var julianDay: JulianDay {
        days.first!.julianDay
    }
}
