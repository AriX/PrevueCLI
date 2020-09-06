//
//  ProgramCommand.swift
//  PrevueApp
//
//  Created by Ari on 4/6/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

struct ProgramCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.program
    let day: JulianDay
    let program: Program
}

extension ProgramCommand: BinaryCodable {
    static let flagsMarker: Byte = 0x12
    static let terminator: Byte = 0x00
    
    init(fromBinary decoder: BinaryDecoder) throws {
        let timeslot = try decoder.decode(Timeslot.self)
        day = try decoder.decode(JulianDay.self)
        let sourceIdentifier = try decoder.readString(until: { $0 == ProgramCommand.flagsMarker})
        let flags = try decoder.decode(ProgramAttributes.self)
        let programName = try decoder.readString(until: { $0 == 0x00})
        // There's something unhandled here - perhaps the ability to signal that a program spans multiple sources - see the "BIGC" test file for an example
        
        program = Program(timeslot: timeslot, sourceIdentifier: sourceIdentifier, programName: programName, flags: flags)
    }
    
    func binaryEncode(to encoder: BinaryEncoder) throws {
        encoder += [program.timeslot, day.dayOfYear, program.sourceIdentifier.asBytes(), ProgramCommand.flagsMarker, program.flags.rawValue, program.programName.asBytes(), ProgramCommand.terminator]
    }
}
