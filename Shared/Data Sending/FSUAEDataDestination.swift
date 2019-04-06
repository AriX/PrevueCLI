//
//  FSUAEDataDestination.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation
import Network

class FSUAEDataDestination: NetworkDataDestination {
    var connection: NWConnection?
    func openConnection() {
        if connection == nil {
            let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port))
            let connection = NWConnection(to: endpoint, using: .tcp)
            connection.start(queue: .global())
            self.connection = connection
        }
    }
    func closeConnection() {
        connection = nil
    }
    override func send(_ bytes: Bytes) {
        guard let connection = connection else {
            print("[FSUAEDataDestination] Tried to send bytes with no open connection")
            return
        }
        
        super.send(bytes)
        
        let semaphore = DispatchSemaphore(value: 0)
        
        connection.send(content: Data(bytes), completion: .contentProcessed({ (error) in
            print("Sent packet with error \(String(describing: error))")
            semaphore.signal()
        }))
        // TODO: rate limiting
        
        semaphore.wait()
    }
}
