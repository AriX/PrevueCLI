//
//  SerialPortDataDestination.swift
//  PrevueApp
//
//  Created by Ari on 4/27/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation

#if !os(Windows) && !os(Linux)
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
    func send(data bytes: Bytes) {
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
        
        write(handle, buffer.baseAddress, size)
        
//        let timeToSend = (Double(bytes.count)/1.5)*1000.0*2
//        usleep(UInt32(timeToSend))
        // TODO: Is this potentially unnecessarily slow?
        limitSendingRate(byteCount: bytes.count, baudRate: Int(baudRate))
    }
    let delay: useconds_t = 830
    func setRTS(_ up: Bool) {
        guard let handle = handle else {
            print("[SerialPortDataDestination] Tried to set RTS with no open handle")
            return
        }
        
        var status: Int32 = 0
        let statusPointer = UnsafeMutableRawPointer(&status)
        
        _ = ioctl(handle, TIOCMGET, statusPointer);
        
        if up {
            status |= TIOCM_RTS;
        } else {
            status &= ~TIOCM_RTS;
        }
        print("Setting status to \(status)")
        
        _ = ioctl(handle, TIOCMSET, statusPointer);
        
        usleep(delay);
    }
    func sendCTRLGroup(_ r: Bool, _ s: Bool) {
        for _ in 1...4 {
            setRTS(r);
        }
        for _ in 1...4 {
            setRTS(s);
        }
    }
    func sendCTRLByte(byt: Byte) {
        setRTS(true); setRTS(true); setRTS(true);
        sendCTRLGroup(true, !((byt&1)>0)); // start
        sendCTRLGroup(!((byt&1)>0), !((byt&2)>0)); // data
        sendCTRLGroup(!((byt&2)>0), !((byt&4)>0)); // data
        sendCTRLGroup(!((byt&4)>0), !((byt&8)>0)); // data
        sendCTRLGroup(!((byt&8)>0), !((byt&16)>0)); // data
        sendCTRLGroup(!((byt&16)>0), !((byt&32)>0)); // data
        sendCTRLGroup(!((byt&32)>0), !((byt&64)>0)); // data
        sendCTRLGroup(!((byt&64)>0), !((byt&128)>0)); // data
        sendCTRLGroup(!((byt&128)>0), false); // data
        sendCTRLGroup(false, false); // stop
    }
    func send(control bytes: Bytes) {
        for byte in bytes {
            sendCTRLByte(byt: byte)
        }
    }
}
#endif
