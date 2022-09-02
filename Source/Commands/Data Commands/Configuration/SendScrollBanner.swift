//
//  SendScrollBanner.swift
//  PrevuePackage
//
//  Created by Ari on 4/16/22.
//  Copyright © 2022 Vertex. All rights reserved.
//

import Foundation

struct SendScrollBanner: MetaCommand {
    let scrollBannerPath: String
    let sendBannerINI: Bool?
    let driveName: String?
    
    var commands: [DataCommand] {
        let writableDriveName = driveName ?? "DF0"
        let sendBannerINI = self.sendBannerINI ?? true
        
        let bannerFilename = "pgwawo.160"
        let filePath = "\(writableDriveName):\(bannerFilename)"
        let sendBannerCommands = SendFileCommand(localFilePath: scrollBannerPath, remoteFilePath: filePath).commands
        
        let reloadCommand = UtilityCommand(mode: .reloadScrollBanner)
        
        if sendBannerINI {
            let offOnCommands: [DataCommand] = [BoxOffCommand(), BoxOnCommand(selectCode: "*")]
            
            let bannerINI = INIFile(sections: [
                INIFile.Section(name: "BANNER", items: [[INIFile.Section.Entry(key: "FILENAME", value: filePath)]])
            ])
            let bannerINIPath = "\(writableDriveName):BANNER.INI"
            let sendBannerINICommands = DownloadCommand.commandsToTransferFile(filePath: bannerINIPath, contents: bannerINI.bytes)
            
            var commands: [DataCommand] = []
            commands += offOnCommands
            commands += [UtilityRunShellCommand(command: "delete df0:Banner#? all")]
            commands += sendBannerCommands
            commands += offOnCommands
            commands += sendBannerINICommands
            commands += [reloadCommand]
            return commands
            
        } else {
            return sendBannerCommands + [reloadCommand]
        }
    }
}
