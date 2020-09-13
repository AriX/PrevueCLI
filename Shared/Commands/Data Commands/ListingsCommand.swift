//
//  ListingsCommand.swift
//  PrevuePackage
//
//  Created by Ari on 9/10/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

struct ListingsCommand: MetaCommand {
    let channelsFilePath: String
    let programsFilePath: String
    let forAtari: Bool
    
    var commands: [DataCommand] {
        let channelsFile = URL(fileURLWithPath: channelsFilePath)
        let programsFile = URL(fileURLWithPath: programsFilePath)
        let date = Date()
        
        let julianDay = JulianDay(dayOfYear: JulianDay(with: date).dayOfYear)
        
        var listings: Listings
        do {
            listings = try Listings(channelsCSVFile: channelsFile, programsCSVFile: programsFile, day: julianDay, forAtari: forAtari)
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
        let programCommands: [ProgramCommand] = programs.map { (program) in
            ProgramCommand(day: julianDay, program: program)
        }
        
        return [channelCommand] + programCommands
    }
}
