//
//  SerialPortDataDestination.swift
//  PrevueApp
//
//  Created by Ari on 4/27/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation
import Dispatch

#if !os(Windows) && !os(Linux)
class SerialPortDataDestination: DataDestination {
    let path: String
    let baudRate: speed_t
    var handle: CInt?
    
    enum CodingKeys: CodingKey {
        case path
        case baudRate
    }
    
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
        
        delayForSendingBytes(byteCount: bytes.count, baudRate: Int(baudRate))
    }
    
    var ctrlBitBuffer: [Bool] = []
    var ctrlSending: Bool = false
    let ctrlQueue = DispatchQueue(label: "CTRL data", qos: .userInteractive, attributes: .concurrent)
    lazy var ctrlTimer = DispatchSource.makeTimerSource(flags: .strict, queue: ctrlQueue)
    
    func startTimer() {
        let duration = durationToSendBit(baudRate: 110)
        let nanosecondDuration = Int(round(duration.nanoseconds))
        ctrlTimer.schedule(deadline: .now(), repeating: .nanoseconds(nanosecondDuration), leeway: .nanoseconds(0))
        
        ctrlTimer.setEventHandler(handler: sendCTRLBitFromBuffer)
        ctrlTimer.resume()
    }
    
    func sendCTRLBitFromBuffer() {
        guard let bit = ctrlBitBuffer.first else {
            if ctrlSending {
                ctrlSending = false
                print("[CTRL] Exhausted buffer")
            }
            
            return
        }
        
        if !ctrlSending {
            print("[CTRL] Start sending")
            ctrlSending = true
        }
        
        setRTS(bit)
        
        ctrlBitBuffer.removeFirst()
    }

    func stopTimer() {
        ctrlTimer.cancel()
    }
    
    func setRTS(_ up: Bool) {
        guard let handle = handle else {
            print("[SerialPortDataDestination] Tried to set RTS with no open handle")
            return
        }
        
        var status: Int32 = 0
        _ = ioctl(handle, TIOCMGET, &status)
        
        var updatedStatus = status
        if up {
            updatedStatus |= TIOCM_RTS
        } else {
            updatedStatus &= ~TIOCM_RTS
        }
        
        if status != updatedStatus {
            _ = ioctl(handle, TIOCMSET, &updatedStatus)
        }
    }
    
    func sendCTRLByte(_ byte: Byte) {
        let bits = byte.asBits.reversed().map { $0 == .zero }
        
        ctrlBitBuffer.append(false) // stop
        ctrlBitBuffer.append(true) // start
        ctrlBitBuffer.append(contentsOf: bits)
        ctrlBitBuffer.append(false) // stop
        ctrlBitBuffer.append(false) // stop
        ctrlBitBuffer.append(false) // stop
        ctrlBitBuffer.append(false) // stop
        
        // TODO: Do we really need this many stop bits?
    }
    
    func send(control bytes: Bytes) {
        ctrlQueue.sync {
            for byte in bytes {
                sendCTRLByte(byte)
            }
        }
    }
}
#endif
