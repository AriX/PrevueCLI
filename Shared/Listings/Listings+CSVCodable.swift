//
//  CSVListings.swift
//  PrevuePackage
//
//  Created by Ari on 4/17/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation

extension Listings {
    init(channelsCSVFile: URL, programsCSVFile: URL, day: JulianDay, forAtari: Bool = false) throws {
        var channels = try Channel.load(from: channelsCSVFile)
        var programs = try Program.load(from: programsCSVFile)
        
        if (forAtari) {
            channels = channels.makeAtariCompatible()
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
}

protocol CSVCodable: Decodable {
    static func load(from csvFileURL: URL) throws -> [Self]
    static func write(_ items: [Self], to csvFileURL: URL) throws
}

extension CSVCodable {
    static func load(from csvFileURL: URL) throws -> [Self] {
        let csvContents = try String(contentsOf: csvFileURL, encoding: .utf8)
        let reader = try CSVReader(string: csvContents, hasHeaderRow: true)
        let decoder = CSVRowDecoder()
        decoder.userInfo[.csvCoding] = true
        
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
                var value = String(describing: child.value)
                if let customValue = child.value as? CSVCustomFieldValue {
                    value = customValue.csvValue
                }
                try writer.write(field: value)
            }
        }
    }
}

protocol CSVCustomFieldValue {
    var csvValue: String { get } 
}

extension Listings.Channel: CSVCodable {
}
extension Listings.Program: CSVCodable {
}

extension CodingUserInfoKey {
    // Boolean indicating whether or not CSV encoding/decoding is being used
    static let csvCoding: CodingUserInfoKey = CodingUserInfoKey(rawValue: "csvCoding")!
}
