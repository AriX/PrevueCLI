//
//  CurdayDat+Listings.swift
//  PrevuePackage
//
//  Created by Ari on 9/12/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

extension CurdayDat.Channel.Program {
    init(fromBinary decoder: BinaryDecoder) throws {
        let backup = decoder.cursor
        
        let timeslot = try decoder.decode(StringConvertibleInt.self)
        guard timeslot != 49 else {
            self.init(timeslot: 49, flags: 0, programType: "", movieCategory: "", unknown: "", programName: "")
            return
        }
        
        decoder.cursor = backup
        
        try self.init(from: decoder)
    }
}

public extension CurdayDat {
    var listings: Listings {
        var channels: [Listings.Channel] = []
        var programs: [Listings.Program] = []
        
        for channel in self.channels {
            channels.append(channel.listingsChannel)
            programs += channel.listingsPrograms
        }
        
        let julianDay = JulianDay(dayOfYear: header.julianDayNumber.value)
        let programsDay = (julianDay, programs)
        return Listings(channels: channels, days: [programsDay])
    }
}

extension CurdayDat.Channel {
    var listingsChannel:  Listings.Channel {
        return Listings.Channel(sourceIdentifier: sourceIdentifier, channelNumber: channelNumber, timeslotMask: nil, callLetters: callLetters, flags: flags)
    }
    
    var listingsPrograms: [Listings.Program] {
        programs.compactMap {
            let timeslot = Timeslot($0.timeslot.value)
            if timeslot > 48 {
                return nil
            }
            
            let flags = Listings.Program.Attributes(rawValue: UInt8($0.flags.value))
            return Listings.Program(timeslot: timeslot, sourceIdentifier: sourceIdentifier, programName: $0.programName.descriptionConvertingSpecialCharactersToStrings, flags: flags)
        }
    }
}
