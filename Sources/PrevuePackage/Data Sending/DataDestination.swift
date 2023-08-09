//
//  DataDestination.swift
//  PrevuePackage
//
//  Created by Ari on 11/18/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation

/**
 A protocol describing an object which can receive data.
 */
public protocol DataDestination: Codable {
    func send(data bytes: Bytes)
    func send(control bytes: Bytes)
    
    func openConnection() throws
    func closeConnection()
    
    var baudRate: UInt { get }
}

/**
 Support sending UVSGCommand commands to data destinations.
 */
extension Array where Element == DataDestination {
    func send(data command: SatelliteCommand) {
        do {
            let bytes = try BinaryEncoder.encode(SerializedCommand(command: command))
            
            let commandType = type(of: command)
            print("Sending \(commandType) in \(bytes.count) \(bytes.count == 1 ? "byte" : "bytes"): \(bytes.hexEncodedString())")
            for destination in self {
                destination.send(data: bytes)
            }
            let slowestBaudRate = map(\.baudRate).min() ?? 2400
            bytes.delayForSending(at: slowestBaudRate)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    func send(data commands: [SatelliteCommand]) {
        var i = 0
        for command in commands {
            if commands.count > 1 {
                print("Sending \(i) of \(commands.count)")
            }
            send(data: command)
            i += 1
        }
    }
}

extension DataDestination {
    func send(data command: SatelliteCommand) {
        [self].send(data: command)
    }
    func send(data commands: [SatelliteCommand]) {
        [self].send(data: commands)
    }
    func send(control commands: [ControlCommand]) {
        do {
            let encodedCommands = try commands.flatMap { (command) -> Bytes in
                let bytes = try BinaryEncoder.encode(SerializedCommand(command: command))
                let commandType = type(of: command)
                print("Sending CTRL \(commandType) in \(bytes.count) \(bytes.count == 1 ? "byte" : "bytes"): \(bytes.hexEncodedString())")
                return bytes
            }
            send(control: encodedCommands)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

class NetworkDataDestination: DataDestination {
    var host: String
    var port: Int32
    var baudRate: UInt { 2400 }
    
    init(host: String, port: Int32) {
        self.host = host
        self.port = port
    }
    
    func send(data bytes: Bytes) {
    }
    
    func send(control bytes: Bytes) {
        // Unimplemented
    }
    
    func openConnection() throws {
        // Unimplemented
    }
    
    func closeConnection() {
        // Unimplemented
    }
}

#if os(Windows)
import WinSDK
#endif

extension Array where Element == Byte {
    static func durationToSendBit(atBaudRate baudRate: UInt) -> TimeInterval {
        return (1 / Double(baudRate))
    }
    
    func durationToSendBytes(byteCount: Int, at baudRate: UInt, startBits: Int = 1, stopBits: Int = 1) -> TimeInterval {
        let bytes = Double(byteCount)
        let bitsPerByte = Double(8 + startBits + stopBits)
        let durationPerBit = Self.durationToSendBit(atBaudRate: baudRate)
        
        return (bytes * bitsPerByte * durationPerBit)
    }
    
    // Call this after sending data to rate limit sending to a particular baud rate
    func delayForSending(at baudRate: UInt) {
        // For unknown reasons, this seems to be too fast (for the Atari emulator) until I apply a factor of 4 or 5
        let timeToWait = durationToSendBytes(byteCount: count, at: baudRate).miliseconds
        sleep(miliseconds: timeToWait)
    }
    
    func sleep(miliseconds: Double) {
        #if os(Windows)
        Sleep(UInt32(miliseconds))
        #else
        let microseconds = miliseconds * 1000.0
        usleep(UInt32(microseconds))
        #endif
    }
}

extension TimeInterval {
    var miliseconds: Double {
        return (self * 1000.0)
    }
    var microseconds: Double {
        return (miliseconds * 1000.0)
    }
    var nanoseconds: Double {
        return (microseconds * 1000.0)
    }
}
