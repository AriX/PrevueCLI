//
//  UVSGEncoding.swift
//  PrevueFramework
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

protocol UVSGChecksummable {
    var checksum: Byte { get }
}

extension Array: UVSGChecksummable where Element == Byte {
    var checksum: Byte {
        var checksum = UInt8(0)
        for byte in self {
            checksum ^= byte
        }
        
        return checksum
    }
}

protocol UVSGEncodable {
    func encode() -> [Byte]
    func encodeWithChecksum() -> [Byte]
}

extension UVSGEncodable {
    func encodeWithChecksum() -> [Byte] {
        let encoded = encode()
        return (encoded + [encoded.checksum])
    }
}
