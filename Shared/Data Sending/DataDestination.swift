//
//  DataDestination.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Network

/**
 A protocol describing an object which can receive data.
 */
protocol DataDestination {
    func send(_ bytes: Bytes)
}

/**
 Support sending UVSGEncodable commands to a data destination.
 */
// TODO: Should there instead be a single protocol for converting things into bytes, and this takes those?
extension DataDestination {
    func send(_ command: UVSGEncodable) {
        send(command.encodeWithChecksum())
    }
    func send(_ commands: [UVSGEncodable]) {
        for command in commands {
            send(command)
        }
    }
}

class NetworkDataDestination: DataDestination {
    var host: String
    var port: UInt16
    
    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }
    
    func send(_ bytes: Bytes) {
        print("Sending \(bytes.hexEncodedString())to \(self)")
    }
}

class ClassicListenerDataDestination: NetworkDataDestination {
    override func send(_ bytes: Bytes) {
        // Unimplemented
        
        super.send(bytes)
    }
}

