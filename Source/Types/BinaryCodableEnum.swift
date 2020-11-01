//
//  BinaryCodableEnum.swift
//  PrevueCLI
//
//  Created by Ari on 7/4/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

// Protocol that allows an enum to be coded as its raw value with BinaryCodable, and as a case name wih Codable
protocol BinaryCodableEnum: BinaryCodable, UVSGDocumentableEnum, RawRepresentable, CaseIterable where RawValue: BinaryCodable {
}

// MARK: BinaryCodable

extension BinaryCodableEnum {
    init(fromBinary decoder: BinaryDecoder) throws {
        let rawValue = try RawValue(fromBinary: decoder)
        guard let enumValue = Self(rawValue: rawValue) else {
            throw BinaryDecoder.Error.invalidEnumCase(rawValue)
        }
        
        self = enumValue
    }
    func binaryEncode(to encoder: BinaryEncoder) throws {
        try rawValue.binaryEncode(to: encoder)
    }
    static func binaryDecodesToNil(with decoder: BinaryDecoder) throws -> Bool {
        // Back up cursor location
        let cursor = decoder.cursor
        
        // Try decoding a value to see if we can
        let rawValue = try RawValue(fromBinary: decoder)
        let enumValue = Self(rawValue: rawValue)
        
        // Restore cursor to prior location
        decoder.cursor = cursor
        
        switch enumValue {
        case .some:
            return false
        case .none:
            return true
        }
    }
    init?(ifPresentFromBinary decoder: BinaryDecoder) throws {
        if try Self.binaryDecodesToNil(with: decoder) {
            return nil
        }
        
        try self.init(fromBinary: decoder)
    }
}

// MARK: Codable

extension BinaryCodableEnum {
    init(from decoder: Decoder) throws {
        let stringValue = try decoder.singleValueContainer().decode(String.self)
        guard let matchingCase = Self.allCases.first(where: { $0.stringValue == stringValue }) else {
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid enum case specified: \(stringValue)"))
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

// MARK: UVSGDocumentableEnum

extension BinaryCodableEnum {
    static var allCaseNames: [String] {
        allCases.map { $0.stringValue }
    }
}
