//
//  DownloadCommand.swift
//  PrevueFramework
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

// Sources: http://ariweinstein.com/prevue/viewtopic.php?p=1413#p1413, UVSG test files

struct DownloadCommand: DataCommand {
    let commandMode = DataCommandMode.download
    enum Message: Codable {
        case start(filePath: String)
        case data(packetNumber: UInt8, byteCount: UInt8, data: Bytes)
        case end(packetCount: UInt8)
        
        // nothing
        public init(from decoder: Decoder) throws {
            self = .start(filePath: "")
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Decoding DownloadCommand not yet supported")
            throw DecodingError.dataCorrupted(context)
        }
        func encode(to encoder: Encoder) throws {
            let context = EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Encoding DownloadCommand not yet supported")
            throw EncodingError.invalidValue(self, context)
        }
    }
    let message: Message
}

extension DownloadCommand {
    var payload: Bytes {
        switch message {
        case .start(let filePath):
            return filePath.uvsgBytes()
        case .data(let packetNumber, let byteCount, let data):
            return [packetNumber] + [byteCount] + data
        case .end(let packetCount):
            return [packetCount, 0x00]
        }
    }
}

extension DownloadCommand {
    static func commandsToTransferFile(filePath: String, contents: Bytes) -> [DownloadCommand] {
        let maxPacketSize = Int(Byte.max)
        let packets = contents.splitIntoChunks(chunkSize: maxPacketSize)
        
        let startCommand = DownloadCommand(message: .start(filePath: filePath))
        let packetCommands = packets.enumerated().map { (index, packet) in
            return DownloadCommand(message: .data(packetNumber: UInt8(index % 256), byteCount: UInt8(packet.count), data: packet))
        }
        let endCommand = DownloadCommand(message: .end(packetCount: UInt8(packets.count % 256)))
        return [startCommand] + packetCommands + [endCommand]
    }
}
