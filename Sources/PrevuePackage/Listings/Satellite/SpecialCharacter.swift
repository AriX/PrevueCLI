//
//  SpecialCharacter.swift
//  PrevueCLI
//
//  Created by Ari on 10/30/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

enum SpecialCharacter: Byte {
    case degrees = 0x5E // Temperature degrees symbol
    case closedCaptioned = 0x7C // Close Captioned symbol
    case rightTriangle = 0x80
    case upsideDownTriangle = 0x81
    case rightDoubleTriangle = 0x82
    case upsideDownRightDoubleTriangle = 0x83
    case ratingR = 0x84 // Restricted movie symbol
    case ratingPG = 0x85 // Parental Guidance movie symbol
    case ratingAdult = 0x86 // Adult movie symbol
    case ratingPG13 = 0x87 // Parental Guidance 13 movie symbol
    case leftTriangle = 0x88
    case ratingNR = 0x8C // Not Rated movie symbol
    case ratingG = 0x8D // General Admission movie symbol
    case vcrPlus = 0x8E
    case ratingNC17 = 0x8F //  No Child under 17 movie symbol
    case ratingTVY = 0x90
    case stereo = 0x91 // In Stereo symbol
    case disneyLogo = 0x92
    case ratingTVY7 = 0x93 // Previously, in 7.8.3, this was a 'premiere' symbol: "1st run Syndicated program (non-rerun)"
    case rating16ANS = 0x94
    case hboLogo = 0x95
    case rating18ANS = 0x96
    case rating13ANS = 0x97
    case cinemaxLogo = 0x98
    case ratingTVG = 0x99
    case ratingTV14 = 0x9A
    case ratingTVPG = 0x9B
    case wowLogo = 0x9C
    case ratingGTOUS = 0x9D
    case prevueLogo = 0x9E
    case specialOffer = 0x9F
    case ratingTVM = 0xA1
    case ratingTVMA = 0xA3
}

extension SpecialCharacter {
    static var closedCaptionedSting = "(CC)"
    static var stereoString = "In Stereo"
    static var ratingRString = "(R)"
    static var ratingAdultString = "(Adult)"
    static var ratingPGString = "(PG)"
    static var ratingNRString = "(NR)"
    static var ratingPG13String = "(PG-13)"
    static var ratingGString = "(G)"
    static var ratingNC17String = "(NC-17)"
    
    // TV ratings are available in Prevue 9.0.4, not 7.8.3
    static var ratingTVYString = "(TV-Y)"
    static var ratingTVY7String = "(TV-Y7)"
    static var ratingTVPGString = "(TV-PG)"
    static var ratingTVGString = "(TV-G)"
    static var ratingTVMString = "(TV-M)"
    static var ratingTVMAString = "(TV-MA)"
    static var ratingTV14String = "(TV-14)"
    
    var asString: String? {
        switch self {
        case .closedCaptioned: return SpecialCharacter.closedCaptionedSting
        case .stereo: return SpecialCharacter.stereoString
        case .ratingR: return SpecialCharacter.ratingRString
        case .ratingAdult: return SpecialCharacter.ratingAdultString
        case .ratingPG: return SpecialCharacter.ratingPGString
        case .ratingNR: return SpecialCharacter.ratingNRString
        case .ratingPG13: return SpecialCharacter.ratingPG13String
        case .ratingG: return SpecialCharacter.ratingGString
        case .ratingNC17: return SpecialCharacter.ratingNC17String
        case .ratingTVY: return SpecialCharacter.ratingTVYString
        case .ratingTVY7: return SpecialCharacter.ratingTVY7String
        case .ratingTV14: return SpecialCharacter.ratingTV14String
        case .ratingTVMA: return SpecialCharacter.ratingTVMAString
        case .ratingTVM: return SpecialCharacter.ratingTVMString
        case .ratingTVPG: return SpecialCharacter.ratingTVPGString
        case .ratingTVG: return SpecialCharacter.ratingTVGString
        default: return nil
        }
    }
}
