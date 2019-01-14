//
//  CommandPayload.swift
//  PrevueFramework
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

extension BoxOnCommand: UVSGEncodableDataCommand {
    public var payload: Bytes {
        return self.selectCode.uvsgBytes()
    }
}

extension TitleCommand: UVSGEncodableDataCommand {
    public var payload: Bytes {
        return self.title.uvsgBytes()
    }
}
