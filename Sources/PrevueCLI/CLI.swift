//
//  CLI.swift
//  PrevueCLI
//
//  Created by Ari on 4/28/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

struct CLI {
    struct Command {
        let name: String
        let usage: String
        let minimumArgumentCount: Int
        
        let handler: ([String]) -> Void
    }
    
    let commands: [Command]
    let usagePreamble: String
    
    var helpCommand: Command {
        Command(name: "help", usage: ": Prints this help", minimumArgumentCount: 0, handler: { (arguments) in
            print(self.usagePreamble)
            
            for command in (self.commands + [self.helpCommand]) {
                print("    PrevueCLI \(command.name)\(command.usage)")
            }
        })
    }
    
    func command(named name: String) -> Command? {
        return commands.first { $0.name.lowercased() == name.lowercased() }
    }
    
    func command(for arguments: [String]) -> Command {
        if arguments.count > 1 {
            if let command = command(named: arguments[1]),
                (arguments.count - 2) >= command.minimumArgumentCount {
                return command
            }
        }
        
        return helpCommand
    }
    
    func runCommand(for arguments: [String]) {
        let command = self.command(for: arguments)
        
        let commandArguments = Array(arguments.dropFirst(2))
        command.handler(commandArguments)
    }
}
