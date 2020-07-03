//
//  TulsaTime.swift
//  PrevueCLI
//
//  Created by Ari on 7/2/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

extension ClockCommand {
    static var currentTulsaTime: ClockCommand? {
        let currentTimeZone = TimeZone.current
        guard let tulsaTimeZone = TimeZone.tulsa else { return nil }
        
        let currentDate = Date()
        let tulsaDate = currentDate.convertTimeZone(from: currentTimeZone, to: tulsaTimeZone)
        
        return ClockCommand(with: tulsaDate, timeZone: tulsaTimeZone)
    }
}

extension TimeZone {
    static var tulsa: TimeZone? {
        return TimeZone(identifier: "America/Chicago")
    }
}

extension Date {
    func convertTimeZone(from: TimeZone, to: TimeZone) -> Date {
         let delta = TimeInterval(to.secondsFromGMT(for: self) - from.secondsFromGMT(for: self))
         return addingTimeInterval(delta)
    }
}
