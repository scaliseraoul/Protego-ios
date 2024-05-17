//
//  SoundClassifierViewModel.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 01/05/24.
//

import Foundation
import AVFoundation
import SoundAnalysis
import SwiftUI

class SoundClassifierViewModel: NSObject, ObservableObject {
    
    private let audioEngine = AVAudioEngine()
    private var soundClassifier: Protego?

    var inputFormat: AVAudioFormat!
    var analyzer: SNAudioStreamAnalyzer!
    let analysisQueue = DispatchQueue(label: "Raoul.Protego-Test")
    
    @Published var classificationResult: String = "Speak, and I will classify..."
    
    enum SystemAudioClassificationError: Error {

        /// The app encounters an interruption during audio recording.
        case audioStreamInterrupted

        /// The app doesn't have permission to access microphone input.
        case noMicrophoneAccess
    }
    
    override init() {
        super.init()
        do {
            try ensureMicrophoneAccess()
            try startAudioSession()
            initializeAudioEngine()
        } catch {
        }
    }
    
    private func startAudioSession() throws {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
        } catch {
            throw error
        }
    }
    
    private func ensureMicrophoneAccess() throws {
        var hasMicrophoneAccess = false
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            let sem = DispatchSemaphore(value: 0)
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { success in
                hasMicrophoneAccess = success
                sem.signal()
            })
            _ = sem.wait(timeout: DispatchTime.distantFuture)
        case .denied, .restricted:
            break
        case .authorized:
            hasMicrophoneAccess = true
        @unknown default:
            fatalError("unknown authorization status for microphone access")
        }

        if !hasMicrophoneAccess {
            throw SystemAudioClassificationError.noMicrophoneAccess
        }
    }
    
    private func initializeAudioEngine() {
        do {
            soundClassifier = try Protego()
            inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
            analyzer = SNAudioStreamAnalyzer(format: inputFormat)
            let request = try SNClassifySoundRequest(mlModel: soundClassifier!.model)
            try analyzer.add(request, withObserver: self)

            audioEngine.inputNode.installTap(onBus: 0, bufferSize: 8000, format: inputFormat) { [weak self] buffer, time in
                self?.analysisQueue.async {
                    self?.analyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
                }
            }
            try audioEngine.start()
            
        } catch {
            print("Error during audio engine setup: \(error)")
        }
    }
}

extension SoundClassifierViewModel: SNResultsObserving {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
              let classification = result.classifications.first,
              classification.confidence > 0.6 else { return }
        
        DispatchQueue.main.async {
            self.classificationResult = "Recognition: \(classification.identifier)\nConfidence: \(Int(classification.confidence * 100.0))%"
        }
    }
}

