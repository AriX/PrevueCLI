//
//  PrevueCommandFile.swift
//  PrevuePackage
//
//  Created by Ari on 4/25/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation
#if os(Windows) || os(Linux)
import Yams
#endif

struct PrevueCommandFile: Codable {
    let destinations: [DataDestination]
    let commands: [Command]
}

// MARK: Encoding/decoding

extension PrevueCommandFile {
    struct SerializedDestination: Codable, PropertiesGettableByType {
        let TCPDataDestination: TCPDataDestination?
        #if !os(Linux)
        let SerialPortDataDestination: SerialPortDataDestination?
        #endif
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode commands
        let serializedCommands = try container.decode([SerializedCommand].self, forKey: .commands)
        commands = serializedCommands.compactMap { $0.command }
        
        // Decode destinations
        let serializedDestinations = try container.decode([SerializedDestination].self, forKey: .destinations)
        destinations = serializedDestinations.compactMap {
            return $0.propertyValue(of: DataDestination.self)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode commands
        let serializedCommands = commands.map { SerializedCommand(command: $0) }
        try container.encode(serializedCommands, forKey: .commands)
        
        // Encode destinations
        var destinationsContainer = container.nestedUnkeyedContainer(forKey: .destinations)
        for destination in destinations {
            var serializedContainer = destinationsContainer.nestedContainer(keyedBy: DynamicKey.self)
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
            try! destination.openConnection()
        }
        
        for command in commands {
            destinations.send(data: command.satelliteCommands)
        }
        
        for destination in destinations {
            destination.closeConnection()
        }
    }
}

// MARK: Reading/writing as files

extension PrevueCommandFile {
    init(contentsOfFile filePath: String) throws {
        let commandFileText = try String(contentsOfFile: filePath)
        
        // Change the current working directory to the directory containing the .prevuecommand file (in order to resolve relative paths referenced in the file)
        let fileURL = URL(fileURLWithPath: filePath)
        let containingDirectory = fileURL.deletingLastPathComponent()
        FileManager.default.changeCurrentDirectoryPath(containingDirectory.path)

        let decoder = YAMLDecoder()
        self = try decoder.decode(PrevueCommandFile.self, from: commandFileText)
    }
    
    func write(toFile: String) throws {
        let encoder = YAMLEncoder()
        let commandFileText = try encoder.encode(self)
        if toFile == "-" {
            print("\(commandFileText)")
        } else {
            try commandFileText.write(toFile: toFile, atomically: true, encoding: .utf8)
            print("Writing:\n\(commandFileText)")
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
