//
//  DownloadCommand.swift
//  PrevuePackage
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

// Sources: http://ariweinstein.com/prevue/viewtopic.php?p=1413#p1413, UVSG test files

struct DownloadCommand: DataCommand, Equatable {
    static let commandMode = DataCommandMode.download
    enum Message: Equatable {
        case start(filePath: String)
        case packet(packetIndex: UInt8, byteCount: UInt8, data: Bytes)
    }
    let message: Message
}

extension DownloadCommand {
    static func commandsToTransferFile(filePath: String, contents: Bytes) -> [DownloadCommand] {
        let maxPacketSize = Int(Byte.max)
        let dataChunks = contents.splitIntoChunks(chunkSize: maxPacketSize)
        
        let startCommand = DownloadCommand(message: .start(filePath: filePath))
        let packetCommands = dataChunks.enumerated().map { (index, dataChunk) in
            return DownloadCommand(message: .packet(packetIndex: UInt8(index % 256), byteCount: UInt8(dataChunk.count), data: dataChunk))
        }
        let endCommand = DownloadCommand(message: .packet(packetIndex: UInt8(dataChunks.count % 256), byteCount: 0, data: []))
        return [startCommand] + packetCommands + [endCommand]
    }
}

// MARK: Encoding

// Encode/decode download commands as the message structure

extension DownloadCommand: BinaryCodable {
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
    enum Kind: String, CodingKey {
        case start, packet, end
    }
    
    struct Start: BinaryCodable {
        let filePath: String
    }
    
    struct Packet: BinaryCodable {
        let index: UInt8
        let byteCount: UInt8
        let data: Bytes
        
        var isEnd: Bool {
            return byteCount == 0
        }
    }
    
    // Convenience for regular Codable, not used by BinaryCodable
    struct End: Codable {
        let packetCount: UInt8
    }
    
    init(with start: Start) {
        self = .start(filePath: start.filePath)
    }
    
    init(with packet: Packet) {
        self = .packet(packetIndex: packet.index, byteCount: packet.byteCount, data: packet.data)
    }
    
    init(with end: End) {
        self = .packet(packetIndex: end.packetCount, byteCount: 0, data: [])
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Kind.self)
        if let start = try container.decodeIfPresent(Start.self, forKey: .start) {
            self.init(with: start)
        } else if let packet = try container.decodeIfPresent(Packet.self, forKey: .packet) {
            self.init(with: packet)
        } else if let end = try container.decodeIfPresent(End.self, forKey: .end) {
            self.init(with: end)
        } else {
            let context = DecodingError.Context(codingPath: container.codingPath, debugDescription: "Malformed DownloadCommand.Message")
            throw DecodingError.valueNotFound(DownloadCommand.Message.self, context)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Kind.self)
        switch self {
        case .start(let filePath):
            let start = Start(filePath: filePath)
            try container.encode(start, forKey: .start)
        case .packet(let packetIndex, let byteCount, let data):
            let packet = Packet(index: packetIndex, byteCount: byteCount, data: data)
            try container.encode(packet, forKey: .packet)
        }
    }
}

// MARK: Binary encoding

extension DownloadCommand.Message: BinaryCodable {
    init(fromBinary decoder: BinaryDecoder) throws {
        if !decoder.userInfo.decodingDownloadCommand {
            // Not currently decoding a download command; interpret this as a "start" command
            let start = try decoder.decode(Start.self)
            self.init(with: start)

            decoder.userInfo.decodingDownloadCommand = true
        } else {
            // In the middle of decoding a download command, interpret this as a "packet" or "end"
            let packet = try decoder.decode(Packet.self)
            self.init(with: packet)

            if packet.isEnd {
                decoder.userInfo.decodingDownloadCommand = false
            }
        }
    }
}

extension DownloadCommand.Message.Packet {
    init(fromBinary decoder: BinaryDecoder) throws {
        let index = try decoder.decode(Byte.self)
        let byteCount = try decoder.decode(Byte.self)
        let bytes = try decoder.readBytes(count: Int(byteCount))
        
        self.init(index: index, byteCount: byteCount, data: bytes)
    }
}

extension CodingUserInfoKey {
    // Boolean indicating whether or not we're in the middle of decoding a download command
    static let decodingDownloadCommand: CodingUserInfoKey = CodingUserInfoKey(rawValue: "decodingDownloadCommand")!
}

extension Dictionary where Key == CodingUserInfoKey, Value == Any {
    var decodingDownloadCommand: Bool {
        get {
            return self[.decodingDownloadCommand] as? Bool ?? false
        }
        set {
            self[.decodingDownloadCommand] = newValue
        }
    }
}

// MARK: UVSGDocumentedType

extension DownloadCommand {
    var documentedType: UVSGDocumentedType {
        get {
            // TODO: Support documentation for enum types like this
            return .none
        }
    }
}
