//
//  DataSending+AriDebugCTRL.swift
//  PrevueApp
//
//  Created by Ari on 11/4/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

extension DataDestination {
    func sendDebugCTRLByte(byte: Byte) {
        send(data: AddDebugCTRLByteCommand(byte: byte))
    }
}

// Uses the fake "mode G" I added to ESQ
struct AddDebugCTRLByteCommand: DataCommand {
    let commandMode = DataCommandMode.debugAddCTRLByte
    var byte: Byte
}

extension AddDebugCTRLByteCommand {
    var payload: Bytes {
        return [byte]
    }
}
