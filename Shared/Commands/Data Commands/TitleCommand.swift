//
//  TitleCommand.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

struct TitleCommand: DataCommand {
    enum Alignment: Byte {
        case center = 0x18 // ^X
        case left = 0x19 // ^Y
        case right = 0x1A // ^Z
    }
    
    let commandMode = DataCommandMode.title
    let alignment: Alignment?
    var title: String
}

// MARK: Encoding

extension TitleCommand {
    var payload: Bytes {
        return alignment.payload + title.asNullTerminatedBytes()
    }
}

extension TitleCommand.Alignment: UVSGEncodable {
    var payload: Bytes {
        return [rawValue]
    }
}

// Encode TitleAlignment as a string (e.g. "center") instead of as its byte value
extension TitleCommand.Alignment: UVSGDocumentableEnum, EnumCodableAsCaseName {
    init(from decoder: Decoder) throws {
        try self.init(asNameFrom: decoder)
    }
    func encode(to encoder: Encoder) throws {
        try encode(asNameTo: encoder)
    }
}
