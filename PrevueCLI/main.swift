//
//  main.swift
//  PrevueCLI
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation

let destination = FSUAEDataDestination(host: "127.0.0.1", port: 5542)
destination.openConnection()

destination.send(BoxOnCommand(selectCode: "*"))

// Configuration test
//let command2 = ConfigurationCommand(timeslotsBack: 1, timeslotsForward: 8, scrollSpeed: 2, maxAdCount: 36, maxAdLines: 8, unknown: false, unknownAdSetting: 0x0103, timezone: 6, observesDaylightSavingsTime: true, cont: true, keyboardActive: true, unknown2: false, unknown3: false, unknown4: false, unknown5: false, grph: 0x4E, videoInput: 0x58, unknown6: 0x58)

// Download test
//var bytes: Bytes = []
//for _ in stride(from: 0, to: 256, by: 1) {
//    bytes.append(0x30)
//}
//let downloadCommands = DownloadCommand.commandsToTransferFile(filePath: "DF0:saladworks2.fun", contents: bytes)
//destination.send(downloadCommands)
//destination.send(BoxOffCommand())

// Config.dat test
//destination.send(ConfigDatCommand(clockCmd: 2).encodeWithChecksum())

destination.send(BoxOffCommand())

destination.closeConnection()
