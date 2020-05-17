//
//  PrevueCommandFile.swift
//  PrevuePackage
//
//  Created by Ari on 4/25/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

struct PrevueCommandFile: Codable {
    let destinations: [DataDestination]
    let commandContainers: [CommandContainer]
}

// MARK: Encoding/decoding

extension PrevueCommandFile {
    struct SerializedCommand: Decodable, PropertiesGettableByType {
        let BoxOnCommand: BoxOnCommand?
        let BoxOffCommand: BoxOffCommand?
        let ResetCommand: ResetCommand?
        let TitleCommand: TitleCommand?
        let ClockCommand: ClockCommand?
        let CurrentClockCommand: FileCurrentClockCommand?
        let DownloadCommand: DownloadCommand?
        let LocalAdResetCommand: LocalAdResetCommand?
        let LocalAdCommand: LocalAdCommand?
        let ColorLocalAdCommand: ColorLocalAdCommand?
        let ConfigurationCommand: ConfigurationCommand?
        let ConfigDatCommand: ConfigDatCommand?
        let ChannelsCommand: ChannelsCommand?
        let ProgramCommand: ProgramCommand?
        let ListingsCommand: FileListingsCommand?
    }
    
    class SerializedDestination: Codable, PropertiesGettableByType {
        let TCPDataDestination: TCPDataDestination?
        let SerialPortDataDestination: SerialPortDataDestination?
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode commands
        let serializedCommands = try container.decode([SerializedCommand].self, forKey: .commands)
        commandContainers = serializedCommands.compactMap {
            return $0.propertyValue(of: CommandContainer.self)
        }
        
        // Decode destinations
        let serializedDestinations = try container.decode([SerializedDestination].self, forKey: .destinations)
        destinations = serializedDestinations.compactMap {
            return $0.propertyValue(of: DataDestination.self)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode commands
        var serializedCommands = container.nestedUnkeyedContainer(forKey: .commands)
        for commandContainer in commandContainers {
            for command in commandContainer.commands {
                var serializedContainer = serializedCommands.nestedContainer(keyedBy: DynamicKey.self)
                let serializedCommandKey = DynamicKey(stringValue: "\(type(of: commandContainer))")
                try command.encode(to: serializedContainer.superEncoder(forKey: serializedCommandKey))
            }
        }
        
        // Encode destinations
        var serializedDestinations = container.nestedUnkeyedContainer(forKey: .destinations)
        for destination in destinations {
            var serializedContainer = serializedDestinations.nestedContainer(keyedBy: DynamicKey.self)
            let serializedDestinationKey = DynamicKey(stringValue: "\(type(of: destination))")
            try destination.encode(to: serializedContainer.superEncoder(forKey: serializedDestinationKey))
        }
    }

    enum CodingKeys: CodingKey {
        case destinations
        case commands
    }
}

// MARK: Sending

extension PrevueCommandFile {
    func sendAllCommands() {
        for destination in destinations {
            destination.openConnection()
        }

        for commandContainer in commandContainers {
            for command in commandContainer.commands {
                for destination in destinations {
                    destination.send(data: command)
                }
            }
        }

        for destination in destinations {
            destination.closeConnection()
        }
    }
}

// MARK: Utilities

protocol PropertiesGettableByType {
}

extension PropertiesGettableByType {
    func propertyValue<T>(of type: T.Type) -> T? {
        return propertyValues(of: type).first
    }
    func propertyValues<T>(of type: T.Type) -> [T] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.compactMap {
            if case Optional<Any>.some(let unwrappedValue) = $0.value,
                let typedValue = unwrappedValue as? T {
                return typedValue
            }
            
            return nil
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
