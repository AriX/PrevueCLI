//
//  main.swift
//  PrevueCLI
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation

//let command = TitleCommand(title: "        Electronic Program Guide")
//let data = command.encodeWithChecksum()

let command1 = BoxOnCommand(selectCode: "*")
let command2 = ConfigurationCommand(timeslotsBack: 1, timeslotsForward: 8, scrollSpeed: 2, maxAdCount: 36, maxAdLines: 8, unknown: false, unknownAdSetting: 0x0103, timezone: 6, observesDaylightSavingsTime: true, cont: true, keyboardActive: false, unknown2: false, unknown3: false, unknown4: false, unknown5: false, grph: 0x4E, videoInput: 0x58, unknown6: 0x58)

print(command2.encodeWithChecksum().hexEncodedString())

let dataDestination = FSUAEDataDestination(host: "127.0.0.1", port: 5542)
dataDestination.send(bytes: command1.encodeWithChecksum())
dataDestination.send(bytes: command2.encodeWithChecksum())

RunLoop.current.run()
