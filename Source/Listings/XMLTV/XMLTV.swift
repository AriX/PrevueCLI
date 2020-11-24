//
//  XMLTV.swift
//  PrevuePackage
//
//  Created by Ari on 9/12/20.
//  Copyright © 2020 Vertex. All rights reserved.
//

import Foundation

struct XMLTV {
    struct Channel {
        var displayNames: [String]
        var programs: [Program]
        
        struct Program {
            let startDate: Date
            let endDate: Date?
            let title: String
            let subtitle: String?
            let description: String?
            let categories: [String]
            let actors: [String]
            let year: String?
            let duration: TimeInterval?
            let stereo: Bool?
            let closedCaptioned: Bool
            let ratings: [Rating]
            
            struct Rating {
                let ratingSystem: String?
                let rating: String
            }
        }
    }
    
    var sourceInfoURL: String?
    var sourceInfoName: String?
    var generatorInfoName: String?
    var channels: [String: Channel]
}
