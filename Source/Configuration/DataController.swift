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
        
        for destination in dataDestinations {
            if let serialDestination = destination as? SerialPortDataDestination {
                serialDestination.startTimer()
            }
            
            destination.openConnection()
        }
    }
    
    convenience init() {
#if os(Windows) || os(Linux)
        let destination = TCPDataDestination(host: "127.0.0.1", port: 5542)
#else
        let destination = SerialPortDataDestination(path: "/dev/cu.usbserial-14210")
#endif
        self.init(dataDestinations: [destination])
    }
    
    func send(control commands: [ControlCommand]) {
        for dataDestination in dataDestinations {
            dataDestination.send(control: commands)
        }
    }
    
    func sendBlastoff() {
        // do things?
    }
}
