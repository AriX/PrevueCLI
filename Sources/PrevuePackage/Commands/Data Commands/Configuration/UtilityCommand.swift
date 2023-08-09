//
//  UtilityCommand.swift
//  PrevuePackage
//
//  Created by Ari on 4/15/22.
//  Copyright © 2022 Vertex. All rights reserved.
//

import Foundation

struct UtilityCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.utility
    enum Mode: ASCIICharacter, EnumCodableAsCaseName {
        case reloadLogoListFile = "5"
        case reloadScrollBanner = "6"
        case reloadBrushes = "a"
    }
    let mode: Mode
}

extension UtilityCommand {
    func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(ASCIICharacter("3"))
        try encoder.encode(ASCIICharacter("3"))
        try encoder.encode(mode.rawValue)
        try encoder.encode(Byte(0x00))
    }
    
    init(fromBinary decoder: BinaryDecoder) throws {
        _ = try decoder.readBytes(count: 2)
        let modeValue = try decoder.decode(ASCIICharacter.self)
        if let mode = Mode(rawValue: modeValue) {
            self.mode = mode
        } else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported UtilityCommand.Mode")
            throw DecodingError.valueNotFound(UtilityCommand.Mode.self, context)
        }
    }
    
}

// TODO: Merge

struct UtilityRunShellCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.utility
    let command: String
}

extension UtilityRunShellCommand {
    func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(ASCIICharacter("3"))
        try encoder.encode(ASCIICharacter("2"))
        try encoder.encode(command)
    }
    
    init(fromBinary decoder: BinaryDecoder) throws {
//        _ = try decoder.readBytes(count: 2)
//        let modeValue = try decoder.decode(ASCIICharacter.self)
//        if let mode = Mode(rawValue: modeValue) {
//            self.mode = mode
//        } else {
//            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported UtilityCommand.Mode")
//            throw DecodingError.valueNotFound(UtilityCommand.Mode.self, context)
//        }
        // todo
        command = ""
    }
    
}
