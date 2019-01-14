//
//  main.swift
//  PrevueCLI
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

import PrevueFramework

let command = TitleCommand(title: "        Electronic Program Guide")
let data = command.encodeWithChecksum()
print(data.hexEncodedString())
