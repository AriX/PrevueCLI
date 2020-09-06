//
//  BinaryCodableOptionSet.swift
//  PrevueCLI
//
//  Created by Ari on 7/4/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

// Protocol that allows an OptionSet to be coded as its raw value with BinaryCodable, and as an option name with Codable
protocol BinaryCodableOptionSet: OptionSet, BinaryCodable, UVSGDocumentableOptionSet where RawValue: BinaryInteger & Codable {
    associatedtype Options: CaseIterable
}

// MARK: BinaryCodable

extension BinaryCodableOptionSet {
    init(fromBinary decoder: BinaryDecoder) throws {
        let rawValue = try decoder.decode(RawValue.self)
        self.init(rawValue: rawValue)
    }
    func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(rawValue)
    }
}

// MARK: Codable

extension BinaryCodableOptionSet {
    init(from decoder: Decoder) throws {
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
    func encode(to encoder: Encoder) throws {
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
}

// MARK: UVSGDocumentableOptionSet

extension BinaryCodableOptionSet {
    static var allOptionNames: [String] {
        Options.allCases.map { String(describing: $0) }
    }
}
