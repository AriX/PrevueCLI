//
//  NewLookConfigurationCommand.swift
//  PrevuePackage
//
//  Created by Ari on 4/6/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

/*
 config.dat format string from ESQ: %01ld%01lc%01ld%01ld%02ld%02ld%01lc%01lc%01lc%01lc%01ld%01ld%01lc%01lc%01lc%01lc%01lc%01lc%01c%02ld%02ld%01lc%01lc%01lc%02ld%02ld%02ld%03ld%01ld%2.2s%01lc%01lc%01lc%01c%01c%01d%01c%01c%01c%01c%01c%01c
 */

struct NewLookConfigurationCommand: DataCommand, Equatable {
    enum DisplayFormat: ASCIICharacter, BinaryCodableEnum {
        case grid = "G"
        case scroll = "S"
    }
    enum TextAdFlag: ASCIICharacter, BinaryCodableEnum {
        case none = "N"
        case local = "L"
        case remote = "R"
        case satellite = "S"
    }
    static let commandMode = DataCommandMode.configDat
    let unknown1: ASCIIDigitInt = 2 // Default 2
    let unknown2: Byte = 0x43 // C Default C
    let gridMR: ASCIIDigitInt = 0 // GridMR? Default 0
    let SBS: ASCIIDigitInt = 1 // SBS Default 3
    let unknown5: ASCIIDigitsInt16 = 08 // Default 24
    let unknown6: ASCIIDigitsInt16 = 08 // Default 24
    let displayFormat: DisplayFormat // Display format. G for grid, or S for scroll. Default G.
    let unknown8: Byte = 0x4E // N Default N
    let unknown9: Byte = 0x41 // A Default A
    let unknown10: Byte = 0x45 // E Default E
    let unknown11: ASCIIDigitInt = 0 // Default 0
    let sport: ASCIIDigitInt = 1 // Default 0
    let unknown13: Byte = 0x4E // N Default Y.
    let unknown14: Byte = 0x4E // N Default Y.
    let unknown15: Byte = 0x4E // N Default N.
    let unknown16: Byte = 0x4E // N Default N.
    let unknown17: Byte = 0x4E // N Default Y.
    let unknown18: Byte = 0x4E // N Default N.
    let unknown19: Byte = 0x4C // L Default L.
    let unknown20: ASCIIDigitsInt16 = 29 // Default 29
    let unknown21: ASCIIDigitsInt16 = 06 // Default 6
    let cycle: Byte = 0x59 // Y Default Y.
    let unknown23: Byte = 0x59 // Y Default Y.
    let unknown24: Byte = 0x59 // Y Default N.
    let unknown25: ASCIIDigitsInt16 = 23 // Default 23
    let unknown26: ASCIIDigitsInt16 = 36 // Default 36
    let unknown27: ASCIIDigitsInt16 = 06 // Default 12
    // These next 2 are one 3-digit number? Seems to represent "CycleFreq" (default 15)
    let unknown28p1: ASCIIDigitsInt16 = 01
    let unknown28p2: ASCIIDigitInt = 5
    let afterOrder: ASCIIDigitInt = 1 // AftrOrder Default 1
    let unknown30: ASCIIDigitsInt16 = 00 // %2.2s? what's that?
    let unknown31: Byte = 0x59 // Y Default Y
    let unknown32: Byte = 0x4E // N Default N  - Yes to use 24 hour time, no to use AM/PM
    let unknown33: Byte = 0x59 // Y Default Y
    let unknown34: Byte = 0x43 // C ??
    let unknown35: Byte = 0x8E // ?? Default 0x8E.
    let unknown36: ASCIIDigitInt = 8 // 8 Default 8.
    let textAdFlag: TextAdFlag // Text ad/keyboard setting, N/R/L/S. Default N.
    let unknown38: Byte = 0x4E // N Default N.
    let unknown39: Byte = 0x4E // N Default N.
    let unknown40: Byte = 0x4E // N Default Y.
    let unknown41: Byte = 0x4E // N - something related to CTRL? Default N.
//    let clockCmd: ASCIIDigitInt // Clock command. If 1, the 'K' clock command doesn't work. If 2, it does. Default 1.
}

extension NewLookConfigurationCommand {
    func binaryEncode(to encoder: BinaryEncoder) throws {
        let innerEncoder = BinaryEncoder()
        try self.encode(to: innerEncoder)
        let configDatBytes = innerEncoder.data
        
        let unknownByte = Byte(0x00) // Unknown! What does this mean? Perhaps unused.
        let configLength = UInt16(configDatBytes.count) + 1 // Unsure why, but it expects 1 more than the config length
        try encoder.encode(unknownByte, configLength, configDatBytes)
    }
    init(fromBinary decoder: BinaryDecoder) throws {
        _ = try decoder.decode(Byte.self) // Read unknown byte
        let configLength = try decoder.decode(UInt16.self) - 1
        let configDatBytes = try decoder.readBytes(count: Int(configLength))
        
        let innerDecoder = BinaryDecoder(data: configDatBytes)
        // the problem is that none of the dudes in between are being read right now because they are all hardcoded
//        try self.init(from: innerDecoder)
        innerDecoder.cursor += 8
        displayFormat = try innerDecoder.decode(DisplayFormat.self)
        innerDecoder.cursor += 37
        textAdFlag = try innerDecoder.decode(TextAdFlag.self)
    }
}

// TODO: Remove once this command is fully modeled
extension NewLookConfigurationCommand: UVSGDocumentable {
    var documentedType: UVSGDocumentedType {
        return .dictionary([("displayFormat", DisplayFormat.grid.documentedType), ("textAdFlag", TextAdFlag.satellite.documentedType)])
    }
}
