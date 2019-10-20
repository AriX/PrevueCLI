//
//  ConfigDatCommand.swift
//  PrevuePackage
//
//  Created by Ari on 4/6/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

/*
 config.dat format string from ESQ: %01ld%01lc%01ld%01ld%02ld%02ld%01lc%01lc%01lc%01lc%01ld%01ld%01lc%01lc%01lc%01lc%01lc%01lc%01c%02ld%02ld%01lc%01lc%01lc%02ld%02ld%02ld%03ld%01ld%2.2s%01lc%01lc%01lc%01c%01c%01d%01c%01c%01c%01c%01c%01c
 */

struct ConfigDatCommand: DataCommand {
    let commandMode = DataCommandMode.configDat
    let unknown1: UInt8 = 2 // Default 2
    let unknown2: Byte = 0x43 // C Default C
    let gridMR: UInt8 = 0 // GridMR? Default 0
    let SBS: UInt8 = 1 // SBS Default 3
    let unknown5: UInt16 = 08 // Default 24
    let unknown6: UInt16 = 08 // Default 24
    let unknown7: Byte = 0x47 // Display format. G for grid, or S for scroll. Default G.
    let unknown8: Byte = 0x4E // N Default N
    let unknown9: Byte = 0x41 // A Default A
    let unknown10: Byte = 0x45 // E Default E
    let unknown11: UInt8 = 0 // Default 0
    let sport: UInt8 = 1 // Default 0
    let unknown13: Byte = 0x4E // N Default Y.
    let unknown14: Byte = 0x4E // N Default Y.
    let unknown15: Byte = 0x4E // N Default N.
    let unknown16: Byte = 0x4E // N Default N.
    let unknown17: Byte = 0x4E // N Default Y.
    let unknown18: Byte = 0x4E // N Default N.
    let unknown19: Byte = 0x4C // L Default L.
    let unknown20: UInt16 = 29 // Default 29
    let unknown21: UInt16 = 06 // Default 6
    let cycle: Byte = 0x59 // Y Default Y.
    let unknown23: Byte = 0x59 // Y Default Y.
    let unknown24: Byte = 0x59 // Y Default N.
    let unknown25: UInt16 = 23 // Default 23
    let unknown26: UInt16 = 36 // Default 36
    let unknown27: UInt16 = 06 // Default 12
    // These next 2 are one 3-digit number? Seems to represent "CycleFreq" (default 15)
    let unknown28p1: UInt16 = 01
    let unknown28p2: UInt8 = 5
    let afterOrder: UInt8 = 1 // AftrOrder Default 1
    let unknown30: UInt16 = 00 // %2.2s? what's that?
    let unknown31: Byte = 0x59 // Y Default Y
    let unknown32: Byte = 0x4E // N Default N  - Yes to use 24 hour time, no to use AM/PM
    let unknown33: Byte = 0x59 // Y Default Y
    let unknown34: Byte = 0x43 // C ??
    let unknown35: Byte = 0x8E // ?? Default 0x8E.
    let unknown36: UInt8 = 8 // 8 Default 8.
    let unknown37: Byte = 0x4E // N Default N.
    let unknown38: Byte = 0x4E // N Default N.
    let unknown39: Byte = 0x4E // N Default N.
    let unknown40: Byte = 0x4E // N Default Y.
    let unknown41: Byte = 0x4E // N - something related to CTRL? Default N.
    let clockCmd: UInt8 // Clock command. If 1, the 'K' clock command doesn't work. If 2, it does. Default 1.
}

extension ConfigDatCommand {
    var payload: Bytes {
        let configDatBytes = [
            unknown1.byteByRepresentingNumberAsASCIIDigit(),
            unknown2,
            gridMR.byteByRepresentingNumberAsASCIIDigit(),
            SBS.byteByRepresentingNumberAsASCIIDigit(),
            unknown5.bytesBySeparatingIntoASCIIDigits()[0],
            unknown5.bytesBySeparatingIntoASCIIDigits()[1],
            unknown6.bytesBySeparatingIntoASCIIDigits()[0],
            unknown6.bytesBySeparatingIntoASCIIDigits()[1],
            unknown7,
            unknown8,
            unknown9,
            unknown10,
            unknown11.byteByRepresentingNumberAsASCIIDigit(),
            sport.byteByRepresentingNumberAsASCIIDigit(),
            unknown13,
            unknown14,
            unknown15,
            unknown16,
            unknown17,
            unknown18,
            unknown19,
            unknown20.bytesBySeparatingIntoASCIIDigits()[0],
            unknown20.bytesBySeparatingIntoASCIIDigits()[1],
            unknown21.bytesBySeparatingIntoASCIIDigits()[0],
            unknown21.bytesBySeparatingIntoASCIIDigits()[1],
            cycle,
            unknown23,
            unknown24,
            unknown25.bytesBySeparatingIntoASCIIDigits()[0],
            unknown25.bytesBySeparatingIntoASCIIDigits()[1],
            unknown26.bytesBySeparatingIntoASCIIDigits()[0],
            unknown26.bytesBySeparatingIntoASCIIDigits()[1],
            unknown27.bytesBySeparatingIntoASCIIDigits()[0],
            unknown27.bytesBySeparatingIntoASCIIDigits()[1],
            unknown28p1.bytesBySeparatingIntoASCIIDigits()[0],
            unknown28p1.bytesBySeparatingIntoASCIIDigits()[1],
            unknown28p2.byteByRepresentingNumberAsASCIIDigit(),
            afterOrder.byteByRepresentingNumberAsASCIIDigit(),
            unknown30.bytesBySeparatingIntoASCIIDigits()[0],
            unknown30.bytesBySeparatingIntoASCIIDigits()[1],
            unknown31,
            unknown32,
            unknown33,
            unknown34,
            unknown35,
            unknown36.byteByRepresentingNumberAsASCIIDigit(),
            unknown37,
            unknown38,
            unknown39,
            unknown40,
            unknown41,
            clockCmd.byteByRepresentingNumberAsASCIIDigit()
        ]
        
        let unknownByte = Byte(0x00) // Unknown! What does this mean? Perhaps unused.
        let configLength = UInt16(configDatBytes.count) + 1 // Unsure why, but it expects 1 more than the config length
        let configLengthBytes = configLength.bytesBySeparatingIntoHighAndLowBits()
        return [unknownByte, configLengthBytes[0], configLengthBytes[1]] + configDatBytes
    }
}
