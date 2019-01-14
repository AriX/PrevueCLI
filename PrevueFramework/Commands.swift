//
//  Commands.swift
//  PrevueFramework
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

public protocol DataCommand {
    var commandMode: DataCommandMode { get }
}

public struct BoxOnCommand: DataCommand {
    public let commandMode = DataCommandMode.boxOn
    public var selectCode: String
}

public struct TitleCommand: DataCommand {
    public let commandMode = DataCommandMode.title
    public var title: String
}

public struct ResetCommand: DataCommand {
    public let commandMode = DataCommandMode.reset
}

public struct BoxOffCommand: DataCommand {
    public let commandMode = DataCommandMode.boxOff
}

