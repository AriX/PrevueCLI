/// Implementations of BinaryCodable for built-in types.

import Foundation

extension Array: BinaryEncodable where Element: BinaryEncodable {
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        for element in self {
            try element.binaryEncode(to: encoder)
        }
    }
}

extension Array: BinaryDecodable, CodingPathIntrospectable where Element: BinaryDecodable {
    public init(fromBinary decoder: BinaryDecoder) throws {
        self.init()
        do {
            while !decoder.isAtEnd() {
                let decoded = try Element.init(fromBinary: decoder)
                append(decoded)
            }
        } catch BinaryDecoder.Error.expectedEndOfData {
            // Do nothing, we hit end of data expectedly
        }
    }
}

// Read/write strings as null-terminated UTF-8
extension String: BinaryCodable {
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        for element in utf8 {
            try element.encode(to: encoder)
        }
        
        // Encode null terminator
        try Byte(0x00).encode(to: encoder)
    }
    
    public init(fromBinary decoder: BinaryDecoder) throws {
        var nextByte: Byte?
        var bytes: [Byte] = []
        while nextByte == nil || nextByte != 0x00 {
            if let nextByte = nextByte {
                bytes.append(nextByte)
            }
            nextByte = try decoder.decode(Byte.self)
        }
        
        if let string = String(bytes: bytes, encoding: .utf8) {
            self = string
        } else {
            throw BinaryDecoder.Error.invalidUTF8(bytes)
        }
    }
}

extension Optional: BinaryEncodable where Wrapped: BinaryEncodable {
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        switch self {
        case .some(let encodable):
            try encodable.binaryEncode(to: encoder)
        case .none:
            break
        }
    }
}

extension FixedWidthInteger where Self: BinaryEncodable {
    public func binaryEncode(to encoder: BinaryEncoder) {
        encoder.appendBytes(of: self.bigEndian)
    }
}

extension FixedWidthInteger where Self: BinaryDecodable {
    public init(fromBinary binaryDecoder: BinaryDecoder) throws {
        var v = Self.init()
        try binaryDecoder.read(into: &v)
        self.init(bigEndian: v)
    }
}

// for size in [8, 16, 32, 64] {
//     for prefix in ["", "U"] {
//         print("extension \(prefix)Int\(size): BinaryCodable {}")
//     }
// }
// Copy the above snippet, then run: `pbpaste | swift`
extension Int8: BinaryCodable {}
extension UInt8: BinaryCodable {}
extension Int16: BinaryCodable {}
extension UInt16: BinaryCodable {}
extension Int32: BinaryCodable {}
extension UInt32: BinaryCodable {}
extension Int64: BinaryCodable {}
extension UInt64: BinaryCodable {}

