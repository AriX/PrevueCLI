//
//  UVSGMessage.swift
//  PrevueFramework
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation

// MARK: Types

typealias Byte = UInt8
typealias Bytes = [Byte]

// MARK: Checksums

protocol UVSGChecksummable {
    var checksum: Byte { get }
}

extension Array: UVSGChecksummable where Element == Byte {
    var checksum: Byte {
        var checksum = UInt8(0)
        for byte in self {
            checksum ^= byte
        }
        
        return checksum
    }
}

protocol UVSGEncodable {
    func encode() -> Bytes
    func encodeWithChecksum() -> Bytes
}

extension UVSGEncodable {
    func encodeWithChecksum() -> Bytes {
        let encoded = encode()
        return (encoded + [encoded.checksum])
    }
}

// MARK: Commands

protocol DataCommand {
    var commandMode: DataCommandMode { get }
}

protocol UVSGEncodableDataCommand: UVSGEncodable {
    var commandMode: DataCommandMode { get }
    var payload: Bytes { get }
}

extension UVSGEncodableDataCommand {
    func encode() -> Bytes {
        let startBytes: Bytes = [0x55, 0xAA]
        return (startBytes + [commandMode.asByte()] + payload)
    }
}

// MARK: Type conversion

// TODO: Make a protocol for this

extension Character {
    func asByte() -> Byte {
        let unicodeScalars = self.unicodeScalars
        assert(unicodeScalars.count == 1, "Character must be a single unicode scalar")
        
        let firstValue: UInt32 = unicodeScalars.first!.value
        assert(firstValue <= 255, "Character must be a single byte")
        
        return Byte(firstValue)
    }
}

extension DataCommandMode {
    func asByte() -> Byte {
        return self.rawValue.asByte()
    }
}

extension String {
    func uvsgBytes() -> Bytes {
        return (Array(self.utf8) + [0x00])
    }
}

extension Bool {
    func asByte() -> Byte {
        return (self ? Byte(1) : Byte(0))
    }
}

// MARK: Debugging

extension Array where Element == Byte {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhX ", $0) }.joined()
    }
}
