//
//  TitleCommand.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

struct TitleCommand: DataCommand {
    let commandMode = DataCommandMode.title
    let alignment: TextAlignmentControlCharacter?
    var title: String
}

extension TitleCommand {
    var textAlignmentBytes: Bytes {
        guard let alignment = alignment else { return [] }
        return [alignment.rawValue]
    }
    
    var payload: Bytes {
        return textAlignmentBytes + title.uvsgBytes()
    }
}
