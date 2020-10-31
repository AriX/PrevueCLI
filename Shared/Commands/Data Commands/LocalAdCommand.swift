//
//  LocalAdCommand.swift
//  PrevueCLI
//
//  Created by Ari on 11/17/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

// MARK: - Local ad structure

struct LocalAd: BinaryCodableStruct, Equatable {
    let adNumber: UInt8
    let content: [Content]
    let timePeriod: TimePeriod?

    struct Content: BinaryCodableStruct, Equatable {
        enum Alignment: Byte, BinaryCodableEnum {
            case center = 0x18 // ^X
            case left = 0x19 // ^Y
            case right = 0x1A // ^Z
            case crawl = 0x0B // ^K, for local ads on EPG only
        }
        struct TextColor: BinaryCodableStruct, Equatable {
            enum Color: Byte, BinaryCodableEnum {
                case transparent = 0x30
                case white = 0x31
                case black = 0x32
                case yellow = 0x33
                case red = 0x34
                case lightBlue = 0x35
                case grey = 0x36
                case blue = 0x37
            }
            let background: Color
            let foreground: Color
        }
        let alignment: Alignment?
        let color: TextColor? // Supported on Amiga only
        let text: String
    }
    struct TimePeriod: BinaryCodableStruct, Equatable {
        let beginning: Timeslot
        let ending: Timeslot
    }
}

// MARK: - Local ad commands

enum LocalAdCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.localAd
    case reset
    case ad(LocalAd)
}

struct ColorLocalAdCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.colorLocalAd
    let ad: LocalAd
}

// MARK: - Local ad encoding

extension LocalAd {
    static let terminator: Byte = 0x00
    
    init(fromBinary decoder: BinaryDecoder) throws {
        adNumber = try decoder.decode(UInt8.self)
        
        // Decode contents until we see a terminator or time period marker
        var contents: [Content] = []
        repeat {
            let content = try decoder.decode(Content.self)
            contents.append(content)
        } while decoder.nextByte != LocalAd.terminator && decoder.nextByte != LocalAd.TimePeriod.marker
        
        content = contents
        timePeriod = try TimePeriod(ifPresentFromBinary: decoder)
    }
}

extension LocalAd.Content {
    func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(alignment, color, text.asBytes)
    }
    init(fromBinary decoder: BinaryDecoder) throws {
        alignment = try Alignment(ifPresentFromBinary: decoder)
        color = try TextColor(ifPresentFromBinary: decoder)
        
        // Read text until a terminator, time period marker, color marker, or alignment byte
        text = try decoder.readString(until: { $0 == LocalAd.terminator || $0 == LocalAd.TimePeriod.marker || $0 == TextColor.marker || Alignment(rawValue: $0) != nil }, consumingFinalByte: false)
    }
}

extension LocalAd.Content.TextColor: MarkerBinaryCodable {
    static let marker: Byte = 0x03 // CTRL-C, for color
}

extension LocalAd.TimePeriod: MarkerBinaryCodable {
    static let marker: Byte = 0x14 // CTRL-T, for time
}

protocol MarkerBinaryCodable: BinaryCodable {
    static var marker: Byte { get }
}

extension MarkerBinaryCodable {
    static var headerBytes: Bytes { return [marker] }
    init?(ifPresentFromBinary decoder: BinaryDecoder) throws {
        guard decoder.nextByte == Self.marker else { return nil }
        try self.init(fromBinary: decoder)
    }
}

// MARK: - Local ad command encoding

extension LocalAdCommand {
    static let resetMarker: Byte = 0x92 // Special value 0x92 means reset all local ads
    
    init(fromBinary decoder: BinaryDecoder) throws {
        if decoder.nextByte == LocalAdCommand.resetMarker {
            self = .reset
            decoder.cursor += 1
        } else {
            let ad = try decoder.decode(LocalAd.self)
            self = .ad(ad)
        }
        
        decoder.cursor += footerBytes.count
    }
    func binaryEncode(to encoder: BinaryEncoder) throws {
        switch self {
        case .reset:
            encoder += LocalAdCommand.resetMarker
        case .ad(let ad):
            try encoder.encode(ad)
        }
        
        encoder += footerBytes
    }
    var footerBytes: Bytes {
        return [LocalAd.terminator]
    }
}

extension ColorLocalAdCommand {
    var footerBytes: Bytes {
        return [LocalAd.terminator]
    }
}

// MARK: - Codable

// Encode/decode local ad commands as the ad structure

extension LocalAdCommand {
    enum CodingKeys: String, CodingKey {
        case reset
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.allKeys.contains(.reset) {
            self = .reset
        } else {
            let ad = try decoder.singleValueContainer().decode(LocalAd.self)
            self = .ad(ad)
        }
    }
    func encode(to encoder: Encoder) throws {
        switch self {
        case .reset:
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(true, forKey: .reset)
        case .ad(let ad):
            var container = encoder.singleValueContainer()
            try container.encode(ad)
        }
    }
}

extension ColorLocalAdCommand {
    init(from decoder: Decoder) throws {
        let ad = try decoder.singleValueContainer().decode(LocalAd.self)
        self.init(ad: ad)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(ad)
    }
}

extension LocalAdCommand {
    var documentedType: UVSGDocumentedType {
        get {
            // Hack. TODO: Better represent nested enums.
            let documentedType = LocalAd(adNumber: 0, content: [.init(alignment: .center, color: nil, text: "")], timePeriod: .init(beginning: 0, ending: 0)).documentedType
            guard case var UVSGDocumentedType.dictionary(documentedDictionary) = documentedType else { fatalError("documentedType for LocalAd must be dictionary") }

            // Add the "reset" case
            documentedDictionary.insert(("reset", UVSGDocumentedType.optional(UVSGDocumentedType.scalar("Bool"))), at: 0)
            
            return .dictionary(documentedDictionary)
        }
    }
}

extension ColorLocalAdCommand {
    var documentedType: UVSGDocumentedType {
        get {
            ad.documentedType
        }
    }
}
