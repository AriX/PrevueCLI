//
//  AtariListingsFiltering.swift
//  PrevueCLI
//
//  Created by Ari on 9/10/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

protocol AtariListingsFiltering {
    func makeAtariCompatible(atIndex: Int) -> Self?
}

extension Listings.Channel: AtariListingsFiltering {
    func makeAtariCompatible(atIndex index: Int) -> Listings.Channel? {
        // Atari can't handle channel names longer than 5 characters, and seems to choke when channel numbers contain '.', so let's skip those channels
        if let channelNumber = channelNumber, channelNumber.contains(".") {
            return nil
        } else if let callLetters = callLetters, callLetters.count > 5 {
            return nil
        }
        
        // Limit Atari channel lineup to the first 48 channels
        if index > 48 {
            return nil
        }
        
        return self
    }
}

extension Listings.Program: AtariListingsFiltering {
    func makeAtariCompatible(atIndex index: Int) -> Listings.Program? {
        // Atari can't handle channel names longer than 5 characters, so let's skip those programs
        let strippedProgramName = SpecialCharacterString(with: programName.descriptionExcludingSpecialCharacters)
        return Listings.Program(timeslot: timeslot, sourceIdentifier: sourceIdentifier, programName: strippedProgramName, flags: flags)
    }
}

extension Array where Element: AtariListingsFiltering {
    func makeAtariCompatible() -> Self {
        return enumerated().compactMap {
            $0.element.makeAtariCompatible(atIndex: $0.offset)
        }
    }
}
