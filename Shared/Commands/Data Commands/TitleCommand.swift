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

extension TitleCommand {
    init(centeredTitle: String) {
        let characterLimit = 40
        let spacesToAdd = (characterLimit - centeredTitle.count) / 2
        
        let space = " "
        let spaces = String(repeating: space, count: spacesToAdd)
        
        self.init(title: spaces + centeredTitle)
    }
}

extension TitleCommand {
    var payload: Bytes {
        return title.uvsgBytes()
    }
}
