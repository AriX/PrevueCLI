//
//  BoxCommands.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

struct BoxOnCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.boxOn
    let selectCode: String
}

struct BoxOffCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.boxOff
}

struct SaveDataCommand: DataCommand, Equatable {
    static let commandMode: DataCommandMode = .saveData
}

struct ResetCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.reset
}

struct VersionCommand: DataCommand, Equatable {
    static let commandMode: DataCommandMode = .version
    let versionString: String
}

// MARK: Encoding

extension BoxOffCommand {
    var footerBytes: Bytes {
        return [0xBB, 0x00]
    }
}

extension SaveDataCommand {
    var footerBytes: Bytes {
        return [0x00]
    }
}

extension ResetCommand {
    var footerBytes: Bytes {
        return [0x00]
    }
}

extension VersionCommand {
    static var headerBytes: Bytes {
        return [0x01]
    }
}
