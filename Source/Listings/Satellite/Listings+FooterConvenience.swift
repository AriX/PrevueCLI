//
//  Listings+FooterConvenience.swift
//  PrevueApp
//
//  Created by Ari on 4/9/21.
//  Copyright © 2021 Vertex. All rights reserved.
//

import Foundation

extension Listings {
    mutating func addFooterText(sourceIdentifier: Listings.SourceIdentifier, footerText1: String, footerText2: String) {
        let (channel, programs) = Listings.generateFooterChannelAndPrograms(sourceIdentifier: sourceIdentifier, footerText1: footerText1, footerText2: footerText2)
        addChannelAndProgramsToEveryDay(channel, programs)
    }
    
    mutating func addChannelAndProgramsToEveryDay(_ channel: Channel, _ programs: [Program]) {
        channels.append(channel)
        days = days.map { ($0.julianDay, $0.programs + programs) }
    }
    
    static func generateFooterChannelAndPrograms(sourceIdentifier: Listings.SourceIdentifier, footerText1: String, footerText2: String) -> (Channel, [Program]) {
        let channel = Channel(sourceIdentifier: sourceIdentifier, channelNumber: "", timeslotMask: nil, callLetters: "", flags: [.ditto, .stereo])
        let programs: [Program] = stride(from: 1, to: 48, by: 1).map {
            let timeslot = Timeslot($0)
            let footerText = (timeslot % 2 == 0 ? footerText1 : footerText2)
            let programName = SpecialCharacterString(footerText)
            return Program(timeslot: timeslot, sourceIdentifier: sourceIdentifier, programName: programName, flags: .none)
        }
        return (channel, programs)
    }
}
