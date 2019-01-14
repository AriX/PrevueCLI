//
//  UVSGMessage.swift
//  PrevueFramework
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation

// MARK: Types

public typealias Byte = UInt8
public typealias Bytes = [Byte]

extension DataCommandMode {
    func asByte() -> Byte {
        let unicodeScalars = self.rawValue.unicodeScalars
        assert(unicodeScalars.count == 1, "Command mode must be a single character")
        
        let firstValue: UInt32 = unicodeScalars.first!.value
        assert(firstValue <= 255, "Command mode must be a single byte")
        
        return Byte(firstValue)
    }
}

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

public protocol UVSGEncodable {
    func encode() -> Bytes
    func encodeWithChecksum() -> Bytes
}

extension UVSGEncodable {
    public func encodeWithChecksum() -> Bytes {
        let encoded = encode()
        return (encoded + [encoded.checksum])
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

// MARK: Commands

public protocol UVSGEncodableDataCommand: UVSGEncodable {
    var commandMode: DataCommandMode { get }
    var payload: Bytes { get }
}

extension UVSGEncodableDataCommand {
    public func encode() -> Bytes {
        let startBytes: Bytes = [0x55, 0xAA]
        return (startBytes + [commandMode.asByte()] + payload)
    }
}

// MARK: Strings

extension String {
    public func uvsgBytes() -> Bytes {
        return (Array(self.utf8) + [0x00])
    }
}

// MARK: Debugging

extension Array where Element == Byte {
    public func hexEncodedString() -> String {
        return map { String(format: "%02hhX ", $0) }.joined()
    }
}
