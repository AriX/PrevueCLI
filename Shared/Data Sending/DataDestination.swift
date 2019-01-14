//
//  DataDestination.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

protocol DataDestination {
}

class NetworkDataDestination: DataDestination {
    var host: String
    var port: UInt16
    
    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }
}

class ClassicListenerDataDestination: NetworkDataDestination {
}

class FSUAEDataDestination: NetworkDataDestination {
}
