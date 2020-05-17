//
//  UVSGMessage.swift
//  PrevueFramework
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

protocol UVSGEncodable: UVSGDocumentable {
    var payload: Bytes { get }
}

// MARK: Commands

protocol UVSGCommand: UVSGEncodable {
    var encoded: Bytes { get }
    var encodedWithChecksum: Bytes { get }
}

protocol DataCommand: UVSGCommand, Codable, CommandContainer {
    var commandMode: DataCommandMode { get }
}

extension DataCommand {
    var encoded: Bytes {
        let startBytes: Bytes = [0x55, 0xAA]
        return (startBytes + [commandMode.asByte()] + payload)
    }
}

protocol ControlCommand: UVSGCommand {
    var commandMode: ControlCommandMode { get }
}

extension ControlCommand {
    var encoded: Bytes {
        return ([commandMode.rawValue] + payload)
    }
}

// MARK: Checksumming

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

extension UVSGCommand {
    var encodedWithChecksum: Bytes {
        let encoded = self.encoded
        return (encoded + [encoded.checksum])
    }
}

// MARK: Common types

extension ControlCommand {
    static func leftRightStringAsBytes(leftString: String, rightString: String) -> Bytes {
        return (leftString.asBytes() + [Byte(0x12)] + rightString.asBytes() + [Byte(0x0D)])
    }
}

// MARK: Command containers

protocol CommandContainer {
    var commands: [DataCommand] { get }
}

extension DataCommand {
    var commands: [DataCommand] {
        return [self]
    }
}
