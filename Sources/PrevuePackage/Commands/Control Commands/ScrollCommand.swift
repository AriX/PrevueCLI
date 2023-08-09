//
//  ScrollCommands.swift
//  PrevueCLI
//
//  Created by Ari on 9/25/21.
//  Copyright © 2021 Vertex. All rights reserved.
//

import Foundation

struct ScrollCommand: ControlCommand {
    enum Operation {
        case pause
        case resume
    }
    
    let operation: Operation
    var commandMode: ControlCommandMode {
        switch operation {
        case .pause:
            return .pauseGridScroll
        case .resume:
            return .startGridScroll
        }
    }
}

extension ScrollCommand {
    var payload: Bytes {
        return [0x0D]
    }
    func binaryEncode(to encoder: BinaryEncoder) throws {
        encoder += payload
    }
    func encode(to encoder: Encoder) throws {
        // TODO
    }
    init(from decoder: Decoder) throws {
        // TODO
        fatalError("Unimplemented")
    }
}
