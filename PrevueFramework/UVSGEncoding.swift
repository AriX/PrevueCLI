//
//  UVSGMessage.swift
//  PrevueFramework
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation

typealias Byte = UInt8

extension DataCommandMode {
    func asByte() -> Byte {
        let unicodeScalars = self.rawValue.unicodeScalars
        assert(unicodeScalars.count == 1, "Command mode must be a single character")
        
        let firstValue: UInt32 = unicodeScalars.first!.value
        assert(firstValue <= 255, "Command mode must be a single byte")
        
        return Byte(firstValue)
    }
}

//struct UVSGDataCommand: UVSGPackable {
//    let startBytes: [Byte] = [0x55, 0xAA]
//    var commandMode: CommandMode
//    var payload: [Byte]
//
//    func pack() -> [Byte] {
//        return (startBytes + [commandMode.asByte()] + payload)
//    }
//}


protocol UVSGEncodableDataCommand: UVSGEncodable {
    var commandMode: DataCommandMode { get }
    var payload: [Byte] { get }
}

extension UVSGEncodableDataCommand {
    func encode() -> [Byte] {
        let startBytes: [Byte] = [0x55, 0xAA]
        return (startBytes + [commandMode.asByte()] + payload)
    }
}

//struct UVSGOnCommand: UVSGDataCommand {
//    let commandMode: DataCommandMode = .boxOn
//    var payload: [Byte] {
//        return []
//    }
//}
