//
//  ByteConvenience.swift
//  PrevuePackage
//
//  Created by Ari on 4/5/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation

// MARK: Byte conversion

extension Character {
    var asByte: Byte {
        let unicodeScalars = self.unicodeScalars
        assert(unicodeScalars.count == 1, "Character must be a single unicode scalar")
        
        let firstValue: UInt32 = unicodeScalars.first!.value
        assert(firstValue <= 255, "Character must be a single byte")
        
        return Byte(firstValue)
    }
}

// MARK: Type conversion

extension String {
    var asBytes: Bytes {
        Array(utf8)
    }
}

// MARK: Convenience conversions

extension Array where Element == Byte {
    func splitIntoChunks(chunkSize: Int) -> [Bytes] {
        return stride(from: 0, to: self.count, by: chunkSize).map { chunkStartIndex in
            let endIndex = (self.index(chunkStartIndex, offsetBy: chunkSize, limitedBy: self.count) ?? self.count)
            return Bytes(self[chunkStartIndex ..< endIndex])
        }
    }
}

extension Bytes {
    static func leftRightStringAsBytes(leftString: String, rightString: String) -> Bytes {
        return (leftString.asBytes + [Byte(0x12)] + rightString.asBytes + [Byte(0x0D)])
    }
}

// MARK: Checksumming

extension Sequence where Element == Byte {
    func checksum() -> Byte {
        var checksum = UInt8(0)
        for byte in self {
            checksum ^= byte
        }
        
        return checksum
    }
}

// MARK: Debugging

extension Byte {
    func hexEncodedString() -> String {
        return String(format: "%02hhX", self)
    }
}

extension Collection where Element == Byte {
    func hexEncodedString() -> String {
        return map { $0.hexEncodedString() }.joined(separator: " ")
    }
}

extension String {
    var hexStringAsBytes: Bytes {
        let stripped = filter { !$0.isWhitespace }
        var start = stripped.startIndex
        return stride(from: 0, to: stripped.count, by: 2).compactMap { _ in
            let end = stripped.index(after: start)
            defer { start = stripped.index(after: end) }
            return Byte(stripped[start...end], radix: 16)
        }
    }
}
