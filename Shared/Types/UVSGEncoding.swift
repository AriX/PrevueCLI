//
//  UVSGMessage.swift
//  PrevueFramework
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

// TODO: Reconsider this hierarchy so encoding details don't have to be made public

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

protocol DataCommand: UVSGEncodable, Codable, CommandContainer {
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

// MARK: Common types

enum TextAlignmentControlCharacter: Byte, CaseIterable {
    case center = 0x18
    case left = 0x19
    case right = 0x1A
}

// Encode TextAlignmentControlCharacter as a string (e.g. "center") instead of an integer
extension TextAlignmentControlCharacter: Codable {
    init(from decoder: Decoder) throws {
        let stringValue = try decoder.singleValueContainer().decode(String.self)
        guard let matchingCase = Self.allCases.first(where: { $0.stringValue == stringValue }) else {
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid text alignment specified"))
        }
        
        self = matchingCase
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.stringValue)
    }
    var stringValue: String {
        String(describing: self)
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
