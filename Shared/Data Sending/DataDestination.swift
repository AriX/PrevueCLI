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
// TODO: Should there instead be a single protocol for converting things into bytes, and this takes those?
extension DataDestination {
    func send(data command: UVSGCommand) {
        let commandType = type(of: command)
        let bytes = command.encodedWithChecksum
        print("Sending \(commandType) in \(bytes.count) \(bytes.count == 1 ? "byte" : "bytes"): \(bytes.hexEncodedString())")
        send(data: bytes)
    }
    func send(data commands: [UVSGCommand]) {
        var i = 0
        for command in commands {
            if commands.count > 1 {
                print("Sending \(i) of \(commands.count)")
            }
            send(data: command)
            i += 1
        }
    }
    func send(control command: UVSGCommand) {
        send(control: command.encodedWithChecksum)
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
    // Call this after sending data to rate limit sending to a particular baud rate
    func limitSendingRate(byteCount: Int, baudRate: Int) {
        // e.g. for 2400 baud, assume we're sending 240 bytes per second, with 1,000 miliseconds in a second
        // For unknown reasons, this seems to be too fast (for the Atari emulator) until I apply a factor of 4 or 5
        let timeToWait = (Double(byteCount) * 10.0) * (1 / Double(baudRate)) * 1000.0 * 4.5
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
