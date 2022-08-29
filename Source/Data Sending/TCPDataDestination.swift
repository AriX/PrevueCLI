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
    
    override func openConnection() throws {
        if sender == nil {
            sender = host.withCString { UVSGSerialDataSenderCreate($0, port) }
            if sender == nil {
                print("[TCPDataDestination] Failed to open connection")
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
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
    }
    
    override func send(control bytes: Bytes) {
        for byte in bytes {
            sendDebugCTRLByte(byte: byte)
        }
    }
}

#if !os(Windows)
extension TCPDataDestination: FileDescriptorSerialInterface {
    func receive(byteCount: Int) -> Bytes? {
        guard let fileDescriptor = fileDescriptor else {
            print("[TCPDataDestination] Tried to receive bytes with no open connection")
            return nil
        }
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: byteCount)
        defer {
            buffer.deallocate()
        }

        let bytesRead = recv(fileDescriptor, buffer, byteCount, 0)

        guard bytesRead >= 0 else {
            return nil
        }
        
        return Bytes(UnsafeMutableBufferPointer(start: buffer, count: bytesRead))
    }
    
    var fileDescriptor: CInt? {
        guard let sender = sender else { return nil }
        return UVSGSerialDataSenderGetSocket(sender)
    }
}
#endif
