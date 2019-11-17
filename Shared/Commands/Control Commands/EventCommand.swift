//
//  EventCommand.swift
//  PrevueCLI
//
//  Created by Ari on 11/12/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

enum EventType: Character {
    case comingSoon = ":"
    case thisMonth = ";"
    case tuesdaysAndFridays = "?"
    case mondaysAndSaturdays = "@"
    case nextMonth = "<"
    case thisFall = "="
    case thisSummer = ">"
    case titleLookup = "0"
    case monday = "1"
    case tuesday = "2"
    case wednesday = "3"
    case thursday = "4"
    case friday = "5"
    case saturday = "6"
    case sunday = "7"
    case weekdays = "8"
    case weeknights = "9"
    case weekends = "A"
    case everyNight = "B"
    case everyDay = "C"
    case literal = "D" // From CTRL-Q
    case lookupRegionalAdData = "E"
    case ppvOrderInformation = "F"
    case sbeOrderInformation = "G"
    case mondaysThruSaturdays = "H"
    case mondaysThruThursdays = "I"
    case weekdayMornings = "J"
    case weekdayAfternoons = "K"
    case tuesdaysAndThursdays = "L"
    case thisWeek = "M"
    case v1OrderInformation = "N"
    case unformattedV1OrderInformation = "O"
}

struct EventCommand: ControlCommand {
    let commandMode = ControlCommandMode.eventType
    var leftEvent: EventType
    var rightEvent: EventType
}

extension EventCommand {
    var payload: Bytes {
        return ([leftEvent.rawValue.asByte()] + [rightEvent.rawValue.asByte()] + [Byte(0x0D)])
    }
}
