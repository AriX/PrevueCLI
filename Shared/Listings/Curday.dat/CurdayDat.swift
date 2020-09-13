//
//  CurdayDat.swift
//  PrevueCLI
//
//  Created by Ari on 9/6/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

struct CurdayDat: BinaryDecodable {
    struct Header: BinaryCodable {
        let configuration: ConfigurationCommand
        let unknown0: String
        let dataRevisionString: String
        let weatherCityCode: String
        let weatherCityName: String
        let julianDayNumber: StringConvertibleInt
        let unknownNumber: StringConvertibleInt // Possibly same as Julian day
        let unknown1: String
        let unknown2: String
    }

    struct Channel: BinaryDecodable {
        let julianDay: JulianDay
        let channelNumber: String
        let sourceIdentifier: Listings.SourceIdentifier
        let callLetters: String
        let flags: Listings.Channel.Attributes
        let timeslotMask: Bytes
        let blackoutMask: Bytes
        let flag2: Byte
        let backgroundColor: UInt16
        let brushID: Bytes
        let flag3: Byte
        let sourceIdentifier2: Listings.SourceIdentifier
        let programs: [Program]
        
        struct Program: BinaryDecodable {
            let timeslot: StringConvertibleInt
            let flags: StringConvertibleInt
            let programType: String
            let movieCategory: String
            let unknown: String
            let programName: SpecialCharacterString
        }
    }
    
    let header: Header
    let channels: [Channel]
}

// MARK: Binary decoding

extension CurdayDat.Channel {
    init(fromBinary outerDecoder: BinaryDecoder) throws {
        let julianDay = try outerDecoder.decode(JulianDay.self)
        
        let channelBlock = try outerDecoder.read(until: { $0 == julianDay.dayOfYear }, consumingFinalByte: false)
        let decoder = BinaryDecoder(data: channelBlock)
        
        self.julianDay = julianDay
        channelNumber = try decoder.readString(count: 5)
        _ = try decoder.readBytes(count: 6) // Unknown NULL bytes
        sourceIdentifier = try decoder.readString(count: 6)
        _ = try decoder.readBytes(count: 1) // Unknown NULL byte
        callLetters = try decoder.readString(count: 6)
        _ = try decoder.readBytes(count: 2) // Unknown NULL bytes
        flags = try decoder.decode(Listings.Channel.Attributes.self) // Flags
        timeslotMask = try decoder.readBytes(count: 6) // Timeslot mask
        blackoutMask = try decoder.readBytes(count: 6) // Blackout mask
        flag2 = try decoder.decode(Byte.self) // Flag pt 2
        backgroundColor = try decoder.decode(UInt16.self)
        brushID = try decoder.readBytes(count: 2) // Brush ID
        _ = try decoder.readBytes(count: 2) // Unknown NULL bytes
        flag3 = try decoder.decode(Byte.self) // Flag 3
        sourceIdentifier2 = try decoder.decode(String.self)
        programs = try decoder.decode([Program].self)
    }
}

// MARK: Convenience

extension CurdayDat {
    init(with data: Data) throws {
        let unpackedData = try data.unpackPowerPacker2Data()
        self = try BinaryDecoder.decode(CurdayDat.self, data: [UInt8](unpackedData))
    }
}
