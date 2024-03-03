//
//  ListingsCommand.swift
//  PrevuePackage
//
//  Created by Ari on 9/10/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

struct ListingsCommand: MetaCommand {
    let listingsDirectoryPath: String
    let forAtari: Bool
    
    var commands: [DataCommand] {
        let listingsDirectory = URL(fileURLWithPath: listingsDirectoryPath)
        
        var listings: Listings
        do {
            listings = try Listings(directory: listingsDirectory, startDay: Date(), forAtari: forAtari)
        } catch {
            print("Error loading listings from CSVListings: \(error)")
            return []
        }
        
        return listings.commands
    }
}

extension Listings {
    var channelsCommand: ChannelsCommand {
        ChannelsCommand(day: julianDay, channels: Array(channels))
    }
    
    func programCommands(forDays: Int) -> [ProgramCommand] {
        days.prefix(forDays).flatMap { (day) -> [ProgramCommand] in
            day.programs.map { ProgramCommand(day: day.julianDay, program: $0) }
        }
    }
    
    var programCommandsForCurrentDay: [ProgramCommand] {
        programCommands(forDays: 1)
    }
    
    var programCommandsForCurrentAndNextDay: [ProgramCommand] {
        programCommands(forDays: 2)
    }
    
    var commands: [DataCommand] {
        return [channelsCommand] + programCommandsForCurrentAndNextDay
    }
}
