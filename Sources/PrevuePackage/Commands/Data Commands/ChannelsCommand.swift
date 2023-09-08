//
//  ChannelsCommand.swift
//  PrevueApp
//
//  Created by Ari on 4/6/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

struct ChannelsCommand: DataCommand, Codable, Equatable {
    static let commandMode = DataCommandMode.channel
    var day: JulianDay
    var channels: [Listings.Channel]
}

// MARK: Binary coding

extension Listings.Channel: BinaryCodable {
    static let marker: Byte = 0x12
    static let channelNumberMarker: Byte = 0x11
    static let timeslotMaskMarker: Byte = 0x14
    static let callLettersMarker: Byte = 0x01

    init(fromBinary decoder: BinaryDecoder) throws {
        flags = try decoder.decode(Attributes.self)
        
        var markerByte: Byte?
        var readSourceIdentifier: String?
        var channelNumber: String?
        var timeslotMask: TimeslotMask?
        var callLetters: String?
        
        repeat {
            switch markerByte {
            case nil:
                let chunkEndMarkers = [Self.channelNumberMarker, Self.timeslotMaskMarker, Self.callLettersMarker, Self.marker, ChannelsCommand.terminator]
                let nextChunk = try decoder.read(until: { chunkEndMarkers.contains($0) }, consumingFinalByte: false)
                readSourceIdentifier = String(decoding: nextChunk, as: Unicode.UTF8.self)
                break
            case Self.channelNumberMarker:
                let chunkEndMarkers = [Self.timeslotMaskMarker, Self.callLettersMarker, Self.marker, ChannelsCommand.terminator]
                let nextChunk = try decoder.read(until: { chunkEndMarkers.contains($0) }, consumingFinalByte: false)
                channelNumber = String(decoding: nextChunk, as: Unicode.UTF8.self)
                break
            case Self.timeslotMaskMarker:
                timeslotMask = try decoder.decode(TimeslotMask.self)
                break
            case Self.callLettersMarker:
                let chunkEndMarkers = [Self.marker, ChannelsCommand.terminator]
                let nextChunk = try decoder.read(until: { chunkEndMarkers.contains($0) }, consumingFinalByte: false)
                callLetters = String(decoding: nextChunk, as: Unicode.UTF8.self)
                break
            default:
                break
            }
            
            markerByte = try decoder.decode(Byte.self)
        } while markerByte != Self.marker && markerByte != ChannelsCommand.terminator
        
        decoder.cursor -= 1 // Step back one so we don't consume the next channel/terminator marker
        
        guard let sourceIdentifier = readSourceIdentifier else {
            throw BinaryDecoder.Error.malformedData(description: "Channel is missing source identifier")
        }
        
        self.sourceIdentifier = sourceIdentifier
        self.channelNumber = channelNumber
        self.timeslotMask = timeslotMask
        self.callLetters = callLetters
    }
    
    func binaryEncode(to encoder: BinaryEncoder) throws {
        encoder += [Self.marker, flags.rawValue, sourceIdentifier.asBytes]
        
        if let channelNumber = channelNumber {
            encoder += [Self.channelNumberMarker, channelNumber.asBytes]
        }
        
        if let timeslotMask = timeslotMask {
            encoder += [Self.timeslotMaskMarker, timeslotMask.asBytes]
        }
        
        if let callLetters = callLetters {
            encoder += [Self.callLettersMarker, callLetters.asBytes]
        }
    }
}

extension ChannelsCommand: BinaryCodable {
    static let terminator: Byte = 0x00
    
    init(fromBinary decoder: BinaryDecoder) throws {
        day = try decoder.decode(JulianDay.self)
        
        var decodedChannels: [Listings.Channel] = []
        // Check for 0x12, which marks the beginning of another channel block
        while try decoder.decode(Byte.self) == Listings.Channel.marker {
            let channel = try decoder.decode(Listings.Channel.self)
            decodedChannels.append(channel)
        }
        
        channels = decodedChannels
    }
    
    func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(day, channels, ChannelsCommand.terminator)
    }
}
