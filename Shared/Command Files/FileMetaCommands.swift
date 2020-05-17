//
//  FileMetaCommands.swift
//  PrevueCLI
//
//  Created by Ari on 5/2/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

// MARK: Commands

struct FileCurrentClockCommand: FileMetaCommand {
    var commands: [DataCommand] {
        let command = ClockCommand(with: Date())!
        return [command]
    }
}

struct FileListingsCommand: FileMetaCommand {
    let channelsFilePath: String
    let programsFilePath: String
    let forAtari: Bool
    
    var commands: [DataCommand] {
        let channelsFile = URL(fileURLWithPath: channelsFilePath)
        let programsFile = URL(fileURLWithPath: programsFilePath)
        let date = Date()
        let julianDay = JulianDay(dayOfYear: JulianDay(with: date).dayOfYear/* - 1*/)
        
        guard let listingSource = SampleDataListingSource(channelsCSVFile: channelsFile, programsCSVFile: programsFile, day: julianDay, forAtari: forAtari) else {
            print("Error loading listings from SampleDataListingSource")
            return []
        }
        
        let channelCommand = ChannelsCommand(day: julianDay, channels: listingSource.channels)
        let programCommands: [ProgramCommand] = listingSource.programs.map { (program) in
            ProgramCommand(program: program)
        }
        
        return [channelCommand] + programCommands
    }
}

// MARK: Support

protocol FileMetaCommand: CommandContainer, UVSGDocumentable, Codable, CustomStringConvertible {
}

extension FileMetaCommand {
    var description: String {
        return "\(type(of: self)): \(commands)"
    }
}
