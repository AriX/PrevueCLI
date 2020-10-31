//
//  TulsaTime.swift
//  PrevueCLI
//
//  Created by Ari on 7/2/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

extension TimeZone {
    static var tulsa: TimeZone {
        guard let tulsaTimeZone = TimeZone(identifier: "America/Chicago") else {
            fatalError("Failed to load Tulsa time zone")
        }
        
        return tulsaTimeZone
    }
}

extension Date {
    func convertTimeZone(from: TimeZone, to: TimeZone) -> Date {
         let delta = TimeInterval(to.secondsFromGMT(for: self) - from.secondsFromGMT(for: self))
         return addingTimeInterval(delta)
    }
    static var currentTulsaDate: Date {
        let currentDate = Date()
        return currentDate.convertTimeZone(from: .current, to: .tulsa)
    }
}
