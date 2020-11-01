//
//  Bit.swift
//  PrevueCLI
//
//  Created by Ari on 9/26/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

enum Bit: UInt8, CustomStringConvertible {
    case zero, one

    var description: String {
        switch self {
        case .one:
            return "1"
        case .zero:
            return "0"
        }
    }
}

extension FixedWidthInteger {
    var asBits: [Bit] {
        var value = self
        var bits = [Bit](repeating: .zero, count: bitWidth)
        
        for i in 0..<bitWidth {
            let currentBit = value & 0x01
            if currentBit != 0 {
                bits[bitWidth - (i + 1)] = .one
            }

            value >>= 1
        }

        return bits
    }
}

extension Array where Element: FixedWidthInteger {
    var asBits: [Bit] {
        var bits: [Bit] = []
        for byte in self {
            bits += byte.asBits
        }
        return bits
    }
}

extension Array where Element == Bit {
    var asBytes: Bytes {
        assert(count % 8 == 0, "Bit array size must be multiple of 8")

        let byteCount = (1 + (count - 1) / 8)
        var bytes = [UInt8](repeating: 0, count: byteCount)

        for (index, bit) in enumerated() {
            if bit == .one {
                bytes[index / 8] += UInt8(1 << (7 - index % 8))
            }
        }
        return bytes
    }

}
