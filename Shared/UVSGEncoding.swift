//
//  UVSGMessage.swift
//  PrevueFramework
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation

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

protocol DataCommand: UVSGEncodable {
    var commandMode: DataCommandMode { get }
    var payload: Bytes { get }
}

extension DataCommand {
    func encode() -> Bytes {
        let startBytes: Bytes = [0x55, 0xAA]
        return (startBytes + [commandMode.asByte()] + payload)
    }
}

protocol ControlCommand: UVSGEncodable {
    var commandMode: ControlCommandMode { get }
    var payload: Bytes { get }
}

extension ControlCommand {
    func encode() -> Bytes {
        return ([commandMode.rawValue] + payload)
    }
}

extension ControlCommand {
    static func leftRightStringAsBytes(leftString: String, rightString: String) -> Bytes {
        return (leftString.asBytes() + [Byte(0x12)] + rightString.asBytes() + [Byte(0x0D)])
    }
}
