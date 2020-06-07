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
    enum Message {
        case start(filePath: String)
        case packet(packetIndex: UInt8, byteCount: UInt8, data: Bytes)
        case end(packetCount: UInt8)
    }
    let message: Message
}

extension DownloadCommand {
    var payload: Bytes {
        switch message {
        case .start(let filePath):
            return filePath.asNullTerminatedBytes()
        case .packet(let packetIndex, let byteCount, let data):
            return [packetIndex] + [byteCount] + data
        case .end(let packetCount):
            return [packetCount, 0x00]
        }
    }
}

extension DownloadCommand {
    static func commandsToTransferFile(filePath: String, contents: Bytes) -> [DownloadCommand] {
        let maxPacketSize = Int(Byte.max)
        let dataChunks = contents.splitIntoChunks(chunkSize: maxPacketSize)
        
        let startCommand = DownloadCommand(message: .start(filePath: filePath))
        let packetCommands = dataChunks.enumerated().map { (index, dataChunk) in
            return DownloadCommand(message: .packet(packetIndex: UInt8(index % 256), byteCount: UInt8(dataChunk.count), data: dataChunk))
        }
        let endCommand = DownloadCommand(message: .end(packetCount: UInt8(dataChunks.count % 256)))
        return [startCommand] + packetCommands + [endCommand]
    }
}

// MARK: Codable support

// Encode/decode download commands as the message structure

extension DownloadCommand: Codable {
    init(from decoder: Decoder) throws {
        let message = try decoder.singleValueContainer().decode(Message.self)
        self.init(message: message)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(message)
    }
}

extension DownloadCommand.Message: Codable {
    enum CodingKeys: String, CodingKey {
        case start, packet, end
    }
    
    struct Start: Codable {
        let filePath: String
    }
    
    struct Packet: Codable {
        let index: UInt8
        let byteCount: UInt8
        let data: Bytes
    }
    
    struct End: Codable {
        let packetCount: UInt8
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let start = try container.decodeIfPresent(Start.self, forKey: .start) {
            self = .start(filePath: start.filePath)
        } else if let packet = try container.decodeIfPresent(Packet.self, forKey: .packet) {
            self = .packet(packetIndex: packet.index, byteCount: packet.byteCount, data: packet.data)
        } else if let end = try container.decodeIfPresent(End.self, forKey: .end) {
            self = .end(packetCount: end.packetCount)
        } else {
            let context = DecodingError.Context(codingPath: container.codingPath, debugDescription: "Malformed DownloadCommand.Message")
            throw DecodingError.valueNotFound(DownloadCommand.Message.self, context)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .start(let filePath):
            let start = Start(filePath: filePath)
            try container.encode(start, forKey: .start)
        case .packet(let packetIndex, let byteCount, let data):
            let packet = Packet(index: packetIndex, byteCount: byteCount, data: data)
            try container.encode(packet, forKey: .packet)
        case .end(let packetCount):
            let end = End(packetCount: packetCount)
            try container.encode(end, forKey: .end)
        }
    }
}
