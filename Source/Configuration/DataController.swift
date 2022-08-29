//
//  DataController.swift
//  PrevueFramework
//
//  Created by Ari on 11/16/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation

class DataController {
    var dataDestinations: [DataDestination]
    
    init(dataDestinations: [DataDestination]) {
        self.dataDestinations = dataDestinations
    }
    
    convenience init() {
        self.init(dataDestinations: [])
    }
    
    func send(control commands: [ControlCommand]) {
        for dataDestination in dataDestinations {
            dataDestination.send(control: commands)
        }
    }
    
    func send(data commands: [Command]) {
        for command in commands {
            dataDestinations.send(data: command.satelliteCommands)
        }
    }
    
    func connect() throws {
        for destination in dataDestinations {
            try destination.openConnection()
            
#if !os(Windows) && !os(Linux)
            if let serialDestination = destination as? SerialPortDataDestination {
                if serialDestination.supportsRTSBitBanging {
                    // For CTRL
                    serialDestination.startTimer()
                } else {
                    // To switch Atari SIO2PC adapter into data mode
                    serialDestination.setRTS(false)
                }
            }
#endif
        }
    }
}
