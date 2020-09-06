//
//  BytesType.swift
//  PrevueCLI
//
//  Created by Ari on 8/27/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

// MARK: Types

public typealias Byte = UInt8
public typealias Bytes = [Byte]

// MARK: Abstract type

public protocol BytesType {
    var bytes: Bytes { get }
}

extension Byte: BytesType {
    public var bytes: Bytes {
        return [self]
    }
}

extension Array: BytesType where Element == Byte {
    public var bytes: Bytes {
        return self
    }
}
