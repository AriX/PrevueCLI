//
//  SpecialCharacterString.swift
//  PrevuePackage
//
//  Created by Ari on 9/12/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

struct SpecialCharacterString: Equatable {
    enum Component: Equatable {
        case string(String)
        case specialCharacter(Byte)
    }
    let components: [Component]
}

extension SpecialCharacterString: BinaryCodable {
    init(with bytes: Bytes) {
        var components: [Component] = []
        var workingString = ""
        
        for byte in bytes {
            let character = Character(with: byte)
            if character.isASCII {
                workingString.append(character)
            } else {
                if workingString.count > 0 {
                    components.append(.string(workingString))
                }
                
                workingString = ""
                components.append(.specialCharacter(byte))
            }
        }
        
        if workingString.count > 0 {
            components.append(.string(workingString))
        }
        
        self.components = components
    }
    var asBytes: Bytes {
        let bytes = components.flatMap { (component) -> Bytes in
            switch component {
            case .string(let string):
                return string.asBytes()
            case .specialCharacter(let specialCharacter):
                return [specialCharacter]
            }
        }
        
        let nullTerminator: Bytes = [0x00]
        return (bytes + nullTerminator)
    }
    init(fromBinary decoder: BinaryDecoder) throws {
        let bytes = try decoder.read(until: { $0 == 0x00 })
        self.init(with: bytes)
    }
    func binaryEncode(to encoder: BinaryEncoder) throws {
        encoder += self.asBytes
    }
}

extension SpecialCharacterString: Codable, LosslessStringConvertible, ExpressibleByStringLiteral {
    init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        self.init(with: string)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
    init(with string: String) {
        var components: [Component] = []
        var currentIndex = string.startIndex
        
        // Find the next escape sequence
        while let range = string.range(of: "\\{", options: [], range: currentIndex..<string.endIndex, locale: nil) {
            // Make sure this is a valid escape sequence
            if let sequenceEndRange = string.range(of: "}", options: [], range: range.upperBound..<string.endIndex, locale: nil),
                string.distance(from: range.upperBound, to: sequenceEndRange.lowerBound) == 2 {
                // Put any characters found since the last escape sequence into `components` as a string
                let interveningString = string[currentIndex..<range.lowerBound]
                components.append(.string(String(interveningString)))
                
                // Get the special character inside the escape sequence
                let specialCharacterString = string[range.upperBound..<sequenceEndRange.lowerBound]
                if let specialCharacter = Byte(specialCharacterString, radix: 16) {
                    components.append(.specialCharacter(specialCharacter))
                }
                
                // Advance the current index to the end of the escape sequence
                currentIndex = sequenceEndRange.upperBound
            } else {
                currentIndex = range.upperBound
            }
        }
        
        // Add the rest of the string as a component
        if currentIndex != string.endIndex {
            let remainderString = string[currentIndex..<string.endIndex]
            components.append(.string(String(remainderString)))
        }
        
        self.components = components
    }
    var description: String {
        return components.map { (component) -> String in
            switch component {
            case .string(let string):
                return string
            case .specialCharacter(let specialCharacter):
                return "\\{\(specialCharacter.hexEncodedString())}"
            }
        }.joined()
    }
    var descriptionExcludingSpecialCharacters: String {
        return components.compactMap { (component) -> String? in
            if case let .string(string) = component {
                return string.replacingOccurrences(of: "|", with: "")
            }
            
            return nil
        }.joined()
    }
    init?(_ description: String) {
        self.init(with: description)
    }
    init(stringLiteral value: String) {
        self.init(with: value)
    }
}
