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
            let scriptText = try String(contentsOfFile: filePath)

            // Change the current working directory to the directory containing the .prevuecommand file (in order to resolve relative paths referenced in the file)
            let fileURL = URL(fileURLWithPath: filePath)
            let containingDirectory = fileURL.deletingLastPathComponent()
            FileManager.default.changeCurrentDirectoryPath(containingDirectory.path)

            let decoder = YAMLDecoder()
            let commandFile = try decoder.decode(PrevueCommandFile.self, from: scriptText)
            commandFile.sendAllCommands()
        } catch {
            print("PrevueCLI: An error occurred: \(error)")
        }
    }),
    CLI.Command(name: "printCommandSchema", usage: ": Prints all of the supported commands and their syntax details", minimumArgumentCount: 0, handler: { (arguments) in
        let allPossibleSerializedCommands = PrevueCommandFile.SerializedCommand(
            BoxOnCommand: BoxOnCommand(selectCode: ""),
            BoxOffCommand: BoxOffCommand(),
            ResetCommand: ResetCommand(),
            TitleCommand: TitleCommand(alignment: .center, title: ""),
            ClockCommand: ClockCommand(with: Date())!,
            CurrentClockCommand: FileCurrentClockCommand(),
            DownloadCommand: nil,// TODO
            LocalAdResetCommand: LocalAdResetCommand(),
            LocalAdCommand: LocalAdCommand(ad: LocalAd(adNumber: 0, content: [.init(alignment: nil, color: nil, text: "")], timePeriod: .init(beginning: 0, ending: 0))),
            ColorLocalAdCommand: ColorLocalAdCommand(ad: LocalAd(adNumber: 0, content: [.init(alignment: .center, color: .init(background: .red, foreground: .red), text: "")], timePeriod: .init(beginning: 0, ending: 0))),
            ConfigurationCommand: ConfigurationCommand(timeslotsBack: 1, timeslotsForward: 4, scrollSpeed: 3, maxAdCount: 36, maxAdLines: 6, crawlOrIgnoreNationalAds: false, unknownAdSetting: 0x0101, timezone: 7, observesDaylightSavingsTime: true, cont: true, keyboardActive: false, unknown2: false, unknown3: false, unknown4: true, unknown5: 0x41, grph: 0x4E, videoInsertion: 0x4E, unknown6: 0x00),
            ConfigDatCommand: ConfigDatCommand(displayFormat: .grid, textAdFlag: .none),
            ChannelsCommand: ChannelsCommand(day: JulianDay(dayOfYear: 0), channels: [Channel(flags: [.none], sourceIdentifier: "", channelNumber: "", callLetters: "")]),
            ProgramCommand: ProgramCommand(program: Program(timeslot: 0, day: JulianDay(dayOfYear: 0), sourceIdentifier: "", flags: [], programName: "")),
            ListingsCommand: FileListingsCommand(channelsFilePath: "", programsFilePath: "", forAtari: false)
        )
        let documentation = allPossibleSerializedCommands.documentedType.description
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

let destination = TCPDataDestination(host: "127.0.0.1", port: 5541)//SerialPortDataDestination(path: "/dev/cu.Repleo-PL2303-00001014", baudRate: 2400) //TCPDataDestination(host: "127.0.0.1", port: 5542)
destination.openConnection()

// For Atari Sio2pc adapter
//let destination = SerialPortDataDestination(path: "/dev/cu.Repleo-PL2303-00001014", baudRate: 2400)
//destination.setRTS(false)

destination.send(data: BoxOnCommand(selectCode: "*"))

destination.send(data: TitleCommand(alignment: .center, title: "2020 ATARI EPG Test"))

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

let promoTitleCommand = PromoTitleCommand(leftTitle: "Action News", rightTitle: "Action News")
let actionCommand = ActionCommand(value: .quarterScreenPreview("WPVI", "WCAU"))
let actionCommand2 = ActionCommand(value: .quarterScreenTrigger(.null, .null))
let eventCommand = EventCommand(leftEvent: .titleLookup, rightEvent: .titleLookup)

//for byte in promoTitleCommand.encodedWithChecksum {
//    destination.sendDebugCTRLByte(byte: byte)
//}
//for byte in eventCommand.encodedWithChecksum {
//    destination.sendDebugCTRLByte(byte: byte)
//}
//for byte in actionCommand.encodedWithChecksum {
//    destination.sendDebugCTRLByte(byte: byte)
//}
//for byte in actionCommand2.encodedWithChecksum {
//    destination.sendDebugCTRLByte(byte: byte)
//}

//for _ in 1...100 {
////    destination.delay += 1
//    print("trying delay \(destination.delay)")
//    let cmd: [Byte] = [0x05, 0x01, 0x01, 0x0D]
////    let cmd: [Byte] = [0x03, 0x0D]
//    let checksumCmd = cmd + [cmd.checksum]
//    for byte in checksumCmd {
//        destination.sendCTRLByte(byt: byte)
//    }
//}

// Configuration test
let command2 = ConfigurationCommand(timeslotsBack: 1, timeslotsForward: 4, scrollSpeed: 3, maxAdCount: 36, maxAdLines: 6, crawlOrIgnoreNationalAds: false, unknownAdSetting: 0x0101, timezone: 7, observesDaylightSavingsTime: true, cont: true, keyboardActive: false, unknown2: false, unknown3: false, unknown4: true, unknown5: 0x41, grph: 0x4E, videoInsertion: 0x4E, unknown6: 0x00)
//destination.send(data: command2)

// Download test
//var bytes: Bytes = []
//stride(from: 0, to: 32536, by: 1).map { index in
//    let sixteenBitIndex = UInt16(index)
//    bytes.append(contentsOf: sixteenBitIndex.bytesBySeparatingIntoHighAndLowBits())
//}
//let fileData = try Data(contentsOf: URL(fileURLWithPath: "/Users/Ari/Desktop/Prevue Technical/Amiga Resources/Work/ESQ7803/esq"))
//let fileBytes = [UInt8](fileData)
//let downloadCommands = DownloadCommand.commandsToTransferFile(filePath: "DF0:ESQ", contents: fileBytes)
//destination.send(data: downloadCommands)
//destination.send(data: ResetCommand())

// Config.dat test
//destination.send(data: ConfigDatCommand(textAdFlag: .remote, clockCmd: 2).encodedWithChecksum)

// Channel & programs test

//exit(0)

let date = Date()
let julianDay = JulianDay(dayOfYear: JulianDay(with: date).dayOfYear/* - 1*/)

destination.send(data: ClockCommand(with: date)!)

let channelsFilePath = URL(fileURLWithPath: "/Users/Ari/dev/PrevuePackage/Resources/Sample Listings/channels.csv")
let programsFilePath = URL(fileURLWithPath: "/Users/Ari/dev/PrevuePackage/Resources/Sample Listings/programs.csv")
let listingSource = SampleDataListingSource(channelsCSVFile: channelsFilePath, programsCSVFile: programsFilePath, day: julianDay, forAtari: true)!

//let channels = [Channel(flags: .none, sourceIdentifier: "TBS", channelNumber: "2", callLetters: "TBS"), Channel(flags: .none, sourceIdentifier: "KYW", channelNumber: "3", callLetters: "KYW")]
let channelCommand = ChannelsCommand(day: julianDay, channels: listingSource.channels)
destination.send(data: channelCommand)

//let programs: [Program] = stride(from: 0, to: 47, by: 1).map { (index) in
//    Program(timeslot: index, day: julianDay, sourceIdentifier: "KYW", flags: .none, programName: "Eyewitness @ \(index) \(julianDay.dayOfYear)")
//}
let programCommands: [ProgramCommand] = listingSource.programs.map { (program) in
    ProgramCommand(program: program)
}
destination.send(data: programCommands)

// Clock test
//destination.send(ClockCommand(dayOfWeek: .Friday, month: 2, day: 4, year: 119, hour: 07, minute: 00, second: 00, daylightSavingsTime: true))
//destination.send(ClockCommand(with: Date())!)

destination.send(data: BoxOffCommand())

destination.closeConnection()
