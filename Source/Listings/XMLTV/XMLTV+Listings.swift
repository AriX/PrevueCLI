//
//  XMLTV+Listings.swift
//  PrevuePackage
//
//  Created by Ari on 9/12/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

/**
 A couple of known issues here:
 - Sometimes, 2 programs are on at nearly the same time (e.g. Action News Sports starts 20 minutes into Action News). We don't handle that well.
 - I'm pretty sure sports programs are supposed to show in green, but that's not happening right now for some reason.
 - The 1999 curday.dat shows premium channels in althilite color, but we don't know which channels are premium. Similarly, we don't handle sumbySrc.
 - Sometimes, movie descriptions are a bit long and take up more than one entire grid's worth of space.
 - There may be time zone problems/inflexibility if you're sending listings for days other than today, in the current time zone. (See a few comments below.)
 */

extension XMLTV {
    var listings: Listings {
        var channels: [Listings.Channel] = []
        var programs: [Listings.Program] = []
        
        let sortedChannels = self.channels.values.sorted { $0.channelNumber! < $1.channelNumber! }
        for channel in sortedChannels {
            if let listingsChannel = channel.listingsChannel {
                channels.append(listingsChannel)
                programs += channel.listingsPrograms
            }
        }
        
        let julianDay = JulianDay.today //find earliest date?JulianDay(convertingToByte: header.julianDayNumber.value)
        return Listings(julianDay: julianDay, channels: channels, programs: programs)
    }
}

extension XMLTV.Channel {
    var listingsChannel: Listings.Channel? {
        guard let sourceIdentifier = sourceIdentifier,
            let channelNumber = channelNumber,
            let callLetters = callLetters else { return nil }
        
        return Listings.Channel(sourceIdentifier: sourceIdentifier, channelNumber: String(channelNumber), timeslotMask: nil, callLetters: callLetters, flags: .none)
    }
    
    var listingsPrograms: [Listings.Program] {
        guard let sourceIdentifier = sourceIdentifier else { return [] }
        
        return programs.compactMap {
            return $0.listingsProgram(sourceIdentifier: sourceIdentifier)
        }
    }
}

// TODO: This logic could be cleaned up
extension XMLTV.Channel {
    var sourceIdentifier: Listings.SourceIdentifier? {
        guard let callLetters = callLetters else {
            return nil
        }
        return String(callLetters.prefix(6))
    }
    
    var channelNumber: Int? {
        let displayNamesWithDigits = displayNames.filter { $0.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil }
        let displayNamesWithOnlyDigits = displayNamesWithDigits.filter { CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: $0)) }
        
        let mostSpecificResults = (displayNamesWithOnlyDigits.count > 0 ? displayNamesWithOnlyDigits : (displayNamesWithDigits.count > 0 ? displayNamesWithDigits : displayNames))
        let shortestResults = mostSpecificResults.sorted { return $0.count > $1.count }
        guard let channelNumber = shortestResults.first else {
            return nil
        }
        return Int(channelNumber)
    }
    
    var callLetters: String? {
        let allCapsDisplayNames = displayNames.filter {
            let includesOnlyUppercaseLettersAndDigits = CharacterSet.uppercaseLetters.union(CharacterSet.decimalDigits).isSuperset(of: CharacterSet(charactersIn: $0))
            let includesAtLeastOneUppercaseLetter = ($0.rangeOfCharacter(from: CharacterSet.uppercaseLetters) != nil)
            
            return (includesOnlyUppercaseLettersAndDigits && includesAtLeastOneUppercaseLetter)
        }
        let shortestResults = allCapsDisplayNames.sorted { return $0.count > $1.count }
        guard let callLetters = shortestResults.first else {
            return nil
        }
        return String(callLetters.prefix(7))
    }
}

extension XMLTV.Channel.Program {
    var isMovie: Bool {
        return categories.contains("movie")
    }
    
    var ratingCharacter: SpecialCharacter? {
        if let usRating = ratings.first(where: { $0.isUSRating }),
           let ratingCharacter = usRating.specialCharacter {
            return ratingCharacter
        } else if categories.contains("Adults only") {
            return .ratingAdult
        } else {
            return nil
        }
    }
    
    var flags: Listings.Program.Attributes {
        var flags: Listings.Program.Attributes = []
        
        if categories.contains("movie") {
            flags.insert(.movie)
        }
        
        if categories.contains("sports") {
            flags.insert(.none)
            flags.insert(.sportsProg)
        }
        
        if flags.isEmpty {
            flags = .none
        }
        
        return flags
    }
    
    var programName: SpecialCharacterString {
        var programName: [SpecialCharacterString.Component] = []
        
        if !startDate.startsOnTimeslotBoundary {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "h:mm"
            var startTime = dateFormatter.string(from: startDate) // NOTE: This assumes listings are in local time zone. In the future, we may want to support generating listings for other time zones.
            
            // To match Prevue behavior, pad with a space if the hour is only one character long
            if startTime.count < 5 {
                startTime = " \(startTime)"
            }
            
            programName.append(.string("(\(startTime)) "))
        }
        
        if isMovie {
            programName.append(.string("\"\(title)\" "))
            
            if let ratingCharacter = ratingCharacter {
                programName.append(.specialCharacter(ratingCharacter))
                programName.append(.string(" "))
            }
            
            if let year = year {
                programName.append(.string("(\(year)) "))
            }
            
            let actors = self.actors.prefix(2)
            if actors.count > 0 {
                let actorString = actors.joined(separator: ", ")
                programName.append(.string("\(actorString). "))
            }
            
            if let description = description {
                programName.append(.string("\(description)"))
            }
            
        } else {
            programName.append(.string(title))
            
            if let ratingCharacter = ratingCharacter {
                programName.append(.string(" "))
                programName.append(.specialCharacter(ratingCharacter))
            }
        }
        
        if let stereo = stereo, stereo {
            programName.append(.string(" "))
            programName.append(.specialCharacter(.stereo))
        }
        
        if closedCaptioned {
            programName.append(.string(" "))
            programName.append(.specialCharacter(.closedCaptioned))
        }
        
        if isMovie, let duration = duration {
            programName.append(.string(" (\(duration.durationString))"))
            
        }
        
        return SpecialCharacterString(components: programName)
    }
    
    func listingsProgram(sourceIdentifier: Listings.SourceIdentifier) -> Listings.Program? {
        return Listings.Program(timeslot: startDate.timeslot, sourceIdentifier: sourceIdentifier, programName: programName, flags: flags)
    }
}

extension XMLTV.Channel.Program.Rating {
    var isUSRating: Bool {
        switch ratingSystem {
        case "Motion Picture Association of America":
            return true
        case "USA Parental Rating":
            return true
        default:
            return false
        }
    }
    
    var specialCharacter: SpecialCharacter? {
        switch rating {
        case "R":
            return .ratingR
        case "PG":
            return .ratingPG
        case "PG-13":
            return .ratingPG13
        case "NC-17":
            return .ratingNC17
        case "TVY":
            return .ratingTVY
        case "TVY7":
            return .ratingTVY7
        case "TVG":
            return .ratingTVG
        case "TVPG":
            return .ratingTVPG
        case "TVM":
            return .ratingTVM
        case "TVMA":
            return .ratingTVMA
        default:
            return nil
        }
    }
}
