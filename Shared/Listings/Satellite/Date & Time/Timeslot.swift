//
//  Timeslot.swift
//  PrevuePackage
//
//  Created by Ari on 9/13/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

typealias Timeslot = UInt8 // 1 to 48; timeslot 1 is 5 AM

struct TimeslotMask: Equatable {
    let blackedOutTimeslots: [Timeslot]
}

// MARK: Date utilities

extension Date {
    var timeslot: Timeslot {
        return UInt8(timeslotWithRemainder)
    }
    var timeslotWithRemainder: Double {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfListingsDay(for: .currentTulsaDate)
        
        let timeComponents = calendar.dateComponents(in: .tulsa, from: self)
        let todayComponents = calendar.dateComponents(in: .tulsa, from: startOfToday)

        let minutes = calendar.dateComponents([.minute], from: todayComponents, to: timeComponents).minute ?? 0
        let timeslot = (Double(minutes) / 30.0)
        return (timeslot + 1) // Add 1 to get range 1-48, not 0-47
    }
    var startsOnTimeslotBoundary: Bool {
        return timeslotWithRemainder.truncatingRemainder(dividingBy: 1) == 0
    }
}

// MARK: Timeslot encoding

extension TimeslotMask: BinaryCodableStruct {
    init(fromBinary decoder: BinaryDecoder) throws {
        let maskBytes = try decoder.readBytes(count: 6)
        blackedOutTimeslots = maskBytes.asBits.enumerated().compactMap { (index, element) -> Timeslot? in
            if case .zero = element {
                return Timeslot(index + 1)
            } else {
                return nil
            }
        }
    }
    func binaryEncode(to encoder: BinaryEncoder) throws {
        encoder += self.asBytes
    }
    var asBytes: Bytes {
        var timeslotBits = [Bit](repeating: .one, count: 48)
        for timeslot in blackedOutTimeslots {
            timeslotBits[Int(timeslot) - 1] = .zero
        }
        return timeslotBits.asBytes
    }
}
