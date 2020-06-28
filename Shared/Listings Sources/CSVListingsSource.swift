//
//  CSVListingsSource.swift
//  PrevuePackage
//
//  Created by Ari on 4/17/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation

class CSVListingsSource: ListingsSource {
    let channels: [Channel]
    let programs: [Program]
    
    init(channelsCSVFile: URL, programsCSVFile: URL, day: JulianDay, forAtari: Bool = false) throws {
        var channels = try Channel.load(from: channelsCSVFile)
        var programs = try Program.load(from: programsCSVFile)
        
        if (forAtari) {
            channels = channels.filterAtariIncompatibleItems()
            programs = programs.filterAtariIncompatibleItems()
        }
        
        self.channels = channels
        self.programs = programs
    }
}

protocol CSVDecodable: Decodable {
    static func load(from csvFileURL: URL) throws -> [Self]
}

extension CSVDecodable {
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
}

extension CodingUserInfoKey {
    // Boolean indicating whether or not CSV encoding/decoding is being used
    static let csvCoding: CodingUserInfoKey = CodingUserInfoKey(rawValue: "csvCoding")!
}

protocol AtariListingsCompatible {
    func isValidForAtari(atIndex: Int) -> Bool
}

extension Channel: CSVDecodable, AtariListingsCompatible {
    func isValidForAtari(atIndex index: Int) -> Bool {
        // Atari can't handle channel names longer than 5 characters, and seems to choke when channel numbers contain '.', so let's skip those channels
        if channelNumber.contains(".") || sourceIdentifier.count > 5 || callLetters.count > 5 {
            return false
        }
        
        // Limit Atari channel lineup to the first 48 channels
        if index > 48 {
            return false
        }
        
        return true
    }
}

extension Program: CSVDecodable, AtariListingsCompatible {
    func isValidForAtari(atIndex index: Int) -> Bool {
        // Atari can't handle channel names longer than 5 characters, so let's skip those programs
        if sourceIdentifier.count > 5 {
            return false
        }
        
        return true
    }
}

extension Array where Element: AtariListingsCompatible {
    func filterAtariIncompatibleItems() -> Self {
        return enumerated().compactMap {
            $0.element.isValidForAtari(atIndex: $0.offset) ? $0.element : nil
        }
    }
}
