//
//  TitleCommand.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

struct TitleCommand: DataCommand, Equatable {
    enum Alignment: Byte, BinaryCodableEnum {
        case center = 0x18 // ^X
        case left = 0x19 // ^Y
        case right = 0x1A // ^Z
    }
    
    static let commandMode = DataCommandMode.title
    let alignment: Alignment?
    let title: String
}
