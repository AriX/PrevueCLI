//
//  DataSending.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation
import Network

extension DataDestination {
    func send(bytes: Bytes) {
        print("Sending \(bytes.hexEncodedString())to \(self)")
    }
}

extension FSUAEDataDestination {
    func send(bytes: Bytes) {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port))
        let connection = NWConnection(to: endpoint, using: .tcp)
        connection.start(queue: .main)
        connection.send(content: Data(bytes), completion: .contentProcessed({ (error) in
            print("Sent packet to connection \(connection) with error \(String(describing: error))")
        }))
        // TODO: rate limiting
        
        super.send(bytes: bytes)
    }
}

extension ClassicListenerDataDestination {
    func send(bytes: Bytes) {
        // Unimplemented
        
        super.send(bytes: bytes)
    }
}
