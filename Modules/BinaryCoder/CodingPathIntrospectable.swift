//
//  CodingPathIntrospectable.swift
//  PrevueCLI
//
//  Created by Ari on 8/15/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

public protocol CodingPathIntrospectable {
}

public extension CodingPathIntrospectable {
    func value(at codingPath: [CodingKey]) -> CodingPathIntrospectable? {
        if codingPath.count == 0 {
            return self
        }
        
        // handle array/sets?
        let mirror = Mirror(reflecting: self)
        
        var newPath = codingPath
        let firstKey = newPath.removeFirst()
        
        guard let child = mirror.children.first(where: { $0.label == firstKey.stringValue }) else { return nil }
        
        var value = child.value
        if case Optional<Any>.some(let unwrappedValue) = value {
            value = unwrappedValue
        }
        
        guard let decodableValue = value as? CodingPathIntrospectable else { return nil }
        return decodableValue.value(at: newPath)
    }
}
