//
//  AudioSwitchMonitor.swift
//  PrevueApp
//
//  Created by Ari on 1/9/21.
//  Copyright © 2021 Vertex. All rights reserved.
//

import Foundation

// Simulates the function of the Zephyrus Electronics Model 100 Audio Demod/Switcher

enum SatelliteAudioState: Byte {
    case silence = 0
    case leftAudio = 1
    case rightAudio = 2
    case backgroundAudio = 3
}

protocol AudioStateObserver: AnyObject {
    func setAudioState(_ audioState: SatelliteAudioState)
}

class AudioSwitchMonitor {
    weak var switcher: AudioStateObserver?
    
    var source: DispatchSourceRead?
    var serialInterface: FileDescriptorSerialInterface? {
        didSet {
            guard let fileDescriptor = serialInterface?.fileDescriptor else {
                print("[AudioSwitchMonitor] Failed to initialize because serial interface is not connected")
                return
            }
            
            let readSource = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor, queue: DispatchQueue.global(qos: .default))
            readSource.setEventHandler {
                guard let bytes = self.serialInterface?.receive(byteCount: 128),
                      let lastByte = bytes.last,
                      let audioState = SatelliteAudioState(rawValue: lastByte) else { return }
                
                print("[AudioSwitchMonitor] Changing audio state to \(audioState)")
                self.switcher?.setAudioState(audioState)
            }
            readSource.resume()
            
            source?.cancel()
            source = readSource
        }
    }
    
    deinit {
        source?.cancel()
    }
}
