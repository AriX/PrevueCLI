//
//  ProgramCommand.swift
//  PrevueApp
//
//  Created by Ari on 4/6/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

struct ProgramCommand: DataCommand {
    let commandMode = DataCommandMode.program
    let program: Program
}

extension Program {
    var payload: Bytes {
        return Array([[timeslot, day.dayOfYear], sourceIdentifier.asBytes(), [0x12], [flags.rawValue], programName.asBytes(), [0x00]].joined())
    }
}

extension ProgramCommand {
    var payload: Bytes {
        return program.payload
    }
}
