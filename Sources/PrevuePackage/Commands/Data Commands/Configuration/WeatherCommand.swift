//
//  WeatherCommand.swift
//  PrevuePackage
//
//  Created by Ari on 9/14/23.
//  Copyright © 2023 Vertex. All rights reserved.
//

import Foundation

struct WeatherCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.weather
    let displayLength: Byte // How long to display this weather command for, in minutes
    let colorID: Byte
    enum Icon: Byte, BinaryCodableEnum, EnumCodableAsCaseName {
        case noIcon = 1
        case sun = 2
        case cloud = 3
        case rain = 4
        case overcast = 5
        case snow = 6
        case fog = 7
        case cold = 8
    }
    let icon: Icon
    let weatherID: String
    let weatherText: String
}

extension WeatherCommand {
    static let endOfStringMarker: Byte = 0x12 // ^R
    
    func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(displayLength)
        try encoder.encode(colorID)
        try encoder.encode(icon)
        try encoder.encode(Byte(0x01)) // Unused "spare expansion byte"
        try encoder.encode(weatherID.asBytes)
        try encoder.encode(WeatherCommand.endOfStringMarker)
        try encoder.encode(weatherText.asBytes)
        try encoder.encode(Byte(0x00))
    }
    
    init(fromBinary decoder: BinaryDecoder) throws {
        displayLength = try decoder.decode(Byte.self)
        colorID = try decoder.decode(Byte.self)
        icon = try decoder.decode(Icon.self)
        _ = try decoder.decode(Byte.self) // Unused "spare expansion byte"
        weatherID = try decoder.readString(until: { $0 == WeatherCommand.endOfStringMarker})
        weatherText = try decoder.readString(until: { $0 == 0x00})
    }
}
