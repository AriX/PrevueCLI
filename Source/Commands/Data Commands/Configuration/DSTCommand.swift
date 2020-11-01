//
//  DSTCommand.swift
//  PrevuePackage
//
//  Created by Ari on 9/26/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

struct DSTBoundary: BinaryCodableStruct, Equatable {
    let year: Int
    let dayOfYear: Int
    let hour: Int
    let minute: Int
}

struct DSTCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.daylightSavingsTime
    enum Mode: ASCIICharacter, BinaryCodableEnum {
        case local = "2"
        case global = "3"
    }
    let mode: Mode
    let start: DSTBoundary
    let end: DSTBoundary
}

// MARK: Convenience

extension DSTBoundary {
    init(from date: Date, timeZone: TimeZone = .current) {
        let components = Calendar.current.dateComponents(in: timeZone, from: date)
        year = components.year!
        dayOfYear = JulianDay(from: date).dayOfYear
        hour = components.hour!
        minute = components.minute!
    }
}

extension DSTCommand.Mode {
    var timeZone: TimeZone {
        switch self {
        case .global:
            return .tulsa
        case .local:
            return .current
        }
    }
}

struct CurrentDSTCommand: MetaCommand {
    var commands: [DataCommand] {
        let currentDate = Date()
        
        return DSTCommand.Mode.allCases.flatMap { (mode) -> [DSTCommand] in
            let timeZone = mode.timeZone
            guard let period = timeZone.nextDaylightSavingsTimePeriod(for: currentDate) else { return [] }
            
            let startBoundary = DSTBoundary(from: period.start, timeZone: timeZone)
            let endBoundary = DSTBoundary(from: period.end, timeZone: timeZone)
            
            return [DSTCommand(mode: mode, start: startBoundary, end: endBoundary)]
        }
    }
}

// MARK: Encoding

extension DSTBoundary {
    static let startMarker: Byte = 0x04 // ^D
    static let endMarker: Byte = 0x13 // ^S
    
    func binaryEncode(to encoder: BinaryEncoder) throws {
        let string = String(format: "%04d%03d%02d:%02d", year, dayOfYear, hour, minute)
        encoder += string.asBytes
    }
    
    init(fromBinary decoder: BinaryDecoder) throws {
        let yearString = try decoder.readString(count: 4)
        let dayOfYearString = try decoder.readString(count: 3)
        let hourString = try decoder.readString(count: 2)
        _ = try decoder.readString(count: 1) // Expect colon
        let minuteString = try decoder.readString(count: 2)
        
        guard let year = Int(yearString), let dayOfYear = Int(dayOfYearString), let hour = Int(hourString), let minute = Int(minuteString) else {
            throw BinaryDecoder.Error.malformedData(description: "Failed to parse DST date boundary")
        }
        
        self.year = year
        self.dayOfYear = dayOfYear
        self.hour = hour
        self.minute = minute
    }
}

extension DSTCommand {
    func binaryEncode(to encoder: BinaryEncoder) throws {
        let payloadEncoder = BinaryEncoder()
        try payloadEncoder.encode(DSTBoundary.startMarker, start, DSTBoundary.endMarker, end, Byte(0x00))
        
        let payload = payloadEncoder.data
        let payloadLength = String(format: "%02d", payload.count).asBytes
        
        try encoder.encode(mode, payloadLength, payload)
    }
    
    init(fromBinary decoder: BinaryDecoder) throws {
        mode = try decoder.decode(Mode.self)
        _ = try decoder.readBytes(count: 2)
        _ = try decoder.readBytes(count: 1) // Expect start marker
        start = try decoder.decode(DSTBoundary.self)
        _ = try decoder.readBytes(count: 1) // Expect end marker
        end = try decoder.decode(DSTBoundary.self)
        _ = try decoder.readBytes(count: 1) // Expect terminator
    }
    
}
