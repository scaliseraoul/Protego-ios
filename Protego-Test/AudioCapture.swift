//
//  AudioCapture.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 17/05/24.
//

import AVFoundation

class AudioCapture: NSObject {
    private var audioEngine: AVAudioEngine!
    private var inputNode: AVAudioInputNode!

    override init() {
        super.init()
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.processAudioBuffer(buffer: buffer)
        }

        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }

    private func processAudioBuffer(buffer: AVAudioPCMBuffer) {
        // Process the audio buffer and make predictions using your ML model
    }
}

