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
    let omitSpecialCharacters: Bool?
    
    var commands: [DataCommand] {
        let listingsDirectory = URL(fileURLWithPath: listingsDirectoryPath)
        
        var listings: Listings
        do {
            listings = try Listings(directory: listingsDirectory, startDay: Date(), forAtari: forAtari, omitSpecialCharacters: omitSpecialCharacters ?? false)
        } catch {
            print("Error loading listings from CSVListings: \(error)")
            return []
        }
        
        return listings.commands
    }
}

extension Listings {
    var commands: [DataCommand] {
        let channelCommand = ChannelsCommand(day: julianDay, channels: Array(channels))
        let programCommands = days.prefix(2).flatMap { (day) -> [ProgramCommand] in
            day.programs.map { ProgramCommand(day: day.julianDay, program: $0) }
        }
        
        return [channelCommand] + programCommands
    }
}
