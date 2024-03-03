//
//  AtariListingsFiltering.swift
//  PrevueCLI
//
//  Created by Ari on 9/10/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

extension Listings.Channel {
    var isAtariCompatible: Bool {
        // Atari can't handle channel names longer than 5 characters, and seems to choke when channel numbers contain '.', so let's skip those channels
        if let channelNumber = channelNumber, channelNumber.contains(".") {
            return false
        } else if let callLetters = callLetters, callLetters.count > 5 {
            return false
        }
        
        return true
    }
}

extension Array where Element == Listings.Channel {
    mutating func makeAtariCompatible() {
        self = self.filter { $0.isAtariCompatible }
        
        // Limit Atari channel lineup to the first N channels
        self = Array(self.prefix(36/*EPGMachine.atariChannelLimit*/))
    }
}
