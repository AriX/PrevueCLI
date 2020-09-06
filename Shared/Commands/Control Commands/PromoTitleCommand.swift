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
        return Bytes.leftRightStringAsBytes(leftString: leftTitle, rightString: rightTitle)
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
