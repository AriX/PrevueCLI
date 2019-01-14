//
//  CommandPayload.swift
//  PrevueFramework
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

extension BoxOnCommand: UVSGEncodableDataCommand {
    var payload: [Byte] {
        return Array(self.selectCode.utf8) // check if stringis null-terminated
    }
}
