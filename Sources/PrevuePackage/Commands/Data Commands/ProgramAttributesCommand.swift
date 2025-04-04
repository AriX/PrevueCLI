//
//  ProgramAttributesCommand.swift
//  PrevuePackage
//
//  Created by Ari on 8/9/23.
//  Copyright © 2023 Vertex. All rights reserved.
//

/*
struct ProgramAttributesCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.programAttributes
    let day: JulianDay
    let sourceIdentifier: Listings.SourceIdentifier
    struct Attributes: BinaryCodable, Equatable {
        let programType: Byte
        let movieCategory: Byte
        let color: Byte
    }
    let programAttributes: [Timeslot: Attributes]
}

extension ProgramAttributesCommand: BinaryCodable {
    static let endOfStringMarker: Byte = 0x12 // ^R
    static let terminator: Byte = 0x00
    
    init(fromBinary decoder: BinaryDecoder) throws {
        day = try decoder.decode(JulianDay.self)
        sourceIdentifier = try decoder.readString(until: { $0 == Self.endOfStringMarker})
        let timeslotMask = try decoder.decode(TimeslotMask.self)
        let attributeCount = try decoder.decode(Byte.self)
        var programAttributes: [Timeslot: Attributes] = [:]
        for timeslot in timeslotMask.timeslots {
            let attributeData = try decoder.readBytes(count: Int(attributeCount))
            programAttributes[timeslot] = try BinaryDecoder(data: attributeData).decode(Attributes.self)
        }
        self.programAttributes = programAttributes
        _ = try decoder.readBytes(count: 1) // Expect terminator
    }
    
    func binaryEncode(to encoder: BinaryEncoder) throws {
        encoder += [day.asByte, sourceIdentifier.asBytes, Self.endOfStringMarker]
        let timeslots = programAttributes.keys.sorted()
        try encoder.encode(TimeslotMask(timeslots: timeslots))
        for timeslot in timeslots {
            guard let attributes = programAttributes[timeslot] else { throw EncodingError.invalidValue(programAttributes, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Missing attributes for timeslot \(timeslot)")) }
            try encoder.encode(attributes.attributeCount)
            try encoder.encode(attributes)
        }
        encoder += Byte(Self.terminator)
    }
}

extension ProgramAttributesCommand.Attributes {
    // need to actually write this
    
    var attributeCount: Byte {
        var count: Byte = 1 // programType
        if movieCategory != nil {
            count += 1
        }
        if color != nil {
            count += 1
        }
        return count
    }
}*/

//extension ProgramAttributesCommand.Attributes: BinaryCodable {
//    init(fromBinary decoder: BinaryDecoder) throws {
//        let attributeCount = try decoder.decode(Byte.self)
//        let attributeData = try decoder.readBytes(count: Int(attributeCount))
//        
//    }
//    
//    func binaryEncode(to encoder: BinaryEncoder) throws {
//        
//    }
//}
