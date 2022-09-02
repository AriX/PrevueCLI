//
//  INIFile.swift
//  PrevueCLI
//
//  Created by Ari on 12/13/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

struct INIFile {
    let sections: [Section]
    
    struct Section {
        let name: String
        let items: [[Entry]]
        
        struct Entry {
            let key: String
            let value: String
        }
    }
}

extension INIFile {
    var text: String {
        sections.map { section in
            "[\(section.name)]" + "\n\n" + section.items.map { item in
                item.map { entry in
                    "\(entry.key) = \(entry.value)"
                }.joined(separator: "\n") + "\n"
            }.joined(separator: "\n")
        }.joined(separator: "\n")
    }
    var bytes: Bytes {
        Bytes(text.data(using: .utf8)!)
    }
}
