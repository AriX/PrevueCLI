//
//  LocalAdCommand.swift
//  PrevueCLI
//
//  Created by Ari on 11/17/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

// MARK: Local ad structure

struct LocalAd: Codable {
    let adNumber: UInt8
    let content: [Content]
    let timePeriod: TimePeriod?

    struct Content: Codable {
        enum Alignment: Byte {
            case center = 0x18 // ^X
            case left = 0x19 // ^Y
            case right = 0x1A // ^Z
            case crawl = 0x0B // ^K, for local ads on EPG only
        }
        struct TextColor: Codable {
            enum Color: Byte {
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
    struct TimePeriod: Codable {
        let beginning: Timeslot
        let ending: Timeslot
    }
}

// MARK: Local ad commands

struct LocalAdResetCommand: DataCommand {
    let commandMode = DataCommandMode.localAd
}

struct LocalAdCommand: DataCommand {
    let commandMode = DataCommandMode.localAd
    let ad: LocalAd
}

struct ColorLocalAdCommand: DataCommand {
    let commandMode = DataCommandMode.colorLocalAd
    let ad: LocalAd
}

// MARK: Local ad encoding

extension LocalAd: UVSGEncodable {
    var payload: Bytes {
        let encodedContents = content.reduce([]) {
            return $0 + $1.payload
        }
        return [adNumber] + encodedContents + timePeriod.payload + [0x00]
    }
}

extension LocalAd.Content: UVSGEncodable {
    var payload: Bytes {
        return alignment.payload + color.payload + text.asBytes()
    }
}

extension LocalAd.Content.Alignment: UVSGEncodable {
    var payload: Bytes {
        return [rawValue]
    }
}

extension LocalAd.Content.TextColor: UVSGEncodable {
    var payload: Bytes {
        let flag: Byte = 0x03 // CTRL-C, for color
        return [flag, background.rawValue, foreground.rawValue]
    }
}

extension LocalAd.TimePeriod: UVSGEncodable {
    var payload: Bytes {
        let flag: Byte = 0x14 // CTRL-T, for time
        return [flag, beginning, ending]
    }
}

// MARK: Local ad command encoding

extension LocalAdResetCommand {
    var payload: Bytes {
        let flag: Byte = 0x92 // Special value 0x92 means reset all local ads
        return [flag, 0x00]
    }
}

extension LocalAdCommand {
    var payload: Bytes {
        ad.payload
    }
    
    var documentedType: UVSGDocumentedType {
        get {
            ad.documentedType
        }
    }
}

extension ColorLocalAdCommand {
    var payload: Bytes {
        ad.payload
    }
    
    var documentedType: UVSGDocumentedType {
        get {
            ad.documentedType
        }
    }
}

// MARK: Codable support

// Encode/decode local ad commands as the ad structure

extension LocalAdCommand: Codable {
    init(from decoder: Decoder) throws {
        let ad = try decoder.singleValueContainer().decode(LocalAd.self)
        self.init(ad: ad)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(ad)
    }
}

extension ColorLocalAdCommand: Codable {
    init(from decoder: Decoder) throws {
        let ad = try decoder.singleValueContainer().decode(LocalAd.self)
        self.init(ad: ad)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(ad)
    }
}

// Encode Alignment as a string (e.g. "center") instead of as its byte value
extension LocalAd.Content.Alignment: UVSGDocumentableEnum, EnumCodableAsCaseName {
    init(from decoder: Decoder) throws {
        try self.init(asNameFrom: decoder)
    }
    func encode(to encoder: Encoder) throws {
        try encode(asNameTo: encoder)
    }
}

// Encode Color as a string (e.g. "red") instead of as its number value
extension LocalAd.Content.TextColor.Color: EnumCodableAsCaseName, UVSGDocumentableEnum {
    init(from decoder: Decoder) throws {
        try self.init(asNameFrom: decoder)
    }
    func encode(to encoder: Encoder) throws {
        try encode(asNameTo: encoder)
    }
}
