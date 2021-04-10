//
//  JulianDay.swift
//  PrevuePackage
//
//  Created by Ari on 9/26/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

struct JulianDay: Equatable, Hashable {
    let dayOfYear: Int
}

// MARK: Convenience

extension JulianDay {
    init(from date: Date) {
        let calendar = Calendar.current
        let adjustedDate = calendar.date(byAdding: .hour, value: -5, to: date)! // Subtract 5 hours, since the listings day starts at 5 AM
        dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: adjustedDate)!
    }
    
    static var today: JulianDay {
        return JulianDay(from: .currentTulsaDate)
    }
}

// MARK: Encoding

extension JulianDay: BinaryCodableStruct {    
    var asByte: Byte {
        return UInt8(dayOfYear % 256)
    }
    
    init(fromBinary decoder: BinaryDecoder) throws {
        let day = try decoder.decode(UInt8.self)
        dayOfYear = Int(day)
    }
    
    func binaryEncode(to encoder: BinaryEncoder) throws {
        encoder += self.asByte
    }
}
