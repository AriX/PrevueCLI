//
//  BoxCommands.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

struct BoxOnCommand: DataCommand {
    let commandMode = DataCommandMode.boxOn
    var selectCode: String
}

struct BoxOffCommand: DataCommand {
    let commandMode = DataCommandMode.boxOff
}

struct ResetCommand: DataCommand {
    let commandMode = DataCommandMode.reset
}

extension BoxOnCommand: UVSGEncodableDataCommand {
    var payload: Bytes {
        return self.selectCode.uvsgBytes()
    }
}

extension BoxOffCommand: UVSGEncodableDataCommand {
    var payload: Bytes {
        return [0xBB, 0x00]
    }
}

extension ResetCommand: UVSGEncodableDataCommand {
    var payload: Bytes {
        return []
    }
}
