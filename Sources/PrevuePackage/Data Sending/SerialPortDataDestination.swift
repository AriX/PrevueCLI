//
//  SerialPortDataDestination.swift
//  PrevueApp
//
//  Created by Ari on 4/27/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

import Foundation
import Dispatch
import UVSGSerialData

#if !os(Linux)
class SerialPortDataDestination: DataDestination {
    let path: String
    let baudRate: UInt
    var supportsRTSBitBanging: Bool = true
    #if os(Windows)
    var handle: OpaquePointer?
    #else
    var handle: CInt?
    #endif
    
    enum CodingKeys: CodingKey {
        case path
        case baudRate
    }
    
    init(path: String, baudRate: UInt = 2400, supportsRTSBitBanging: Bool) {
        self.path = path
        self.baudRate = baudRate
        self.supportsRTSBitBanging = supportsRTSBitBanging
    }
    
    func openConnection() throws {
        guard self.handle == nil else { return }
        
        #if os(Windows)
        handle = path.withCString { UVSGSerialPortIOClientCreate($0, UInt32(baudRate)) }
        if handle == nil {
            print("[SerialPortDataDestination] Failed to open \(path)")
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        #else
        let handle = open(path, O_RDWR | O_NOCTTY | O_NONBLOCK)
        if handle == -1 {
            print("[SerialPortDataDestination] Failed to open \(path)")
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
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
        #endif
    }
    
    func closeConnection() {
        if let handle = handle {
            #if os(Windows)
            UVSGSerialPortIOClientFree(handle)
            #else
            close(handle)
            #endif
        }
        handle = nil
    }
    
    // MARK: - Sending data
    
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
        
        #if os(Windows)
        UVSGSerialPortIOClientSendData(handle, buffer.baseAddress, size)
        #else
        write(handle, buffer.baseAddress, size)
        #endif
    }
    
    // MARK: - CTRL
    
    var ctrlBitBuffer: [Bool] = []
    var ctrlSending: Bool = false
    let ctrlQueue = DispatchQueue(label: "CTRL data", qos: .userInteractive, attributes: .concurrent)
    lazy var ctrlTimer = DispatchSource.makeTimerSource(flags: .strict, queue: ctrlQueue)
    
    func startTimer() {
        let duration = Bytes.durationToSendBit(atBaudRate: 110)
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
        
        // TODO: Support RTS bit-banging on Windows
        #if !os(Windows)
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
        #endif
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

#if !os(Windows)
// TODO: Support receiving serial data on Windows
extension SerialPortDataDestination: FileDescriptorSerialInterface {
    func receive(byteCount: Int) -> Bytes? {
        guard let handle = handle else {
            print("[SerialPortDataDestination] Tried to receive bytes with no open handle")
            return nil
        }
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: byteCount)
        defer {
            buffer.deallocate()
        }

        let bytesRead = read(handle, buffer, byteCount)

        guard bytesRead >= 0 else {
            return nil
        }
        
        return Bytes(UnsafeMutableBufferPointer(start: buffer, count: bytesRead))
    }
    
    var fileDescriptor: CInt? {
        return handle
    }
}
#endif

extension SerialPortDataDestination: CustomStringConvertible {
    var description: String {
        "SerialPortDataDestination(path: \(path), baudRate: \(baudRate), supportsRTSBitBanging: \(supportsRTSBitBanging), handle: \(String(describing: handle))"
    }
}

#endif
