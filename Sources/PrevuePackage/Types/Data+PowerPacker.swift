//
//  PowerPacker.swift
//  PrevuePackage
//
//  Created by Ari on 9/11/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation
import PowerPacker

enum PowerPackerError: Error {
    case decrunchError
}

extension Data {
    var isPowerPacker2Data: Bool {
        let headerBytes = String(bytes: self[0..<4], encoding: .ascii)
        return (headerBytes == "PP20")
    }
    func unpackPowerPacker2Data() throws -> Data {
        guard isPowerPacker2Data else { return self }
        
        let efficiencyHeaderOffset = 4
        let dataStartOffset = 4
        let footerSize = 4
        
        let packedLength = (count - (efficiencyHeaderOffset + dataStartOffset + footerSize))
        let unpackedLength = (Int(self[count-4]) << 16) | (Int(self[count-3]) << 8) | Int(self[count-2])
        
        return try withUnsafeBytes {
            let dataPointer = $0.bindMemory(to: Byte.self).baseAddress!
            
            let efficiencyHeaderPointer = dataPointer + efficiencyHeaderOffset
            let dataStartPointer = efficiencyHeaderPointer + dataStartOffset
            
            let resultBufferPointer = malloc(unpackedLength)!
            let resultPointer = resultBufferPointer.bindMemory(to: Byte.self, capacity: unpackedLength)
            let resultData = Data(bytesNoCopy: resultBufferPointer, count: unpackedLength, deallocator: .free)
            
            let result = ppDecrunchBuffer(efficiencyHeaderPointer, dataStartPointer, resultPointer, UInt32(packedLength), UInt32(unpackedLength))
            
            if result != 1 {
                throw PowerPackerError.decrunchError
            }
            
            return resultData
        }
    }
}
