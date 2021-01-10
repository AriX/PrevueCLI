//
//  SerialInterface.swift
//  PrevueApp
//
//  Created by Ari on 1/10/21.
//  Copyright © 2021 Vertex. All rights reserved.
//

import Foundation

/**
 A protocol describing an object which can receive and originate serial data.
 */
protocol SerialInterface: DataDestination {
    func receive(byteCount: Int) -> Bytes?
}

/**
 A base protocol for file descriptor-based data origins.
 */
protocol FileDescriptorSerialInterface: SerialInterface {
    var fileDescriptor: CInt? { get }
}
