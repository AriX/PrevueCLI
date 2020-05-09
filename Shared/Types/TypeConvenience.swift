//
//  TypeConvenience.swift
//  PrevueCLI
//
//  Created by Ari on 5/8/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

// Allow optional UVSGEncodable values to implement UVSGEncodable, by returning an empty payload
extension Optional: UVSGEncodable where Wrapped: UVSGEncodable {
    var payload: Bytes {
        if let self = self {
            return self.payload
        } else {
            return []
        }
    }
}

// Protocol to allow enums to be coded using the name of their cases rather than their values
protocol EnumCodableAsCaseName: Codable, CaseIterable {
    init(asNameFrom decoder: Decoder) throws
    func encode(asNameTo encoder: Encoder) throws
}

extension EnumCodableAsCaseName {
    init(asNameFrom decoder: Decoder) throws {
        let stringValue = try decoder.singleValueContainer().decode(String.self)
        guard let matchingCase = Self.allCases.first(where: { $0.stringValue == stringValue }) else {
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid text alignment specified"))
        }
        
        self = matchingCase
    }
    func encode(asNameTo encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.stringValue)
    }
    var stringValue: String {
        String(describing: self)
    }
}
