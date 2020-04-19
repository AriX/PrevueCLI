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
    func send(data bytes: Bytes)
    func send(control bytes: Bytes)
}

/**
 Support sending UVSGEncodable commands to a data destination.
 */
// TODO: Should there instead be a single protocol for converting things into bytes, and this takes those?
extension DataDestination {
    func send(data command: UVSGEncodable) {
        send(data: command.encodeWithChecksum())
    }
    func send(data commands: [UVSGEncodable]) {
        var i = 0
        for command in commands {
            print("Sending \(i) of \(commands.count)")
            send(data: command)
            i += 1
        }
    }
    func send(control command: UVSGEncodable) {
        send(control: command.encodeWithChecksum())
    }
}

class NetworkDataDestination: DataDestination {
    var host: String
    var port: UInt16
    
    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }
    
    func send(data bytes: Bytes) {
        print("Sending \(bytes.hexEncodedString())to \(self)")
    }
    
    func send(control bytes: Bytes) {
        // Unimplemented
    }
}

class ClassicListenerDataDestination: NetworkDataDestination {
    override func send(data bytes: Bytes) {
        // Unimplemented
        
        super.send(data: bytes)
    }
    
    override func send(control bytes: Bytes) {
        // Unimplemented
        
        super.send(control: bytes)
    }
}

