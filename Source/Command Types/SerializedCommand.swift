//
//  SatelliteCommandSerialization.swift
//  PrevueCLI
//
//  Created by Ari on 8/8/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

// MARK: Structures

public struct SerializedCommand {
    let command: Command
    
    // This should include an example of each command that can be serialized or deserialized
    static let referenceCommands: [Command] = [
        BoxOnCommand(selectCode: ""),
        BoxOffCommand(),
        ResetCommand(),
        VersionCommand(versionString: "4.1"),
        TitleCommand(alignment: .center, title: ""),
        ClockCommand(with: Date())!,
        CurrentClockCommand(dayOfYear: 0),
        DownloadCommand(message: .start(filePath: "")),
        TransferFileCommand(localFilePath: "", remoteFilePath: ""),
        DSTCommand(mode: .local, start: DSTBoundary(year: 0, dayOfYear: 0, hour: 0, minute: 0), end: DSTBoundary(year: 0, dayOfYear: 0, hour: 0, minute: 0)),
        CurrentDSTCommand(),
        LocalAdCommand.ad(LocalAd(adNumber: 0, content: [.init(alignment: nil, color: nil, text: "")], timePeriod: .init(beginning: 0, ending: 0))),
        ColorLocalAdCommand(ad: LocalAd(adNumber: 0, content: [.init(alignment: .center, color: .init(background: .red, foreground: .red), text: "")], timePeriod: .init(beginning: 0, ending: 0))),
        ConfigurationCommand(timeslotsBack: 1, timeslotsForward: 4, scrollSpeed: 3, maxAdCount: 36, maxAdLines: 6, crawlOrIgnoreNationalAds: false, unknownAdSetting: 0x0101, timezone: 7, observesDaylightSavingsTime: true, cont: true, keyboardActive: false, unknown2: false, unknown3: false, unknown4: true, unknown5: 0x41, grph: 0x4E, videoInsertion: 0x4E, unknown6: 0x00),
        NewLookConfigurationCommand(displayFormat: .grid, textAdFlag: .satellite, clockCmd: 1),
        ChannelsCommand(day: JulianDay(dayOfYear: 0), channels: [Listings.Channel(sourceIdentifier: "", channelNumber: "", timeslotMask: TimeslotMask(blackedOutTimeslots: [0]), callLetters: "", flags: [])]),
        ProgramCommand(day: JulianDay(dayOfYear: 0), program: Listings.Program(timeslot: 0, sourceIdentifier: "", programName: "", flags: [])),
        ListingsCommand(listingsDirectoryPath: "", forAtari: false, omitSpecialCharacters: false),
    ]
}

// MARK: Binary serialization

extension SerializedCommand: BinaryCodable {
    public func binaryEncode(to encoder: BinaryEncoder) throws {
        for command in command.satelliteCommands {
            var encodedBytes: [Byte] = []
            
            if command is DataCommand {
                // Encode start bytes
                let startBytes: Bytes = [0x55, 0xAA]
                encodedBytes.append(contentsOf: startBytes)
            }
            
            // Encode mode byte
            encodedBytes.append(command.commandModeByte)
            
            // Encode payload
            let payload = try BinaryEncoder.encode(command)
            encodedBytes.append(contentsOf: payload)
            
            // Encode checksum
            let checksum = encodedBytes.checksum()
            encodedBytes.append(checksum)
            
            // Write to encoder
            encoder += encodedBytes
        }
    }
    
    public init(fromBinary decoder: BinaryDecoder) throws {
        // Look for 55
        _ = try decoder.read(until: { $0 == 0x55 }, consumingFinalByte: false)
        
        // Bail if we ran out of data already
        if decoder.cursor == decoder.data.count {
            throw BinaryDecoder.Error.expectedEndOfData
        }
        
        let initialDecoderPosition = decoder.cursor
        
        // Expect 55 AA
        let startBytes = try decoder.decode(UInt16.self)
        if startBytes != 0x55AA {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "DataCommand must begin with 55 AA"))
        }
        
        let commandMode = try decoder.decode(DataCommandMode.self)
        guard let commandType = SerializedCommand.commandType(for: commandMode),
            let referenceCommand = SerializedCommand.referenceCommand(for: commandMode) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unrecognized command mode \(commandMode)"))
        }
        
        // Create new decoder for this command (so that we can set its referenceItem)
        let subdata = decoder.data.suffix(from: decoder.cursor)
        let newDecoder = BinaryDecoder(data: Array(subdata))
        newDecoder.userInfo = decoder.userInfo
        newDecoder.referenceItem = referenceCommand
        
        command = try commandType.decodeCommand(with: newDecoder)
        
        // Apply changes to the old decoder
        decoder.cursor += newDecoder.cursor
        decoder.userInfo = newDecoder.userInfo
        
        let finalDecoderPosition = decoder.cursor
        
        let decodedBytes = decoder.data[initialDecoderPosition..<finalDecoderPosition]
        let expectedChecksum = decodedBytes.checksum()
        
        let checksum = try decoder.decode(Byte.self)
        if checksum != expectedChecksum {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Checksum \(checksum.hexEncodedString()) did not match expected checksum \(expectedChecksum.hexEncodedString()) for \(command)"))
        }
    }
}

// MARK: Codable serialization
 
extension SerializedCommand: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        
        let commandTypeName = String(describing: type(of: command))
        let codingKey = DynamicKey(stringValue: commandTypeName)
        try command.encode(to: container.superEncoder(forKey: codingKey))
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        try self.init(from: container)
    }
    
    init(from container: KeyedDecodingContainer<DynamicKey>) throws {
        guard let codingKey = container.allKeys.first else {
            throw DecodingError.valueNotFound(SatelliteCommand.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "No commands found in SerializedCommand"))
        }
        guard let commandType = SerializedCommand.commandType(for: codingKey.stringValue) else {
            throw DecodingError.dataCorruptedError(forKey: codingKey, in: container, debugDescription: "Invalid command type: \(codingKey)")
        }
        
        command = try commandType.decodeCommand(with: container.superDecoder(forKey: codingKey))
    }
    
    static func canDecode(from container: KeyedDecodingContainer<DynamicKey>) -> Bool {
        guard let codingKey = container.allKeys.first else { return false }
        guard SerializedCommand.commandType(for: codingKey.stringValue) != nil else { return false }
        
        return true
    }
}

// MARK: Serialization helpers

extension Command {
    static func decodeCommand(with decoder: Decoder) throws -> Self {
        let container = try decoder.singleValueContainer()
        return try container.decode(Self.self)
    }
}

extension SerializedCommand {
    static var commandTypes: [Command.Type] {
        return SerializedCommand.referenceCommands.map { type(of: $0) }
    }
    
    static func referenceCommand(for commandMode: DataCommandMode) -> SatelliteCommand? {
        let satelliteCommands = SerializedCommand.referenceCommands.compactMap { (command) -> SatelliteCommand? in
            return command as? SatelliteCommand
        }
        return satelliteCommands.first { commandMode.rawValue.asciiValue == $0.commandModeByte }
    }
    
    static func commandType(for commandMode: DataCommandMode) -> SatelliteCommand.Type? {
        guard let referenceCommand = referenceCommand(for: commandMode) else { return nil }
        return type(of: referenceCommand)
    }

    static func commandType(for name: String) -> Command.Type? {
        return commandTypes.first { name == String(describing: $0) }
    }
}

// MARK: Command documentation

extension SerializedCommand {
    static var commandDocumentation: UVSGDocumentedType {
        let documentedTypes = SerializedCommand.referenceCommands.map { (command) -> (String, UVSGDocumentedType) in
            return (String(describing: type(of: command)), command.documentedType)
        }
        
        return .dictionary(documentedTypes)
    }
}
