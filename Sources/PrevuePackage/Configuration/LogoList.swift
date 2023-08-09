//
//  LogoList.swift
//  PrevuePackage
//
//  Created by Ari on 4/16/22.
//  Copyright © 2022 Vertex. All rights reserved.
//

import Foundation

struct LogoList {
    let logoFilenames: [String]
}

extension LogoList {
    var text: String {
        logoFilenames.joined(separator: ",\n").appending(",\n")
    }
    var bytes: Bytes {
        Bytes(text.data(using: .utf8)!)
    }
}
