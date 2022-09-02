//
//  SendLogos.swift
//  PrevuePackage
//
//  Created by Ari on 4/16/22.
//  Copyright © 2022 Vertex. All rights reserved.
//

import Foundation

// Find a way to delete logo files before uploading logo files so we don't run out of disk space.
// Add system to send logos from PrevueApp
// Test on 7.8.3/9.0.4

struct Logo: BinaryCodableStruct {
    let localFilePath: String
    let filename: String
}

struct SendLogos: MetaCommand {
    let logos: [Logo]
    let logoListDriveName: String?
    let imageDriveName: String?
    
    var commands: [DataCommand] {
        let logoListDriveName = self.logoListDriveName ?? "DF0"
        let imageDriveName = self.imageDriveName ?? "DF0"
        
        let offOnCommands: [DataCommand] = [BoxOffCommand(), BoxOnCommand(selectCode: "*")]
        
        let logoList = LogoList(logoFilenames: logos.map({ "Logo-\($0.filename)" }))
        let logoListPath = "\(logoListDriveName):LOGO.LST"
        let sendLogoListCommands = DownloadCommand.commandsToTransferFile(filePath: logoListPath, contents: logoList.bytes)
        
        let sendLogoCommands = logos.flatMap { logo -> [DataCommand] in
            let logoPath = "\(imageDriveName):Logo-\(logo.filename)"
            return SendFileCommand(localFilePath: logo.localFilePath, remoteFilePath: logoPath).commands + offOnCommands
        }
        
        let reloadCommand = UtilityCommand(mode: .reloadLogoListFile)
        
        var commands: [DataCommand] = []
        commands += offOnCommands
        commands += [UtilityRunShellCommand(command: "delete df0:Logo#? all")]
        commands += sendLogoCommands
        commands += offOnCommands
        commands += sendLogoListCommands
        commands += [reloadCommand]
        return commands
    }
}
