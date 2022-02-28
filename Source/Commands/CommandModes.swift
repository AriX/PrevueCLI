//
//  CommandModes.swift
//  PrevuePackage
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

// This is a subset of the command modes discussed here: http://prevueguide.com/wiki/UVSG_Satellite_Data#Command_Modes

enum DataCommandMode: ASCIICharacter, BinaryCodableEnum {
    case boxOn = "A"
    case channel = "C"
    case newChannel = "c"
    case configuration = "F"
    case configDat = "f"
    case daylightSavingsTime = "g"
    case download = "H"
    case ppvOrderInfo = "J"
    case newPPVOverInfo = "j"
    case clock = "K"
    case localAd = "L"
    case clearListing = "O"
    case program = "P"
    case newProgram = "p"
    case reset = "R"
    case title = "T"
    case colorLocalAd = "t"
    case version = "V"
    case saveData = "%"
    case boxOff = "\u{BB}"
    
    // Debug commands
    case debugAddCTRLByte = "G"
}

enum ControlCommandMode: Byte, BinaryCodableEnum {
    case action = 0x01 // CTRL-A - "Promo Action Command"
    case setDefaultBrushes = 0x02 // CTRL-B - "Set Default Brushes"
    case defaultGraphic = 0x03 // CTRL-C  - "Default Graphic Command"
    case defaultPromoSide = 0x04 // CTRL-D - "Default Promo Side Command"
    case eventType = 0x05 // CTRL-E - "Event Type Command"
    case startGridScroll = 0x07 // CTRL-G - "Grid Scrolling Start Command"
    case clock = 0x0B // CTRL-K (only in newer software)
    case actionLocalAvails = 0x0C // CTRL-L - "Local Avail or Tagged Promo"
    case setGenlockFadeLevel = 0x0F // CTRL-O - "Set Genlock Fade Level"
    case pauseGridScroll = 0x10 // CTRL-P - "Grid Scrolling Pause Command"
    case titleStrings = 0x11 // CTRL-Q - "Title Strings Command"
    case videoVue = 0x13 // CTRL-S - "Video View Command" (only in older software)
    case unknownT = 0x14 // CTRL-T (only in newer software)
    case videoInsertion = 0x16 // CTRL-V - "Video Insertion or Configurable Local Avail"
}
