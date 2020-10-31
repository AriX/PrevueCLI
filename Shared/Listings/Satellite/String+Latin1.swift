//
//  String+Latin1.swift
//  PrevueCLI
//
//  Created by Ari on 10/30/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

// Utilities for Latin 1 character encoding (also known as ECMA-94 or ISO 8859-1)

extension String {
    var asLatin1Bytes: Bytes? {
        let string = self as NSString
        guard let stringData = string.data(using: String.Encoding.isoLatin1.rawValue) else { return nil }
        
        return Bytes(stringData)
    }
    
    init?(latin1Bytes: Bytes) {
        self.init(bytes: latin1Bytes, encoding: .isoLatin1)
    }
}
