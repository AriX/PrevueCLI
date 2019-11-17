//
//  DataController.swift
//  PrevueFramework
//
//  Created by Ari on 11/16/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation

// have some kind of serializable config for machines?

class DataController {
    let dataDestinations: [DataDestination]
    
    init(dataDestinations: [DataDestination]) {
        self.dataDestinations = dataDestinations
    }
    
    convenience init() {
        let destination = FSUAEDataDestination(host: "127.0.0.1", port: 5542)
        destination.openConnection()
        destination.send(data: BoxOnCommand(selectCode: "*"))
        self.init(dataDestinations: [destination])
    }
    
    func send(control command: UVSGEncodable) {
        for dataDestination in dataDestinations {
            dataDestination.send(control: command.encodeWithChecksum())
        }
    }
    
    func sendBlastoff() {
        // do things?
    }
}
