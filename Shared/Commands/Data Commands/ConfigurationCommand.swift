//
//  ConfigurationCommand.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

// Sources: http://ariweinstein.com/prevue/viewtopic.php?f=5&t=22&start=30, UVSG test files

// Example from test file (CONFIG1):
// 55 AA 46   42   49   32   33   36   38   4E   01   03   36   59   59   4E   4E   4E   4E   4E   4E   58   58   00
//       F    B    I    2    3    6    8    N              6    Y    Y    N    N    N    N    N    N    X    X
//       MODE BCK  FWD  SSPD #AD1 #AD2 LINE UNK  UNKA UNKA TZ   DST  CONT TEXT UNK2 UNK3 UNK4 UNK5 GRPH VIN  UNK6 END  CHECKSUM

// YAML codeable?

struct ConfigurationCommand: DataCommand {
    let commandMode = DataCommandMode.configuration
    let timeslotsBack: UInt8 // Backward display window (BCK): Number of half hour blocks away to start at (default A on Atari (should confirm), B on Amiga, must be A or B on Amiga)
    let timeslotsForward: UInt8 // Forward display window (FWD): Number of half hour blocks away to end at (default 6 on Atari (should confirm), 4 on Amiga, must be 1-8 on Amiga)
    let scrollSpeed: UInt8 // SSPD: Scroll speed (1-7) (default 3 on Amiga)
    let maxAdCount: UInt16 // #AD: Maximum number of ads to allow (default 36 on Amiga)
    let maxAdLines: UInt8 // LINE: The max # of lines allowed in an ad (default 6 on Amiga, max value 6)
    let unknown: Bool // Unknown value (default N on Amiga, should reverse serial parsing routine to see what it does, used in parseCtrlCmd)
    let unknownAdSetting: UInt16 // Unknown value, something related to how frequently local ads are displayed in the scroll (default 0002 on Atari (should confirm), 0101 on Amiga)
    let timezone: UInt8 // Timezone offset from GMT (default 6, meaning -6) (possible to support positive offsets?) (default 6 on Amiga)
    let observesDaylightSavingsTime: Bool // DST: ? (default N on Amiga)
    let cont: Bool // CONT: Unknown value, keyboard related (default Y on Amiga)
    let keyboardActive: Bool // TEXT: allow local ads editing (default N, switches between N/R/L/S in diagnostic mode on Amiga, Y/N on Atari)
    let unknown2: Bool // Default N
    let unknown3: Bool // Default N
    let unknown4: Bool // Default Y
    let unknown5: Byte // Default A
    let grph: UInt8 // GRPH: Unknown effect (default N on Amiga, possible values include N/E/L)
    let videoInsertion: UInt8 // VIN: Unknown, perhpas related to local video ads (default N on Amiga, appears to accept values X/L/N)
    let unknown6: UInt8 // Unknown value (default 0x00 on Amiga, values L or X observed in UVSG test files?) - seems to set some type of time offest (when 'X', timeslot is labeled 6:28 instead of 6:30)
}

extension ConfigurationCommand {
    var payload: Bytes {
        return [
            timeslotsBack.byteByRepresentingNumberAsASCIILetter(),
            timeslotsForward.byteByRepresentingNumberAsASCIILetter(),
            scrollSpeed.byteByRepresentingNumberAsASCIIDigit(),
            maxAdCount.bytesBySeparatingIntoASCIIDigits()[0],
            maxAdCount.bytesBySeparatingIntoASCIIDigits()[1],
            maxAdLines.byteByRepresentingNumberAsASCIIDigit(),
            unknown.byteByRepresentingAsASCIILetter(),
            unknownAdSetting.bytesBySeparatingIntoHighAndLowBits()[0],
            unknownAdSetting.bytesBySeparatingIntoHighAndLowBits()[1],
            timezone.byteByRepresentingNumberAsASCIIDigit(),
            observesDaylightSavingsTime.byteByRepresentingAsASCIILetter(),
            cont.byteByRepresentingAsASCIILetter(),
            keyboardActive.byteByRepresentingAsASCIILetter(),
            unknown2.byteByRepresentingAsASCIILetter(),
            unknown3.byteByRepresentingAsASCIILetter(),
            unknown4.byteByRepresentingAsASCIILetter(),
            unknown5,
            grph,
            videoInsertion,
            unknown6,
            0x00
        ]
    }
}
