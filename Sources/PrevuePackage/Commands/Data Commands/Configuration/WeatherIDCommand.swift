//
//  WeatherIDCommand.swift
//  PrevuePackage
//
//  Created by Ari on 8/9/23.
//  Copyright © 2023 Vertex. All rights reserved.
//

import Foundation

struct WeatherIDCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.weatherID
    let displayCount: ASCIICharacter // 0-9; 0 = never display, 1 = display every timeslot, 2 = display every other timeslot, 3 = display every 3rd timeslot etc.
    let weatherID: String
    let cityString: String
}

extension WeatherIDCommand {
    static let endOfStringMarker: Byte = 0x12 // ^R
    
    func binaryEncode(to encoder: BinaryEncoder) throws {
        try encoder.encode(displayCount)
        try encoder.encode(weatherID.asBytes)
        try encoder.encode(WeatherIDCommand.endOfStringMarker)
        try encoder.encode(cityString.asBytes)
        try encoder.encode(Byte(0x00))
    }
    
    init(fromBinary decoder: BinaryDecoder) throws {
        displayCount = try decoder.decode(ASCIICharacter.self)
        weatherID = try decoder.readString(until: { $0 == WeatherIDCommand.endOfStringMarker})
        cityString = try decoder.readString(until: { $0 == 0x00})
    }
}
