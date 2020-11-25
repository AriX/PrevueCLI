//
//  CSVListings.swift
//  PrevuePackage
//
//  Created by Ari on 4/17/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation

extension Listings {
    init(channelsCSVFile: URL, programsCSVFile: URL, day: JulianDay, forAtari: Bool = false, omitSpecialCharacters: Bool = false) throws {
        var channels = try Channel.load(from: channelsCSVFile)
        var programs = try Program.load(from: programsCSVFile)
        
        if forAtari {
            channels = channels.makeAtariCompatible()
        }
        
        if forAtari || omitSpecialCharacters {
            programs = programs.makeAtariCompatible()
        }
        
        self.julianDay = day
        self.channels = channels
        self.programs = programs
    }
    
    func write(channelsCSVFile: URL, programsCSVFile: URL) throws {
        try Channel.write(channels, to: channelsCSVFile)
        try Program.write(programs, to: programsCSVFile)
    }
    
    func write(to directory: URL) throws {
        let channelsFileURL = directory.appendingPathComponent("channels.csv", isDirectory: false)
        let programsFileURL = directory.appendingPathComponent("programs.csv", isDirectory: false)
        try write(channelsCSVFile: channelsFileURL, programsCSVFile: programsFileURL)
    }
}

protocol CSVCodable: Decodable {
    static func load(from csvFileURL: URL) throws -> [Self]
    static func write(_ items: [Self], to csvFileURL: URL) throws
    
    static var nonNilKeys: [String] { get }
}

extension CSVCodable {
    static func load(from csvFileURL: URL) throws -> [Self] {
        let csvContents = try String(contentsOf: csvFileURL, encoding: .utf8)
        let reader = try CSVReader(string: csvContents, hasHeaderRow: true)
        let decoder = CSVRowDecoder()
        decoder.userInfo[.csvCoding] = true
        decoder.nilDecodingStrategy = .custom({ (value, key) -> Bool in
            if let key = key, nonNilKeys.contains(key) {
                return false
            }
            
            return value.isEmpty
        })
        
        var items: [Self] = []
        while reader.next() != nil {
            let row = try decoder.decode(Self.self, from: reader)
            items.append(row)
        }
        
        return items
    }
    
    static func write(_ items: [Self], to csvFileURL: URL) throws {
        guard let firstItem = items.first else {
            // Need at least one item to write
            throw CSVError.cannotWriteStream
        }
        
        guard let outputStream = OutputStream(url: csvFileURL, append: false) else {
            throw CSVError.cannotWriteStream
        }
        let writer = try CSVWriter(stream: outputStream)
        
        let mirror = Mirror(reflecting: firstItem)
        for child in mirror.children {
            guard let label = child.label else { continue }
            try writer.write(field: label)
        }
        
        for item in items {
            writer.beginNewRow()
            
            let mirror = Mirror(reflecting: item)
            for child in mirror.children {
                
                var value: Any
                if case Optional<Any>.some(let unwrappedValue) = child.value {
                    value = unwrappedValue
                } else if case Optional<Any>.none = child.value {
                    value = ""
                } else {
                    value = child.value
                }
                
                var stringValue = String(describing: value)
                if let customValue = value as? CSVCustomFieldValue {
                    stringValue = customValue.csvValue
                }
                try writer.write(field: stringValue)
            }
        }
    }
    
    static var nonNilKeys: [String] {
        return []
    }
}

protocol CSVCustomFieldValue {
    var csvValue: String { get } 
}

extension Listings.Channel: CSVCodable {
    static var nonNilKeys: [String] {
        // Don't let callLetters be decoded as nil. Decode as empty string instead. Otherwise, the source identifier is used as call letters (which breaks psuedo-channels, like the slogan at the end of the listings).
        return ["callLetters"]
    }
}

extension Listings.Program: CSVCodable {
}

extension CodingUserInfoKey {
    // Boolean indicating whether or not CSV encoding/decoding is being used
    static let csvCoding: CodingUserInfoKey = CodingUserInfoKey(rawValue: "csvCoding")!
}
