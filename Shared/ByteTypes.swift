//
//  ByteTypes.swift
//  PrevuePackage
//
//  Created by Ari on 4/5/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation

// MARK: Types

typealias Byte = UInt8
typealias Bytes = [Byte]

// MARK: Type conversion

// TODO: Make a consistent protocol for this

extension Character {
    func asByte() -> Byte {
        let unicodeScalars = self.unicodeScalars
        assert(unicodeScalars.count == 1, "Character must be a single unicode scalar")
        
        let firstValue: UInt32 = unicodeScalars.first!.value
        assert(firstValue <= 255, "Character must be a single byte")
        
        return Byte(firstValue)
    }
}

extension DataCommandMode {
    func asByte() -> Byte {
        return self.rawValue.asByte()
    }
}

extension String {
    func uvsgBytes() -> Bytes {
        return (Array(self.utf8) + [0x00])
    }
    func asBytes() -> Bytes {
        return Array(self.utf8)
    }
}

extension Bool {
    func asByte() -> Byte {
        return (self ? Byte(1) : Byte(0))
    }
}

// MARK: Convenience conversions

extension UInt16 {
    func bytesBySeparatingIntoHighAndLowBits() -> Bytes {
        return [UInt8(self >> 8), UInt8(self & 0xFF)]
    }
    
    func bytesBySeparatingIntoASCIIDigits() -> Bytes {
        let string = String(format: "%02d", self)
        return Array(string.utf8)
    }
}

extension UInt8 {
    func byteByRepresentingNumberAsASCIILetter() -> Byte {
        let A = Byte(0x41) // refactor with char?
        return (A + self)
    }
    
    func byteByRepresentingNumberAsASCIIDigit() -> Byte {
        let zero = Byte(0x30)
        return (zero + self)
    }
}

extension Bool {
    func byteByRepresentingAsASCIILetter() -> Byte {
        return (self ? Byte(0x59) : Byte(0x4E))
    }
}

extension Array where Element == Byte {
    func splitIntoChunks(chunkSize: Int) -> [Bytes] {
        return stride(from: 0, to: self.count, by: chunkSize).map { chunkStartIndex in
            let endIndex = (self.index(chunkStartIndex, offsetBy: chunkSize, limitedBy: self.count) ?? self.count)
            return Bytes(self[chunkStartIndex ..< endIndex])
        }
    }
}

// MARK: Debugging

extension Array where Element == Byte {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhX ", $0) }.joined()
    }
}
