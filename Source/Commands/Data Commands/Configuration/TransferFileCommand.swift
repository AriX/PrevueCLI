//
//  TransferFileCommand.swift
//  PrevuePackage
//
//  Created by Ari on 9/10/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

struct TransferFileCommand: MetaCommand {
    let localFilePath: String
    let remoteFilePath: String
    
    var commands: [DataCommand] {
        let fileData = try! Data(contentsOf: URL(fileURLWithPath: localFilePath))
        let fileBytes = [UInt8](fileData)
        return DownloadCommand.commandsToTransferFile(filePath: remoteFilePath, contents: fileBytes)
    }
}
