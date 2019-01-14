//
//  DownloadCommand.swift
//  PrevueFramework
//
//  Created by Ari on 11/17/18.
//  Copyright © 2018 Vertex. All rights reserved.
//

/*
 
 55 AA 48 (the header for the H command again) 00 (the "packet number" of the data you're sending) 34 (The number of bytes of data to follow; possibly limited to 80 bytes. If this value is wrong, the scroll will stop and the software will show a scary warning.) 32 43 30 31 30 38 30 38 47 4E 41 45 30 31 4E 4E 4E 4E 4E 4E 4C 32 39 30 36 59 59 59 32 33 33 36 30 36 30 31 35 31 30 30 59 4E 59 43 8E 38 4E 4E 4E 4E 4E 32 (the actual data to send, in this case $34 bytes) 27 00 (the checksum; note that for some reason the checksum comes BEFORE the 00 in this instance instead of after)
 If you want to send more data, you can continue to send more packets. Simply increment the packet number every time you send data and it will be appended onto the data to be written. You can also send the same packet multiple times; it seems that UV actually sent each packet twice for redundancy: if the first one wasn't received properly, the second one would be used instead (based on the checksum).
 
 Once you're done sending your packets, you must send one final, null packet to get the file to write out:
 CODE: SELECT ALL
 
 55 AA 48 01 00 B6 (here I use packet number $01 because I only sent one packet so far)*/

