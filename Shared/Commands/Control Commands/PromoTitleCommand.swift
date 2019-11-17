//
//  PromoTitleCommand.swift
//  PrevueCLI
//
//  Created by Ari on 11/12/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

// TODO: Control character formatting as specified in D110.doc

struct PromoTitleCommand: ControlCommand {
    let commandMode = ControlCommandMode.titleStrings
    var leftTitle: String // Max 55 characters
    var rightTitle: String // Max 55 characters
}

extension PromoTitleCommand {
    var payload: Bytes {
        return PromoTitleCommand.leftRightStringAsBytes(leftString: leftTitle, rightString: rightTitle)
    }
}
