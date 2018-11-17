//
//  UVSGMessage.swift
//  PrevueFramework
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation

typealias Byte = UInt8

// This is a subset of the command modes discussed here: http://prevueguide.com/wiki/UVSG_Satellite_Data#Command_Modes

enum CommandMode: Character {
    case boxOn = "A"
    case channel = "C"
    case newChannel = "c"
    case configuration = "F"
    case configDat = "f"
    case dst = "g"
    case download = "H"
    case ppvOrderInfo = "J"
    case newPPVOverInfo = "j"
    case clock = "K"
    case ad = "L"
    case clearListing = "O"
    case program = "P"
    case newProgram = "p"
    case reset = "R"
    case title = "T"
    case saveData = "%"
    case boxOff = "\u{BB}"
}

extension CommandMode {
    func asByte() -> Byte {
        let unicodeScalars = self.rawValue.unicodeScalars
        assert(unicodeScalars.count == 1, "Command mode must be a single character")
        
        let firstValue: UInt32 = unicodeScalars.first!.value
        assert(firstValue <= 255, "Command mode must be a single byte")
        
        return Byte(firstValue)
    }
}

func checksumData(<#parameters#>) -> <#return type#> {
    <#function body#>
}

struct UVSGMessage {
    let startBytes: [Byte] = [0x55, 0xAA]
    var commandMode: CommandMode
    var payload: [Byte]
    var checksum: Byte {
        get {
            var checksum: UInt8 = 0x55 ^ 0xAA ^ commandMode.asByte()
            for byte in payload {
                checksum ^= byte
            }
            
            return checksum
        }
    }
}

extension UVSGMessage {
    func asBytes() -> [Byte] {
        return (startBytes + [commandMode.asByte()] + payload + [checksum])
    }
}
