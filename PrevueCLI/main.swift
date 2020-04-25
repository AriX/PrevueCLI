//
//  main.swift
//  PrevueCLI
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import Foundation

let destination = TCPDataDestination(host: "127.0.0.1", port: 5541)//SerialPortDataDestination(path: "/dev/cu.Repleo-PL2303-00001014", baudRate: 2400) //TCPDataDestination(host: "127.0.0.1", port: 5542)
destination.openConnection()

destination.send(data: BoxOnCommand(selectCode: "*"))

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

//for byte in promoTitleCommand.encodeWithChecksum() {
//    destination.sendDebugCTRLByte(byte: byte)
//}
//for byte in eventCommand.encodeWithChecksum() {
//    destination.sendDebugCTRLByte(byte: byte)
//}
//for byte in actionCommand.encodeWithChecksum() {
//    destination.sendDebugCTRLByte(byte: byte)
//}
//for byte in actionCommand2.encodeWithChecksum() {
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
let command2 = ConfigurationCommand(timeslotsBack: 1, timeslotsForward: 4, scrollSpeed: 3, maxAdCount: 36, maxAdLines: 6, unknown: false, unknownAdSetting: 0x0101, timezone: 7, observesDaylightSavingsTime: true, cont: true, keyboardActive: false, unknown2: false, unknown3: false, unknown4: true, unknown5: 0x41, grph: 0x4E, videoInsertion: 0x4E, unknown6: 0x00)
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
//destination.send(data: ConfigDatCommand(clockCmd: 2).encodeWithChecksum())

// Channel & programs test

//exit(0)

let date = Date()
let julianDay = JulianDay(dayOfYear: JulianDay(with: date).dayOfYear/* - 1*/)

destination.send(data: ClockCommand(with: date)!)

let channelsFile = URL(fileURLWithPath: "/Users/Ari/Desktop/Prevue Technical/Sample Listings/channels.csv")
let programsFile = URL(fileURLWithPath: "/Users/Ari/Desktop/Prevue Technical/Sample Listings/programs.csv")
let listingSource = SampleDataListingSource(channelsCSVFile: channelsFile, programsCSVFile: programsFile, day: julianDay)!
//
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
