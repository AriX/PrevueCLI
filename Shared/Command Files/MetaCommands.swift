//
//  MetaCommands.swift
//  PrevueCLI
//
//  Created by Ari on 5/2/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

// MARK: Metacommands

struct CurrentClockCommand: MetaCommand {
    var commands: [DataCommand] {
        let command = ClockCommand.currentTulsaTime!
        return [command]
    }
}

struct ListingsCommand: MetaCommand {
    let channelsFilePath: String
    let programsFilePath: String
    let forAtari: Bool
    
    var commands: [DataCommand] {
        let channelsFile = URL(fileURLWithPath: channelsFilePath)
        let programsFile = URL(fileURLWithPath: programsFilePath)
        let date = Date()
        
        let julianDay = JulianDay(dayOfYear: JulianDay(with: date).dayOfYear)
        
        var listingSource: CSVListingsSource
        do {
            listingSource = try CSVListingsSource(channelsCSVFile: channelsFile, programsCSVFile: programsFile, day: julianDay, forAtari: forAtari)
        } catch {
            print("Error loading listings from CSVListingsSource: \(error)")
            return []
        }
        
        let channelCommand = ChannelsCommand(day: julianDay, channels: listingSource.channels)
        let programCommands: [ProgramCommand] = listingSource.programs.map { (program) in
            ProgramCommand(day: julianDay, program: program)
        }
        
        return [channelCommand] + programCommands
    }
}

struct TransferFileCommand: MetaCommand {
    let localFilePath: String
    let remoteFilePath: String
    
    var commands: [DataCommand] {
        let fileData = try! Data(contentsOf: URL(fileURLWithPath: localFilePath))
        let fileBytes = [UInt8](fileData)
        return DownloadCommand.commandsToTransferFile(filePath: remoteFilePath, contents: fileBytes)
    }
}

// MARK: Convenience

extension MetaCommand {
    var description: String {
        return "\(type(of: self)): \(commands)"
    }
}
