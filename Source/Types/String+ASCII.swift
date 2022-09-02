//
//  String+ASCII.swift
//  PrevueApp
//
//  Created by Ari on 4/23/22.
//  Copyright © 2022 Vertex. All rights reserved.
//

import Foundation

extension String {
    var asASCII: String? {
        guard let stringData = data(using: .ascii, allowLossyConversion: true) else { return nil }
        return String(bytes: stringData, encoding: .ascii)
    }
}
