//
//  EncodingTests.swift
//  PackageTests
//
//  Created by Ari on 8/8/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import XCTest
@testable import PrevuePackage

class CommandSerialization: XCTestCase {
    func encodeCommands(_ commands: [SatelliteCommand]) throws -> Bytes {
        let messages = commands.map { SerializedCommand(command: $0) }
        return try BinaryEncoder.encode(messages)
    }
    
    func encodeCommand(_ command: SatelliteCommand) throws -> Bytes {
        return try encodeCommands([command])
    }
    
    func decodeCommands(_ bytes: Bytes) throws -> [Command] {
        let commandMessages = try BinaryDecoder.decode([SerializedCommand].self, data: bytes)
        return commandMessages.map { $0.command }
    }
    
    func decodeCommands<T: SatelliteCommand>(_ bytes: Bytes, ofType: T.Type) throws -> [T] {
        let commandMessages = try BinaryDecoder.decode([SerializedCommand].self, data: bytes)
        return commandMessages.map { $0.command } as! [T]
    }
    
    func decodeCommand<T: SatelliteCommand>(_ bytes: Bytes, ofType: T.Type) throws -> T {
        return try decodeCommands(bytes, ofType: T.self).first!
    }
    
    func assert<T: SatelliteCommand & Equatable>(commands: [T], serializeToAndFrom expectedBytes: String, file: StaticString = #file, line: UInt = #line) {
        do {
            // Test that the command encodes to the expected bytes
            let encodedCommands = try encodeCommands(commands)
            XCTAssertEqual(encodedCommands, expectedBytes.hexStringAsBytes, file: file, line: line)
            
            // Test that decoding the command results in the same command
            let decodedCommands = try decodeCommands(expectedBytes.hexStringAsBytes, ofType: T.self)
            XCTAssertEqual(commands, decodedCommands, file: file, line: line)
        } catch {
            XCTFail("\(error)", file: file, line: line)
        }
    }
    
    func assert<T: SatelliteCommand & Equatable>(command: T, serializesToAndFrom expectedBytes: String, file: StaticString = #file, line: UInt = #line) {
            do {
                // Test that the command encodes to the expected bytes
                let encodedCommand = try encodeCommand(command)
                XCTAssertEqual(encodedCommand, expectedBytes.hexStringAsBytes, file: file, line: line)
                
                // Test that decoding the command results in the same command
                let decodedCommand = try decodeCommand(expectedBytes.hexStringAsBytes, ofType: T.self)
                XCTAssertEqual(command, decodedCommand, file: file, line: line)
            } catch {
                XCTFail("\(error)", file: file, line: line)
            }
        }
    
    // separate encoding & decoding tests?
    
    func testBoxOn() throws {
        let command = BoxOnCommand(selectCode: "*")
        assert(command: command, serializesToAndFrom: "55AA412A0094")
    }

    func testBoxOff() throws {
        let command = BoxOffCommand()
        assert(command: command, serializesToAndFrom: "55AABBBB00FF")
    }

    func testReset() throws {
        let command = ResetCommand()
        assert(command: command, serializesToAndFrom: "55AA5200AD")
    }

    func testTitle() throws {
        let command = TitleCommand(alignment: nil, title: "    THIS IS A TEST FROM UNITED VIDEO   ")
        assert(command: command, serializesToAndFrom: "55AA542020202054484953204953204120544553542046524F4D20554E4954454420564944454F2020200080")
    }

    func testTitleWithAlignment() throws {
        let command = TitleCommand(alignment: .center, title: "THIS IS A TEST FROM UNITED VIDEO")
        assert(command: command, serializesToAndFrom: "55AA541854484953204953204120544553542046524F4D20554E4954454420564944454F00B8")
    }
    
    func testDownload() throws {
        let downloadCommands = DownloadCommand.commandsToTransferFile(filePath: "DF0:TEMP1", contents: "313233341A".hexStringAsBytes)
        assert(commands: downloadCommands, serializeToAndFrom: "55AA484446303A54454D5031008255AA480005313233341AAC55AA480100B6")
    }
    
    func testClock() throws {
        let command = ClockCommand(dayOfWeek: .Friday, month: 2, day: 4, year: 120, hour: 7, minute: 0, second: 0, daylightSavingsTime: true)
        assert(command: command, serializesToAndFrom: "55 AA 4B 05 02 04 78 07 00 00 01 00 C9")
    }
    
    func testChannels() throws {
        let channels = [
            Listings.Channel(sourceIdentifier: "WPVI", channelNumber: "6", timeslotMask: nil, callLetters: "6ABC", flags: [.hiliteSrc]),
            Listings.Channel(sourceIdentifier: "SOUP", channelNumber: "7", timeslotMask: nil, callLetters: "7SOUP", flags: [.none])
        ]
        let command = ChannelsCommand(day: JulianDay(dayOfYear: 138), channels: channels)
        assert(command: command, serializesToAndFrom: "55 AA 43 8A 12 02 57 50 56 49 11 36 01 36 41 42 43 12 01 53 4F 55 50 11 37 01 37 53 4F 55 50 00 6D")
    }
    
    // Test channels missing a channel number, or call letters, and with timeslot masks
    func testEdgeCaseChannels() throws {
        let channels = [
            Listings.Channel(sourceIdentifier: "HIDECH", channelNumber: nil, timeslotMask: nil, callLetters: "BOOP", flags: [.none]),
            Listings.Channel(sourceIdentifier: "HIDECL", channelNumber: "700", timeslotMask: nil, callLetters: nil, flags: [.none]),
            Listings.Channel(sourceIdentifier: "HIDECL", channelNumber: "700", timeslotMask: TimeslotMask(blackedOutTimeslots: []), callLetters: nil, flags: [.none]),
            Listings.Channel(sourceIdentifier: "HIDECL", channelNumber: "700", timeslotMask: TimeslotMask(blackedOutTimeslots: [1, 17, 42]), callLetters: nil, flags: [.none])
        ]
        let command = ChannelsCommand(day: JulianDay(dayOfYear: 138), channels: channels)
        
        // Test that encoding & decoding the command results in the same command
        let encodedCommand = try encodeCommand(command)
        let decodedCommand = try decodeCommand(encodedCommand, ofType: ChannelsCommand.self)
        XCTAssertEqual(command, decodedCommand)
    }
    
    func testTimeslotMask() throws {
        let noBlackoutMask = TimeslotMask(blackedOutTimeslots: [])
        let noBlackoutMaskEncoded = Bytes([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
        
        XCTAssertEqual(noBlackoutMaskEncoded, try BinaryEncoder.encode(noBlackoutMask))
        XCTAssertEqual(noBlackoutMask, try BinaryDecoder(data: noBlackoutMaskEncoded).decode(TimeslotMask.self))
        
        let firstByteBlackoutMask = TimeslotMask(blackedOutTimeslots: [2, 3, 4, 5, 6, 7, 8])
        let firstByteBlackoutMaskEncoded = Bytes([0x80, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])
        
        XCTAssertEqual(firstByteBlackoutMaskEncoded, try BinaryEncoder.encode(firstByteBlackoutMask))
        XCTAssertEqual(firstByteBlackoutMask, try BinaryDecoder(data: firstByteBlackoutMaskEncoded).decode(TimeslotMask.self))
        
        let lastByteBlackoutMask = TimeslotMask(blackedOutTimeslots: [45, 46, 47, 48])
        let lastByteBlackoutMaskEncoded = Bytes([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, Byte(0x80 | 0x40 | 0x20 | 0x10)])
        
        XCTAssertEqual(lastByteBlackoutMaskEncoded, try BinaryEncoder.encode(lastByteBlackoutMask))
        XCTAssertEqual(lastByteBlackoutMask, try BinaryDecoder(data: lastByteBlackoutMaskEncoded).decode(TimeslotMask.self))
    }
    
    func testPrograms() throws {
        let command = ProgramCommand(day: JulianDay(dayOfYear: 138), program: Listings.Program(timeslot: 1, sourceIdentifier: "WPVI", programName: "Action News", flags: .none))
        assert(command: command, serializesToAndFrom: "55 AA 50 01 8A 57 50 56 49 12 01 41 63 74 69 6F 6E 20 4E 65 77 73 00 1E")
    }
    
    func testConfiguration() throws {
        let command = ConfigurationCommand(timeslotsBack: 1, timeslotsForward: 4, scrollSpeed: 3, maxAdCount: 36, maxAdLines: 6, crawlOrIgnoreNationalAds: false, unknownAdSetting: 0x0101, timezone: 5, observesDaylightSavingsTime: true, cont: true, keyboardActive: false, unknown2: false, unknown3: false, unknown4: true, unknown5: 0x41, grph: 0x4E, videoInsertion: 0x4E, unknown6: 0x00)
        assert(command: command, serializesToAndFrom: "55 AA 46 42 45 33 33 36 36 4E 01 01 35 59 59 4E 4E 4E 59 41 4E 4E 00 00 93")
    }
    
    func testNewLookConfiguration() throws {
        let command = NewLookConfigurationCommand(displayFormat: .grid, textAdFlag: .satellite, clockCmd: 1)
        assert(command: command, serializesToAndFrom: "55 AA 66 00 00 36 32 43 30 31 30 38 30 38 47 4E 41 45 30 31 4E 4E 4E 4E 4E 4E 4C 32 39 30 36 59 59 59 32 33 33 36 30 36 30 31 35 31 30 30 59 4E 59 43 8E 38 53 4E 4E 4E 4E 31 00 15")
    }
    
    func testLocalAd() throws {
        let resetCommand = LocalAdCommand.reset
        assert(command: resetCommand, serializesToAndFrom: "55 AA 4C 92 00 21")
        
        let oneLineCommand = LocalAdCommand.ad(LocalAd(adNumber: 1, content: [LocalAd.Content(alignment: nil, color: nil, text: "        BEFORE YOU VIEW, PREVUE!")], timePeriod: nil))
        assert(command: oneLineCommand, serializesToAndFrom: "55 AA 4C 01 20 20 20 20 20 20 20 20 42 45 46 4F 52 45 20 59 4F 55 20 56 49 45 57 2C 20 50 52 45 56 55 45 21 00 C9")

        let twoLineCommand = LocalAdCommand.ad(LocalAd(adNumber: 2, content: [LocalAd.Content(alignment: .center, color: nil, text: "PREVUE GUIDE"), LocalAd.Content(alignment: .center, color: nil, text: "WE ARE WHAT'S ON")], timePeriod: nil))
        assert(command: twoLineCommand, serializesToAndFrom: "55 AA 4C 02 18 50 52 45 56 55 45 20 47 55 49 44 45 18 57 45 20 41 52 45 20 57 48 41 54 27 53 20 4F 4E 00 D1")

        let multilineWithAlignmentsCommand = LocalAdCommand.ad(LocalAd(adNumber: 3, content: [LocalAd.Content(alignment: .left, color: nil, text: "LEFT-ALIGNED AD LINE"), LocalAd.Content(alignment: .center, color: nil, text: "CENTER-ALIGNED AD LINE"), LocalAd.Content(alignment: .right, color: nil, text: "RIGHT-ALIGNED AD LINE")], timePeriod: nil))
        assert(command: multilineWithAlignmentsCommand, serializesToAndFrom: "55 AA 4C 03 19 4C 45 46 54 2D 41 4C 49 47 4E 45 44 20 41 44 20 4C 49 4E 45 18 43 45 4E 54 45 52 2D 41 4C 49 47 4E 45 44 20 41 44 20 4C 49 4E 45 1A 52 49 47 48 54 2D 41 4C 49 47 4E 45 44 20 41 44 20 4C 49 4E 45 00 91")

        let timeslotConstraintsCommand = LocalAdCommand.ad(LocalAd(adNumber: 4, content: [LocalAd.Content(alignment: .center, color: nil, text: "TARGET YOUR AUDIENCE WITH CABLE"), LocalAd.Content(alignment: .center, color: nil, text: "TELEVISION. CALL COMCAST NOW AT"), LocalAd.Content(alignment: .center, color: nil, text: "215-639-2330")], timePeriod: LocalAd.TimePeriod(beginning: 24, ending: 48)))
        assert(command: timeslotConstraintsCommand, serializesToAndFrom: "55 AA 4C 04 18 54 41 52 47 45 54 20 59 4F 55 52 20 41 55 44 49 45 4E 43 45 20 57 49 54 48 20 43 41 42 4C 45 18 54 45 4C 45 56 49 53 49 4F 4E 2E 20 43 41 4C 4C 20 43 4F 4D 43 41 53 54 20 4E 4F 57 20 41 54 18 32 31 35 2D 36 33 39 2D 32 33 33 30 14 18 30 00 F3")

        let colorCommand = ColorLocalAdCommand(ad: LocalAd(adNumber: 5, content: [LocalAd.Content(alignment: nil, color: nil, text: "Always think "), LocalAd.Content(alignment: nil, color: LocalAd.Content.TextColor(background: .grey, foreground: .yellow), text: "Prevue "), LocalAd.Content(alignment: nil, color: LocalAd.Content.TextColor(background: .lightBlue, foreground: .red), text: "first!")], timePeriod: nil))
        assert(command: colorCommand, serializesToAndFrom: "55 AA 74 05 41 6C 77 61 79 73 20 74 68 69 6E 6B 20 03 36 33 50 72 65 76 75 65 20 03 35 34 66 69 72 73 74 21 00 91 ")
    }
    
    func testLocalDST() throws {
        let start = DSTBoundary(year: 1996, dayOfYear: 301, hour: 2, minute: 0)
        let end = DSTBoundary(year: 1997, dayOfYear: 096, hour: 2, minute: 0)
        let command = DSTCommand(mode: .local, start: start, end: end)
        assert(command: command, serializesToAndFrom: "55 AA 67 32 32 37 04 31 39 39 36 33 30 31 30 32 3A 30 30 13 31 39 39 37 30 39 36 30 32 3A 30 30 00 B4")
    }
    
    func testGlobalDST() throws {
        let start = DSTBoundary(year: 1996, dayOfYear: 301, hour: 2, minute: 0)
        let end = DSTBoundary(year: 1997, dayOfYear: 096, hour: 2, minute: 0)
        let command = DSTCommand(mode: .global, start: start, end: end)
        assert(command: command, serializesToAndFrom: "55 AA 67 33 32 37 04 31 39 39 36 33 30 31 30 32 3A 30 30 13 31 39 39 37 30 39 36 30 32 3A 30 30 00 B5")
    }
    
//    func testYAMLEncoding() throws {
////        - TitleCommand: {alignment: "center", title: "Electronic Program Guide"}
////        let decoder = YAMLDecoder()
////        self = try decoder.decode([SerializedCommand].self, from: commandFileText)
//        let encoder = YAMLEncoder()
//        let command = TitleCommand(alignment: .center, title: "THIS IS A TEST FROM UNITED VIDEO")
//        let string = try encoder.encode(command)
//        print("\(string)")
//    }
}
