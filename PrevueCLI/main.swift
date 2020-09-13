//
//  main.swift
//  PrevueCLI
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation
#if os(Windows)
import Yams
#endif

let commands = [
    CLI.Command(name: "send", usage: " <.prevuecommand file>: Sends the commands in the specified .prevuecommand file", minimumArgumentCount: 1, handler: { (arguments) in
        do {
            let filePath = arguments[0]
            let commandFile = try PrevueCommandFile(contentsOfFile: filePath)
            commandFile.sendAllCommands()
        } catch {
            print("PrevueCLI: An error occurred: \(error)")
        }
    }),
    CLI.Command(name: "convertCommandFileToBinary", usage: " <.prevuecommand file> <binary commands file>: Converts the commands in the specified .prevuecommand file to their satellite data representation", minimumArgumentCount: 2, handler: { (arguments) in
        do {
            let filePath = arguments[0]
            let commandFile = try PrevueCommandFile(contentsOfFile: filePath)
            
            let serializedCommands = commandFile.commands.map { SerializedCommand(command: $0) }
            let bytes = try BinaryEncoder.encode(serializedCommands)
            print("Writing: \(bytes.hexEncodedString())")

            let data = Data(bytes)
            let outputURL = URL(fileURLWithPath: arguments[1])
            try data.write(to: outputURL)

        } catch {
            print("PrevueCLI: An error occurred: \(error)")
        }
    }),
    CLI.Command(name: "convertBinaryToCommandFile", usage: " <binary commands file> <.prevuecommand file>: Converts commands in satellite data format to a .prevuecommand file", minimumArgumentCount: 2, handler: { (arguments) in
        do {
            let fileURL = URL(fileURLWithPath: arguments[0])
            let data = try Data(contentsOf: fileURL)
            let bytes = [UInt8](data)

            let serializedCommands = try BinaryDecoder.decode([SerializedCommand].self, data: bytes)
            let commands = serializedCommands.map { $0.command }
            let commandFile = PrevueCommandFile(destinations: [], commands: commands)
            try commandFile.write(toFile: arguments[1])

        } catch {
            print("PrevueCLI: An error occurred: \(error)")
        }
    }),
    CLI.Command(name: "parseCurdayDat", usage: " <curday.dat file> <directory to save .csv files>: Converts a curday.dat file to .csv listings files (can unpack PowerPack 2.0 if necessary)", minimumArgumentCount: 2, handler: { (arguments) in
        do {
            let fileURL = URL(fileURLWithPath: arguments[0])
            let data = try Data(contentsOf: fileURL).unpackPowerPacker2Data()
            let bytes = [UInt8](data)
            
            let curdayDat = try BinaryDecoder.decode(CurdayDat.self, data: bytes)
            
            let directoryURL = URL(fileURLWithPath: arguments[1])
            let channelsFileURL = directoryURL.appendingPathComponent("channels.csv", isDirectory: false)
            let programsFileURL = directoryURL.appendingPathComponent("programs.csv", isDirectory: false)
            
            let listings = curdayDat.listings
            try listings.write(channelsCSVFile: channelsFileURL, programsCSVFile: programsFileURL)

        } catch {
            print("PrevueCLI: An error occurred: \(error)")
        }
    }),
    CLI.Command(name: "printCommandSchema", usage: ": Prints all of the supported commands and their syntax details", minimumArgumentCount: 0, handler: { (arguments) in
        let documentation = SerializedCommand.commandDocumentation.description
        print("Supported commands:\n\(documentation)")
    }),
    CLI.Command(name: "printJulianDay", usage: ": Prints today's Julian day (0-255)", minimumArgumentCount: 0, handler: { (arguments) in
        let julianDay = JulianDay.now
        print("Julian day: \(julianDay.dayOfYear)")
    }),
//    CLI.Command(name: "repl", usage: ": Opens a REPL interface, where you can type in commands to be sent interactively", handler: { (arguments) in
//
//    })
]

let usagePreamble = """
PrevueCLI
A tool for emulating Prevue Guide and friends
Copyright 2020 Ari Weinstein

Usage:
"""

let cli = CLI(commands: commands, usagePreamble: usagePreamble)
cli.runCommand(for: CommandLine.arguments)

exit(0)
/*
let destination = SerialPortDataDestination(path: "/dev/cu.usbserial-1440", baudRate: 2400) //TCPDataDestination(host: "127.0.0.1", port: 5542)
destination.openConnection()

// For Atari Sio2pc adapter
//let destination = SerialPortDataDestination(path: "/dev/cu.Repleo-PL2303-00001014", baudRate: 2400)
//destination.setRTS(false)

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

//let promoTitleCommand = PromoTitleCommand(leftTitle: "Action News", rightTitle: "Action News")
//let actionCommand = ActionCommand(value: .quarterScreenPreview("WPVI", "WCAU"))
//let actionCommand2 = ActionCommand(value: .quarterScreenTrigger(.null, .null))
//let eventCommand = EventCommand(leftEvent: .titleLookup, rightEvent: .titleLookup)
//
//destination.send(control: promoTitleCommand.encodedWithChecksum)
//destination.send(control: eventCommand.encodedWithChecksum)
//destination.send(control: actionCommand.encodedWithChecksum)
//destination.send(control: actionCommand2.encodedWithChecksum)


SerialPortDataDestination.delay = 930
let time = CFAbsoluteTimeGetCurrent()
destination.send(control: ActionCommand(value: .localAdOrHalfScreenNationalAd).encodedWithChecksum)
destination.send(control: ActionCommand(value: .localAdOrHalfScreenNationalAd).encodedWithChecksum)
destination.send(control: ActionCommand(value: .localAdOrHalfScreenNationalAd).encodedWithChecksum)
destination.send(control: ActionCommand(value: .localAdOrHalfScreenNationalAd).encodedWithChecksum)
print("FINISH: \(CFAbsoluteTimeGetCurrent() - time)")
destination.startTimer()

//for _ in 1...10 {
//    SerialPortDataDestination.delay += 1
//    print("trying delay \(SerialPortDataDestination.delay)")
//    let cmd: [Byte] = [0x05, 0x01, 0x01, 0x0D]
////    let cmd: [Byte] = [0x03, 0x0D]
//    let checksumCmd = cmd + [cmd.checksum]
//    destination.send(control: checksumCmd)
////    for byte in checksumCmd {
////        destination.sendCTRLByte(byt: byte)
////    }
//}

sleep(5)

destination.closeConnection()
*/
