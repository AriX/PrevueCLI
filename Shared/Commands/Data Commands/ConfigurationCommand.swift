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

struct ConfigurationCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.configuration
    let timeslotsBack: ASCIICharacterInt // Backward timeslot display window (BCK): Number of half hour blocks away to start at (default 0 (A) on Atari, B on Amiga, must be A or B on Amiga)
    let timeslotsForward: ASCIICharacterInt // Forward timeslot display window (FWD): Number of half hour blocks away to end at (default 6 on Atari, E (4) on Amiga, must be 1-8 on Amiga; 'A'=>0, 'E'=>4, 'I'=>7)
    let scrollSpeed: ASCIIDigitInt // SSPD: Scroll speed (1-8 on Amiga; 1-7 on Atari) (default 3 on Amiga, 4 on Atari)
    let maxAdCount: ASCIIDigitsInt16 // #AD: Maximum number of ads to allow (default 6 on Atari, 36 on Amiga)
    let maxAdLines: ASCIIDigitInt // LINE: The max # of lines allowed in an ad (default 6 on Amiga, max value 6)
    let crawlOrIgnoreNationalAds: ASCIICharacterBool // On EPG: CRAWL setting (Y/N); on Prevue: IGNORE_NAT_ADS setting (Y/N), defines wheter or not to ignore national ads (default N)
    let unknownAdSetting: UInt16 // Unknown value, something related to how frequently local ads are displayed in the scroll (default 0002 on Atari (should investigate), 0101 on Amiga)
    let timezone: ASCIIDigitInt // Timezone offset from GMT (default 6, meaning -6) (possible to support positive offsets?) (default 6 on Amiga)
    let observesDaylightSavingsTime: ASCIICharacterBool // DST: ? (default N on Amiga)
    let cont: ASCIICharacterBool // CONT: Unknown value, keyboard related (default Y on Amiga)
    let keyboardActive: ASCIICharacterBool // TEXT: allow local ads editing (default N, switches between N/R/L/S in diagnostic mode on Amiga, Y/N on Atari)
    let unknown2: ASCIICharacterBool // Default N
    let unknown3: ASCIICharacterBool // Default N
    let unknown4: ASCIICharacterBool // Default Y
    let unknown5: Byte // Default A
    let grph: UInt8 // GRPH: Unknown effect (default N on Amiga, possible values include N/E/L)
    let videoInsertion: UInt8 // VIN: Unknown, perhpas related to local video ads (default N on Amiga, appears to accept values X/L/N)
    let unknown6: UInt8 // Unknown value (default 0x00 on Amiga, values L or X observed in UVSG test files?) - seems to set some type of time offest (when 'X', timeslot is labeled 6:28 instead of 6:30)
}

extension ConfigurationCommand {
    var footerBytes: Bytes {
        return [0x00]
    }
}
