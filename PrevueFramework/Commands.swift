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
    
    public init(selectCode: String) {
        self.selectCode = selectCode
    }
}

public struct TitleCommand: DataCommand {
    public let commandMode = DataCommandMode.title
    public var title: String
    
    public init(title: String) {
        self.title = title
    }
}

public struct ResetCommand: DataCommand {
    public let commandMode = DataCommandMode.reset
    
    public init() { }
}

public struct BoxOffCommand: DataCommand {
    public let commandMode = DataCommandMode.boxOff
    
    public init() { }
}

