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
protocol DataDestination: Codable {
    func send(data bytes: Bytes)
    func send(control bytes: Bytes)
    
    func openConnection()
    func closeConnection()
}

/**
 Support sending UVSGCommand commands to a data destination.
 */
extension DataDestination {
    func send(data command: SatelliteCommand) {
        do {
            let bytes = try BinaryEncoder.encode(SerializedCommand(command: command))
            
            let commandType = type(of: command)
            print("Sending \(commandType) in \(bytes.count) \(bytes.count == 1 ? "byte" : "bytes"): \(bytes.hexEncodedString())")
            send(data: bytes)
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
    func send(control command: ControlCommand) {
        do {
            let encodedCommand = try BinaryEncoder.encode(SerializedCommand(command: command))
            send(control: encodedCommand)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

class NetworkDataDestination: DataDestination {
    var host: String
    var port: Int32
    
    init(host: String, port: Int32) {
        self.host = host
        self.port = port
    }
    
    func send(data bytes: Bytes) {
    }
    
    func send(control bytes: Bytes) {
        // Unimplemented
    }
    
    func openConnection() {
        // Unimplemented
    }
    
    func closeConnection() {
        // Unimplemented
    }
}

#if os(Windows)
import WinSDK
#endif

extension DataDestination {
    func durationToSendBit(baudRate: Int) -> TimeInterval {
        return (1 / Double(baudRate))
    }
    
    func durationToSendBytes(byteCount: Int, at baudRate: Int, startBits: Int = 1, stopBits: Int = 1) -> TimeInterval {
        let bytes = Double(byteCount)
        let bitsPerByte = Double(8 + startBits + stopBits)
        let durationPerBit = durationToSendBit(baudRate: baudRate)
        
        return (bytes * bitsPerByte * durationPerBit)
    }
    
    // Call this after sending data to rate limit sending to a particular baud rate
    func delayForSendingBytes(byteCount: Int, baudRate: Int) {
        // For unknown reasons, this seems to be too fast (for the Atari emulator) until I apply a factor of 4 or 5
        let timeToWait = durationToSendBytes(byteCount: byteCount, at: baudRate).miliseconds
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
}
