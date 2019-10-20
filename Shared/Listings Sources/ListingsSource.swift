//
//  ListingsSource.swift
//  PrevueApp
//
//  Created by Ari on 4/17/19.
//  Copyright © 2019 Vertex. All rights reserved.
//

protocol ListingsSource {
    var channels: [Channel] { get }
    var programs: [Program] { get }
}
