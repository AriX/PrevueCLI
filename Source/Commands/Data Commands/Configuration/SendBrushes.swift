//
//  SendBrushes.swift
//  PrevueCLI
//
//  Created by Ari on 12/12/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

struct Brush: BinaryCodableStruct {
    let localFilePath: String
    let filename: String
    let id: String
}

struct SendBrushes: MetaCommand {
    let brushes: [Brush]
    let driveName: String?
    
    var commands: [DataCommand] {
        let driveName = self.driveName ?? "DF0"
        
        let offOnCommands: [DataCommand] = [BoxOffCommand(), BoxOnCommand(selectCode: "*")]
        
        let brushINI = INIFile(sections: [
            INIFile.Section(name: "BACKDROP", items: brushes.map {
                [INIFile.Section.Entry(key: "filename", value: "\(driveName):Brush-\($0.filename)"),
                 INIFile.Section.Entry(key: "id", value: $0.id)]
            })
        ]) 
        let brushINIPath = "\(driveName):BRUSH.INI"
        let sendBushINICommands = DownloadCommand.commandsToTransferFile(filePath: brushINIPath, contents: brushINI.bytes)
        
        let sendBrushCommands = brushes.flatMap { brush -> [DataCommand] in
            let brushPath = "\(driveName):Brush-\(brush.filename)"
            return SendFileCommand(localFilePath: brush.localFilePath, remoteFilePath: brushPath).commands + offOnCommands
        }
        
        let reloadCommand = UtilityCommand(mode: .reloadLogoListFile)
        
        var commands: [DataCommand] = []
        commands += offOnCommands
        commands += [UtilityRunShellCommand(command: "delete df0:Brush#? all")]
        commands += sendBrushCommands
        commands += offOnCommands
        commands += sendBushINICommands
        commands += [reloadCommand]
        return commands
    }
}
