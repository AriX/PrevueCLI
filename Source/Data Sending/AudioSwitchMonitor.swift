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

protocol AudioStateObserver: class {
    func setAudioState(_ audioState: SatelliteAudioState)
}

class AudioSwitchMonitor {
    let serialInterface: FileDescriptorSerialInterface
    let source: DispatchSourceRead
    
    weak var switcher: AudioStateObserver?
    
    init?(serialInterface: FileDescriptorSerialInterface) {
        self.serialInterface = serialInterface
        
        guard let fileDescriptor = serialInterface.fileDescriptor else {
            print("[AudioSwitchMonitor] Failed to initialize because serial interface is not connected")
            return nil
        }
        
        source = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor, queue: DispatchQueue.global(qos: .default))
        source.setEventHandler { 
            guard let bytes = serialInterface.receive(byteCount: 128),
                  let lastByte = bytes.last,
                  let audioState = SatelliteAudioState(rawValue: lastByte) else { return }
            
            print("[AudioSwitchMonitor] Changing audio state to \(audioState)")
            self.switcher?.setAudioState(audioState)
        }
        source.resume()
    }
    
    deinit {
        source.cancel()
    }
}
