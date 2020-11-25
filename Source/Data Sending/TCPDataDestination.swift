//
//  TCPDataDestination.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation
import UVSGSerialData

class TCPDataDestination: NetworkDataDestination {
    var sender: OpaquePointer?
    
    override func openConnection() {
        if sender == nil {
            sender = host.withCString { UVSGSerialDataSenderCreate($0, port) }
            if sender == nil {
                print("[TCPDataDestination] Failed to open connection")
            }
        }
    }
    
    override func closeConnection() {
        if sender != nil {
            UVSGSerialDataSenderFree(sender)
            sender = nil
        }
    }
    
    deinit {
        closeConnection()
    }
    
    override func send(data bytes: Bytes) {
        guard let sender = sender else {
            print("[TCPDataDestination] Tried to send bytes with no open connection")
            return
        }
        
        super.send(data: bytes)
        
        let success = Data(bytes).withUnsafeBytes { UVSGSerialDataSenderSendData(sender, $0.baseAddress, bytes.count) }
        if !success {
            print("Failed to send packet of size \(bytes.count)")
        }
        
        delayForSendingBytes(byteCount: bytes.count, baudRate: 2400)
    }
    
    override func send(control bytes: Bytes) {
        for byte in bytes {
            sendDebugCTRLByte(byte: byte)
        }
    }
}
