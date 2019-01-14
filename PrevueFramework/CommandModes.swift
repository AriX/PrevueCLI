//
//  UVSGCommandMode.swift
//  PrevueFramework
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

// This is a subset of the command modes discussed here: http://prevueguide.com/wiki/UVSG_Satellite_Data#Command_Modes

public enum DataCommandMode: Character {
    case boxOn = "A"
    case channel = "C"
    case newChannel = "c"
    case configuration = "F"
    case configDat = "f"
    case dst = "g"
    case download = "H"
    case ppvOrderInfo = "J"
    case newPPVOverInfo = "j"
    case clock = "K"
    case ad = "L"
    case clearListing = "O"
    case program = "P"
    case newProgram = "p"
    case reset = "R"
    case title = "T"
    case saveData = "%"
    case boxOff = "\u{BB}"
}
