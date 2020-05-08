//
//  FileMetaCommands.swift
//  PrevueCLI
//
//  Created by Ari on 5/2/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

// MARK: Commands

class FileClockCommand: FileMetaCommand<ClockCommand, FileClockCommand.CustomKeys> {
    enum CustomKeys: CodingKey {
    }
    
    override class func customCommandsFrom(container: KeyedDecodingContainer<CustomKeys>) throws -> [DataCommand] {
        let command = ClockCommand(with: Date())!
        return [command]
    }
}

class FileListingsCommand: FileMetaCommand<ChannelsCommand, FileListingsCommand.CustomKeys> {
    enum CustomKeys: CodingKey {
        case channelsFile
        case programsFile
        case forAtari
    }
    
    override class func customCommandsFrom(container: KeyedDecodingContainer<CustomKeys>) throws -> [DataCommand] {
        let channelsFilePath = try container.decode(String.self, forKey: .channelsFile)
        let programsFilePath = try container.decode(String.self, forKey: .programsFile)
        let forAtari = try container.decode(Bool.self, forKey: .forAtari)

        let channelsFile = URL(fileURLWithPath: channelsFilePath)
        let programsFile = URL(fileURLWithPath: programsFilePath)
        let date = Date()
        let julianDay = JulianDay(dayOfYear: JulianDay(with: date).dayOfYear/* - 1*/)
        
        guard let listingSource = SampleDataListingSource(channelsCSVFile: channelsFile, programsCSVFile: programsFile, day: julianDay, forAtari: forAtari) else {
            throw DecodingError.dataCorruptedError(forKey: .channelsFile, in: container, debugDescription: "Failed to load listings from channelsFile or programsFile")
        }
        
        let channelCommand = ChannelsCommand(day: julianDay, channels: listingSource.channels)
        let programCommands: [ProgramCommand] = listingSource.programs.map { (program) in
            ProgramCommand(program: program)
        }
        
        return [channelCommand] + programCommands
    }
}

// MARK: Support

class FileMetaCommand<CommandType: DataCommand, CustomKeys: CodingKey>: CommandContainer, Decodable {
    let commands: [DataCommand]
    
    init(commands: [DataCommand]) {
        self.commands = commands
    }
    
    required convenience init(from decoder: Decoder) throws {
        let keys = try decoder.container(keyedBy: DynamicKey.self).allKeys
        
        // Check if the serialized command matches the specified custom keys
        let keysMatch = keys.allMatchType(CustomKeys.self)
        
        if keysMatch {
            // If so, deserialize using customCommandsFrom(container:)
            let container = try decoder.container(keyedBy: CustomKeys.self)
            let commands = try Self.customCommandsFrom(container: container)
            self.init(commands: commands)
        } else {
            // Otherwise, deserialize a regular command
            let command = try decoder.singleValueContainer().decode(CommandType.self)
            self.init(commands: [command])
        }
    }
    
    class func customCommandsFrom(container: KeyedDecodingContainer<CustomKeys>) throws -> [DataCommand] {
        fatalError("Subclasses must override")
    }
}

extension FileMetaCommand: CustomStringConvertible {
    var description: String {
        return "\(type(of: self)): \(commands)"
    }
}

extension Array where Element: CodingKey {
    func allMatchType(_ keyType: CodingKey.Type) -> Bool {
        return allSatisfy {
            keyType.init(stringValue: $0.stringValue) != nil
        }
    }
}

struct DynamicKey: CodingKey {
    var stringValue: String
    init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    var intValue: Int? = nil
    init?(intValue: Int) {
        return nil
    }
}
