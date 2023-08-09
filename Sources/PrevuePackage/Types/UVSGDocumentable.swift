//
//  UVSGDocumentable.swift
//  PrevueCLI
//
//  Created by Ari on 5/16/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

public protocol UVSGDocumentable {
    var documentedType: UVSGDocumentedType { get }
}

public protocol UVSGDocumentableEnum: UVSGDocumentable {
    static var allCaseNames: [String] { get }
}

public protocol UVSGDocumentableOptionSet: UVSGDocumentable {
    static var allOptionNames: [String] { get }
}

public indirect enum UVSGDocumentedType: CustomStringConvertible {
    case none
    case scalar(String)
    case optional(UVSGDocumentedType)
    case `enum`(UVSGDocumentableEnum)
    case optionSet(UVSGDocumentableOptionSet)
    case array(UVSGDocumentedType)
    case dictionary([(String, UVSGDocumentedType)])
    
    public var description: String {
        return description(at: 0)
    }
    
    func description(at level: Int, optional: Bool = false, array: Bool = false, needsNewline: Bool = false) -> String {
        // The following implementation is a total spitball and could probably be improved significantly
        var strings: [String] = []
        var needNewline = needsNewline
        var isArray = array
        switch self {
        case .none:
            return ""
        case .optional(let documentedType):
            return documentedType.description(at: level, optional: true)
        case .scalar(let typeName):
            strings = [typeName]
        case .array(let documentedType):
            if case .scalar = documentedType {
                return "(array) \(documentedType.description(at: 0))"
            } else {
                return documentedType.description(at: level, array: true)
            }
        case .enum(let documentableEnum):
            strings = [type(of: documentableEnum).allCaseNames.joined(separator: ", ")]
        case .optionSet(let documentableOptionSet):
            isArray = true
            strings = [type(of: documentableOptionSet).allOptionNames.joined(separator: ", ")]
        case .dictionary(let types):
            needNewline = true
            strings = types.compactMap { (arg0) -> String? in
                let (serializationKey, documentedType) = arg0
                let newLevel = level + 1
                switch documentedType {
                case .none:
                    return nil
                case .scalar(_):
                    return "\(serializationKey): \(documentedType.description(at: 0))"
                case .array(_):
                    return "\(serializationKey): \(documentedType.description(at: newLevel))"
                case .optional(let documentedType):
                    if case .scalar = documentedType {
                        return "\(serializationKey): (optional) \(documentedType.description(at: 0))"
                    } else {
                        return "\(serializationKey): \(documentedType.description(at: newLevel, optional: true, needsNewline: true))"
                    }
                case .dictionary(let types):
                    if types.count == 0 {
                        return "\(serializationKey): (no arguments)"
                    } else {
                        return "\(serializationKey): \(documentedType.description(at: newLevel, needsNewline: true))"
                    }
                case .enum(_):
                    return "\(serializationKey): \(documentedType.description(at: newLevel, needsNewline: true))"
                case .optionSet(_):
                    // Present an option set as an arry
                    return "\(serializationKey): \(documentedType.description(at: newLevel, array: true, needsNewline: true))"
                }
            }
        }
        
        let spacedContent = strings.map {
            let spacing = String(repeating: "    ", count: level)
            return "\(spacing)\($0)"
        }.joined(separator: "\n")
        let optionalText = (optional ? "(optional)" : (isArray ? "(array)" : ""))
        let newlineText = needNewline ? "\n" : ""
        return "\(optionalText)\(newlineText)\(spacedContent)"
    }
}

public extension UVSGDocumentable {
    var documentedType: UVSGDocumentedType {
        get {
            let mirror = Mirror(reflecting: self)
            
            var types: [(String, UVSGDocumentedType)] = []
            for (label, value) in mirror.children {
                guard let label = label else { continue }
                
                let introspectableValue = (value as? UVSGDocumentable)
                let typeOfValue = type(of: value)
                if typeOfValue is DataCommandMode.Type { continue }
                
                types.append((label, introspectableValue?.documentedType ?? UVSGDocumentedType.scalar("\(typeOfValue)")))
            }
            return .dictionary(types)
        }
    }
}

extension UVSGDocumentableEnum {
    var documentedType: UVSGDocumentedType {
        return .enum(self)
    }
}

extension UVSGDocumentableOptionSet {
    var documentedType: UVSGDocumentedType {
        return .optionSet(self)
    }
}

extension Array: UVSGDocumentable where Element: UVSGDocumentable {
    public var documentedType: UVSGDocumentedType {
        guard let first = first else { return .none }
        return .array(first.documentedType)
    }
}

extension Optional: UVSGDocumentable where Wrapped: UVSGDocumentable {
    public var documentedType: UVSGDocumentedType {
        get {
            switch self {
            case .none:
                return .none
            case .some(let introspectable):
                return .optional(introspectable.documentedType)
            }
        }
    }
}

public protocol UVSGDocumentableScalar: UVSGDocumentable {
}

extension UVSGDocumentableScalar {
    public var documentedType: UVSGDocumentedType {
        return .scalar("\(type(of: self))")
    }
}

extension String: UVSGDocumentableScalar {}
extension Byte: UVSGDocumentableScalar {}
extension Int: UVSGDocumentableScalar {}
