//
//  ChannelsCommand.swift
//  PrevueApp
//
//  Created by Ari on 4/6/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

struct ChannelsCommand: DataCommand, Codable, Equatable {
    static let commandMode = DataCommandMode.channel
    let day: JulianDay
    let channels: [Channel]
}

// MARK: Binary coding

extension Channel: BinaryCodable {
    static let marker: Byte = 0x12
    static let channelNumberMarker: Byte = 0x11
    static let callLettersMarker: Byte = 0x01

    init(fromBinary decoder: BinaryDecoder) throws {
        flags = try decoder.decode(ChannelAttributes.self)
        sourceIdentifier = try decoder.readString(until: { $0 == Channel.channelNumberMarker})
        channelNumber = try decoder.readString(until: { $0 == Channel.callLettersMarker})
        callLetters = try decoder.readString(until: { $0 == Channel.marker || $0 == ChannelsCommand.terminator }, consumingFinalByte: false)
    }
    
    func binaryEncode(to encoder: BinaryEncoder) throws {
        encoder += [Channel.marker, flags.rawValue, sourceIdentifier.asBytes(), Channel.channelNumberMarker, channelNumber.asBytes(), Channel.callLettersMarker, callLetters.asBytes()]
    }
}

extension ChannelsCommand: BinaryCodable {
    static let terminator: Byte = 0x00
    
    init(fromBinary decoder: BinaryDecoder) throws {
        day = try decoder.decode(JulianDay.self)
        
        var decodedChannels: [Channel] = []
        // Check for 0x12, which marks the beginning of another channel block
        while try decoder.decode(Byte.self) == Channel.marker {
            let channel = try decoder.decode(Channel.self)
            decodedChannels.append(channel)
        }
        
        channels = decodedChannels
    }
    
    func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(day, channels, ChannelsCommand.terminator)
    }
}
