//
//  Command.swift
//  PrevuePackage
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

public protocol Command: Codable, UVSGDocumentable {
}

protocol SatelliteCommand: Command, BinaryCodable {
}

protocol DataCommand: SatelliteCommand {
    static var commandMode: DataCommandMode { get }
}

protocol ControlCommand: SatelliteCommand {
    var commandMode: ControlCommandMode { get }
}

protocol MetaCommand: Command, CustomStringConvertible {
    var commands: [DataCommand] { get }
}

// MARK: Convenience

extension Command {
    var satelliteCommands: [SatelliteCommand] {
        if let satelliteCommand = self as? SatelliteCommand {
            return [satelliteCommand]
        } else if let metaCommand = self as? MetaCommand {
            return metaCommand.commands
        }

        return []
    }
}

extension SatelliteCommand {
    var commandModeByte: Byte {
        if let dataCommand = self as? DataCommand {
            return type(of: dataCommand).commandMode.rawValue.asciiValue
        } else {
            let controlCommand = self as! ControlCommand
            return controlCommand.commandMode.rawValue
        }
    }
}

extension MetaCommand {
    var description: String {
        return "\(type(of: self)): \(commands)"
    }
}
