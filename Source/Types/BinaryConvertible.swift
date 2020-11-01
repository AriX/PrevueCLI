//
//  ASCIITypes.swift
//  PrevueCLI
//
//  Created by Ari on 8/31/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

// MARK: ASCIICharacter type

struct ASCIICharacter: Equatable {
    let character: Character
    
    init?(_ character: Character) {
        guard character.unicodeScalars.count == 1,
              let firstScalar = character.unicodeScalars.first,
              firstScalar.value < 255 else { return nil }
        
        self.character = character
    }
    var asciiValue: Byte {
        let unicodeScalars = character.unicodeScalars
        let firstValue: UInt32 = unicodeScalars.first!.value
        return Byte(firstValue)
    }
    init?(asciiValue: Byte) {
        let character = Character(UnicodeScalar(asciiValue))
        self.init(character)
    }
}

extension ASCIICharacter: BinaryCodable {
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(Byte.self)
        guard let initializedSelf = Self(asciiValue: value) else {
            throw BinaryDecoder.Error.invalidUTF8([value])
        }
        
        self = initializedSelf
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(asciiValue)
    }
}

extension ASCIICharacter: LosslessStringConvertible {
    init?(_ description: String) {
        guard let firstCharacter = description.first else { return nil }
        character = firstCharacter
    }
    var description: String {
        return String(character)
    }
}

extension ASCIICharacter: ExpressibleByUnicodeScalarLiteral {
    init(unicodeScalarLiteral value: Character) {
        character = value
    }
}

// Operators
extension ASCIICharacter {
    static func +(left: ASCIICharacter, right: ASCIICharacter) -> ASCIICharacter? {
        let total = left.asciiValue + right.asciiValue
        return ASCIICharacter(asciiValue: total)
    }
    static func +(left: ASCIICharacter, right: Byte) -> ASCIICharacter? {
        guard let rightLetter = ASCIICharacter(asciiValue: right) else { return nil }
        return left + rightLetter
    }
}

// MARK: BinaryConvertible

protocol BinaryConvertible: BinaryCodable, UVSGDocumentable, CustomStringConvertible {
    associatedtype UnderlyingType: Codable
    associatedtype BinaryType: BinaryCodable
    
    var value: UnderlyingType { get }
    
    init(_ value: UnderlyingType)
    init?(binaryValue: BinaryType)
    func asBinaryValue() -> BinaryType?
}

extension BinaryConvertible {
    // BinaryCodable
    init(fromBinary decoder: BinaryDecoder) throws {
        let value = try decoder.decode(BinaryType.self)
        guard let initializedSelf = Self(binaryValue: value) else {
            let errorContext = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Failed to initialize \(Self.self)")
            throw DecodingError.dataCorrupted(errorContext)
        }
        self = initializedSelf
    }
    func binaryEncode(to encoder: BinaryEncoder) throws {
        guard let binaryValue = asBinaryValue() else {
            let errorContext = EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Failed to get binary value")
            throw EncodingError.invalidValue(self, errorContext)
        }
        
        var container = encoder.singleValueContainer()
        try container.encode(binaryValue)
    }
    
    // Codable
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(UnderlyingType.self)
        self.init(value)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    // UVSGDocumentable
    var documentedType: UVSGDocumentedType {
        if let documentedValue = value as? UVSGDocumentable {
            return documentedValue.documentedType
        } else {
            return UVSGDocumentedType.scalar(String(describing: UnderlyingType.self))
        }
    }
    
    // CustomStringConvertible
    var description: String {
        return String(describing: value)
    }
}

protocol BinaryConvertibleInteger: BinaryConvertible, ExpressibleByIntegerLiteral where IntegerLiteralType == UnderlyingType {
}

extension BinaryConvertibleInteger {
    init(integerLiteral: UnderlyingType) {
        self.init(integerLiteral)
    }
}

// MARK: Types convertible to/from ASCII characters

struct ASCIICharacterBool: BinaryConvertible, ExpressibleByBooleanLiteral, Equatable {
    let value: Bool
    
    init(booleanLiteral: Bool) {
        value = booleanLiteral
    }
    init(_ value: Bool) {
        self.value = value
    }
    init?(binaryValue: ASCIICharacter) {
        value = (binaryValue == "Y" ? true : false)
    }
    func asBinaryValue() -> ASCIICharacter? {
        return (value ? "Y" : "N")
    }
}

struct ASCIICharacterInt: BinaryConvertibleInteger, Equatable {
    let value: Int8
    
    init(_ value: Int8) {
        self.value = value
    }
    init?(binaryValue: ASCIICharacter) {
        value = Int8(binaryValue.asciiValue - ASCIICharacter("A").asciiValue)
    }
    func asBinaryValue() -> ASCIICharacter? {
        return (ASCIICharacter("A") + UInt8(value))
    }
}

struct ASCIIDigitInt: BinaryConvertibleInteger, Equatable {
    let value: Int8
    
    init(_ value: Int8) {
        self.value = value
    }
    init?(binaryValue: ASCIICharacter) {
        guard let intValue = Int8(String(binaryValue)) else { return nil }
        value = intValue
    }
    func asBinaryValue() -> ASCIICharacter? {
        let digitString = String(format: "%1d", value)
        return ASCIICharacter(digitString)
    }
}

struct ASCIIDigitsInt16: BinaryConvertibleInteger, Equatable {
    let value: Int16

    init(_ value: Int16) {
        self.value = value
    }
    init?(binaryValue: UInt16) {
        let bytes = [UInt8(binaryValue >> 8), UInt8(binaryValue & 0xFF)]
        guard let string = String(bytes: bytes, encoding: .ascii),
              let value = Int16(string) else { return nil }
        
        self.init(value)
    }
    func asBinaryValue() -> UInt16? {
        let string = String(format: "%02d", value)
        let characters = Array(string)
        guard let digit1 = characters[0].asciiValue,
              let digit2 = characters[1].asciiValue else { return nil }
        
        return (UInt16(digit2) + UInt16(digit1) << 8)
    }
}

// MARK: Types converting to/from strings

// A type that reads a null-terminated string and converts it to an Int
struct StringConvertibleInt: BinaryConvertibleInteger, Equatable {
    let value: Int
    
    init(_ value: Int) {
        self.value = value
    }
    init?(binaryValue: String) {
        guard let value = Int(binaryValue) else { return nil }
        self.value = value
    }
    func asBinaryValue() -> String? {
        return value.description
    }
}
