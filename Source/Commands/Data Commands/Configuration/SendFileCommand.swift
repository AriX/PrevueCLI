//
//  SendFileCommand.swift
//  PrevuePackage
//
//  Created by Ari on 9/10/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

struct SendFileCommand: MetaCommand {
    let localFilePath: String
    let remoteFilePath: String
    
    var commands: [DataCommand] {
        let fileData = try! Data(contentsOf: URL(fileURLWithPath: localFilePath))
        return DownloadCommand.commandsToTransferFile(filePath: remoteFilePath, contents: Bytes(fileData))
    }
}
