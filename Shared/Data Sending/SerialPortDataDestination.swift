//
//  SerialPortDataDestination.swift
//  PrevueApp
//
//  Created by Ari on 4/27/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation

class SerialPortDataDestination: DataDestination {
    let path: String
    let baudRate: speed_t
    var handle: CInt?
    
    init(path: String, baudRate: speed_t = 2400) {
        self.path = path
        self.baudRate = baudRate
    }
    func openConnection() {
        guard self.handle == nil else { return }
        
        let handle = open(path, O_RDWR | O_NOCTTY | O_NONBLOCK)
        if handle == -1 {
            print("[SerialPortDataDestination] Failed to open \(path)")
            return
        }
        
        _ = ioctl(handle, TIOCEXCL)
        _ = fcntl(handle, F_SETFL, 0)
        
        // Get options structure for the port
        var settings = termios()
        tcgetattr(handle, &settings)
        
        // Set baud rates
        cfsetispeed(&settings, baudRate)
        cfsetospeed(&settings, baudRate)
        
        // Commit settings
        tcsetattr(handle, TCSANOW, &settings)
        
        self.handle = handle
    }
    func closeConnection() {
        if let handle = handle {
            close(handle)
        }
        handle = nil
    }
    func send(_ bytes: Bytes) {
        guard let handle = handle else {
            print("[SerialPortDataDestination] Tried to send bytes with no open handle")
            return
        }
        
        let size = bytes.count
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: size, alignment: 1)
        defer {
            buffer.deallocate()
        }
        
        buffer.copyBytes(from: bytes)
        
        print("Sending \(bytes.hexEncodedString())to \(self)")
        write(handle, buffer.baseAddress, size)
    }
}
