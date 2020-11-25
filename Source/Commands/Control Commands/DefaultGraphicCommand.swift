//
//  DefaultGraphicCommand.swift
//  PrevueCLI
//
//  Created by Ari on 11/23/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

struct DefaultGraphicCommand: ControlCommand {
    let commandMode = ControlCommandMode.defaultGraphic
}

extension DefaultGraphicCommand {
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
