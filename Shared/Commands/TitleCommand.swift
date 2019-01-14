//
//  TitleCommand.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

struct TitleCommand: DataCommand {
    let commandMode = DataCommandMode.title
    var title: String
}

extension TitleCommand: UVSGEncodableDataCommand {
    var payload: Bytes {
        return self.title.uvsgBytes()
    }
}
