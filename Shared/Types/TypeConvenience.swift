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
protocol EnumCodableAsCaseName: Codable, CaseIterable, UVSGDocumentableEnum {
    init(asNameFrom decoder: Decoder) throws
    func encode(asNameTo encoder: Encoder) throws
}

// Protocol to allow option sets to be coded using the name of their options rather than the raw value
protocol OptionSetCodableAsOptionNames: OptionSet, Codable, UVSGDocumentableOptionSet where RawValue: BinaryInteger {
    init(asNamesFrom decoder: Decoder) throws
    func encode(asNamesTo encoder: Encoder) throws
    
    associatedtype Options: CaseIterable
}

extension EnumCodableAsCaseName {
    init(asNameFrom decoder: Decoder) throws {
        let stringValue = try decoder.singleValueContainer().decode(String.self)
        guard let matchingCase = Self.allCases.first(where: { $0.stringValue == stringValue }) else {
            throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid enum case specified"))
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
    static var allCaseNames: [String] {
        allCases.map { $0.stringValue }
    }
}

extension OptionSetCodableAsOptionNames {
    init(asNamesFrom decoder: Decoder) throws {
        var optionNames: [String] = []
        if decoder.userInfo[.csvCoding] as? Bool == true {
            // For CSV decoding, treat flags as a set of option names separated by '|'
            let optionNamesString = try decoder.singleValueContainer().decode(String.self)
            optionNames = optionNamesString.components(separatedBy: "|")
        } else {
            // For normal decoding, treat flags as an array of option names
            optionNames = try decoder.singleValueContainer().decode([String].self)
        }
        
        var rawValue: Int = 0
        
        for optionName in optionNames {
            if let optionIndex = Self.allOptionNames.firstIndex(where: { $0 == optionName }) {
                rawValue |= (1 << optionIndex)
            } else {
                throw DecodingError.typeMismatch(Self.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid option specified: \(optionName)\nValid options: \(Self.allOptionNames)"))
            }
        }
        
        self.init(rawValue: RawValue(rawValue))
    }
    func encode(asNamesTo encoder: Encoder) throws {
        let numberOfBits = MemoryLayout<RawValue>.size
        let allOptionNames = Self.allOptionNames
        var optionNames: [String] = []
        
        for optionIndex in 0...numberOfBits {
            let optionValue = (1 << optionIndex)
            if (Int(rawValue) & optionValue) == optionValue {
                if allOptionNames.indices.contains(optionIndex) {
                    optionNames.append(allOptionNames[optionIndex])
                }
            }
        }
        
        var container = encoder.singleValueContainer()
        
        if encoder.userInfo[.csvCoding] as? Bool == true {
            let optionNamesString = optionNames.joined(separator: "|")
            try container.encode(optionNamesString)
        } else {
            try container.encode(optionNames)
        }
    }
    static var allOptionNames: [String] {
        Options.allCases.map { String(describing: $0) }
    }
}
