//
//  SampleDataListingsSource.swift
//  PrevueApp
//
//  Created by Ari on 4/17/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation

class SampleDataListingSource: ListingsSource {
    let channels: [Channel]
    let programs: [Program]
    
    init?(channelsCSVFile: URL, programsCSVFile: URL, day: JulianDay, forAtari: Bool = false) {
        do {
            let sampleChannels = try SampleDataChannel.load(from: channelsCSVFile, forAtari: forAtari)
            self.channels = sampleChannels.map({ (sampleChannel) -> Channel in
                sampleChannel.channel
            })
            let samplePrograms = try SampleDataProgram.load(from: programsCSVFile, forAtari: forAtari)
            self.programs = samplePrograms.map({ (sampleProgram) -> Program in
                sampleProgram.program(with: day)
            })
        } catch {
            // TODO: Log error
            return nil
        }
    }
}

protocol CSVLoadable {
    static func load(from csvFileURL: URL, forAtari: Bool) throws -> [Self]
}

struct SampleDataChannel: CSVLoadable {
    let number: String
    let channelName: String
    let internalName: String
    let grabber: String
    let persistantGrabber: String
    let persistantNumber: String
    let flag: String
    
    static func load(from csvFileURL: URL, forAtari: Bool) throws -> [SampleDataChannel] {
        let rows: [[String]] = try loadRows(from: csvFileURL)
        var sampleChannels = rows.compactMap({ (row) -> SampleDataChannel? in
            if row.count < 7 {
                return nil
            }
            
            let number = row[0]
            let channelName = row[1]
            let internalName = row[2]
            let grabber = row[3]
            let persistantGrabber = row[4]
            let persistantNumber = row[5]
            let flag = row[6]
            if number.count == 0 || channelName.count == 0 || internalName.count == 0 {
                return nil
            }
            
            return SampleDataChannel(number: number, channelName: channelName, internalName: internalName, grabber: grabber, persistantGrabber: persistantGrabber, persistantNumber: persistantNumber, flag: flag)
        }).sorted(by: { (one, two) -> Bool in
            return Double(one.number)! < Double(two.number)!
        })
        
        if forAtari {
            // Atari can't handle channel names longer than 5 characters, and seems to choke when channel numbers contain '.', so let's skip those channels
            sampleChannels.removeAll {
                $0.number.contains(".") || $0.internalName.count > 5 || $0.channelName.count > 5
            }
            
            // Limit Atari channel lineup to the first 48 channels
            sampleChannels = Array(sampleChannels[..<48])
        }
        
        return sampleChannels
    }
    
    var channel: Channel {
        // TODO: Convert flags
        return Channel(flags: .none, sourceIdentifier: internalName, channelNumber: number, callLetters: channelName)
    }
}

struct SampleDataProgram: CSVLoadable {
    let tsdaychannel: String
    let title: String
    let day: String
    
    static func load(from csvFileURL: URL, forAtari: Bool) throws -> [SampleDataProgram] {
        let rows: [[String]] = try loadRows(from: csvFileURL)
        var samplePrograms = rows.compactMap({ (row) -> SampleDataProgram? in
            if row.count < 3 {
                return nil
            }
            
            if row.count > 3 {
                // TODO: Need to handle escaped commas
                return nil
            }
            
            let tsdaychannel = row[0]
            let title = row[1]
            let day = row[2]
            if tsdaychannel.count == 0 || title.count == 0 || day.count == 0 {
                return nil
            }
            
            return SampleDataProgram(tsdaychannel: tsdaychannel, title: title, day: day)
        })

        if forAtari {
            // Atari can't handle channel names longer than 5 characters, so let's skip those programs
            samplePrograms.removeAll {
                let (_, channelIdentifier) = $0.parseTimeslotChannelString
                return channelIdentifier.count > 5
            }
        }
        
        return samplePrograms
    }
    
    var parseTimeslotChannelString: (timeslotString: String, channelIdentifier: String) {
        let timeslotChannel = tsdaychannel.components(separatedBy: day)
        let timeslotString = timeslotChannel.first!
        let channelIdentifier = timeslotChannel.last!
        return (timeslotString, channelIdentifier)
    }
    
    func program(with julianDay: JulianDay) -> Program {
        let (timeslotString, channelIdentifier) = parseTimeslotChannelString
        
        // Ignore the sample day and use the julianDay that was passed in, instead
        return Program(timeslot: UInt8(timeslotString)!, day: julianDay, sourceIdentifier: channelIdentifier, flags: .none, programName: title)
    }
}

extension CSVLoadable {
    static func loadRows(from csvFileURL: URL) throws -> [[String]] {
        let csvContents = try String(contentsOf: csvFileURL, encoding: .ascii)
        let csvLines = csvContents.components(separatedBy: "\n")
        let csvLinesWithoutTableHeaders = csvLines.dropFirst()
        return csvLinesWithoutTableHeaders.map({ (line) -> [String] in
            line.components(separatedBy: ",")
        })
    }
}
