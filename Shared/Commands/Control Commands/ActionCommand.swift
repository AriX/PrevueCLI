//
//  ActionCommand.swift
//  PrevueCLI
//
//  Created by Ari on 11/12/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

enum ActionCommandTransitionType: Character {
    case null = "0"
    case fade = "1"
    case paint = "2" // is this a thing?
    case pullUp = "3" // unimplemented?
    case slide = "4" // unimplemented?
    case unknown = "5" // what's this?
}

enum ActionCommandValue {
    case quarterScreenPreview(SourceIdentifier, SourceIdentifier) // ^A1, provide left and right source identifiers
    case halfScreenNationalAd // ^A3
    case halfScreenSourceConstrainedPreview(SourceIdentifier) // ^A4, ^A6
    case quarterScreenTrigger(ActionCommandTransitionType, ActionCommandTransitionType) // ^A7, "Two source preview trigger" "Similar to ^A1 but without src. Used for multiple tags" - what is this?
    case halfScreenPromoWithTextOverlay // ^A8 - software says "Got Preview (1/2 Screen)", is this right? what's the format?
    case localAdOrQuarterScreenPreview(SourceIdentifier, SourceIdentifier) // ^L1, provide left and right source identifiers
    case localAdOrHalfScreenNationalAd // ^L3
}

struct ActionCommand: ControlCommand {
    let value: ActionCommandValue
    var commandMode: ControlCommandMode {
        switch value {
        case .localAdOrQuarterScreenPreview:
            fallthrough
        case .localAdOrHalfScreenNationalAd:
            return ControlCommandMode.actionLocalAvails
        default:
            return ControlCommandMode.action
        }
    }
}

extension ActionCommand {
    var payload: Bytes {
        switch value {
        case .quarterScreenPreview(let leftSourceIdentifier, let rightSourceIdentifier): // ^A1
            fallthrough
        case .localAdOrQuarterScreenPreview(let leftSourceIdentifier, let rightSourceIdentifier): // ^L1
            return ("1".asBytes() + ActionCommand.leftRightStringAsBytes(leftString: leftSourceIdentifier, rightString: rightSourceIdentifier))
        case .halfScreenNationalAd: // ^A3
            fallthrough
        case .localAdOrHalfScreenNationalAd: // ^L3
            return ("3".asBytes() + [Byte(0x0D)])
        case .halfScreenSourceConstrainedPreview(let sourceIdentifier): // ^A4
            return ("4".asBytes() + sourceIdentifier.asBytes() + [Byte(0x0D)])
        case .quarterScreenTrigger(let leftTransition, let rightTransition): // ^A7
            return ("7".asBytes() + [leftTransition.rawValue.asByte()] + [rightTransition.rawValue.asByte()] + [Byte(0x0D)])
        case .halfScreenPromoWithTextOverlay: // ^A8
            return ("8".asBytes() + [Byte(0x0D)]) // Untested, does this work?
        }
    }
}
