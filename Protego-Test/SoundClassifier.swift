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
import MediaPlayer
import AudioToolbox
import TensorFlowLiteTaskAudio
import AVFoundation

class SoundClassifier: NSObject, ObservableObject {
    
    private let audioEngine = AVAudioEngine()
    private var notificationsManager = NotificationsManager.shared
    private var appState: AppState
    private var audioPlayer: AVAudioPlayer?
    
    private var aggressionCount = 0
    
    @Published var classificationResult: String = "Identifying sounds..."
    
    let strobeController = StrobeLightController()
    
    init(appState: AppState) {
        self.appState = appState
        super.init()
        do {
            try startAudioSession()
            initializeInterpreter()
            NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
            scheduleListeningNotification()
        } catch {
            print("Failed to initialize audio session: \(error)")
        }
    }
    
    private func startAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true)
    }
    
    private func initializeInterpreter() {
        guard let modelPath = Bundle.main.path(forResource: "yament_tflite_classification", ofType: "tflite") else {
            print("Failed to find model file")
            return
        }
        
        do {
            let options = AudioClassifierOptions(modelPath: modelPath)
            let classifier = try AudioClassifier.classifier(options: options)
            let audioTensor = classifier.createInputAudioTensor()
            let audioRecord = try classifier.createAudioRecord()
            
            // Request microphone permissions before starting recording
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                guard granted else {
                    print("Microphone permission denied")
                    return
                }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try audioRecord.startRecording()
                        print("Audio recording started")
                        
                        // Wait a bit for the recording to start
                        Thread.sleep(forTimeInterval: 1.0)
                        
                        while true {
                            do {
                                try audioTensor.load(audioRecord: audioRecord)
                                let classificationResult = try classifier.classify(audioTensor: audioTensor)
                                
                                DispatchQueue.main.async {
                                    self?.handleClassificationResult(classificationResult)
                                }
                                
                                // Add a small delay between classifications
                                Thread.sleep(forTimeInterval: 0.1)
                            } catch {
                                print("Error during classification: \(error)")
                                // If there's an error, wait a bit before trying again
                                Thread.sleep(forTimeInterval: 1.0)
                            }
                        }
                    } catch {
                        print("Error starting audio recording: \(error)")
                    }
                }
            }
        } catch {
            print("Failed to initialize classifier: \(error)")
        }
    }
    
    
    private func handleClassificationResult(_ result: ClassificationResult) {
        let topClassification = result.classifications[0].categories.max { $0.score < $1.score }
        
        if let topClass = topClassification {
            self.classificationResult = "\(topClass.label): \(Int(topClass.score * 100))%"
            
            if topClass.label == "Aggression" && topClass.score > 0.6 {
                self.aggressionCount += 1
                if self.aggressionCount >= 2 {
                    // self.triggerEmergency()
                    self.aggressionCount = 0
                }
            } else {
                self.aggressionCount = 0
            }
        } else {
            self.classificationResult = "Identifying sounds..."
        }
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            audioEngine.pause()
        case .ended:
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                try audioEngine.start()
            } catch {
                print("Failed to restart audio engine: \(error)")
            }
        @unknown default:
            break
        }
    }
    
    func scheduleListeningNotification() {
        let title = "Protego is listening"
        let body = "No data is stored or uploaded."
        let interval = 1800.0 // Every 30 min
        let identifier = "ListeningNotification"
        
        notificationsManager.scheduleRecurringNotification(title: title, body: body, timeInterval: interval, identifier: identifier)
    }
    
    func triggerEmergency() {
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        } catch {
            print("Error during overrideOutputAudioPort: \(error)")
        }
        
        self.appState.shouldNavigateToEmergency = true
        self.playEmergencySound()
        strobeController.startStrobe()
        
        if UIApplication.shared.applicationState == .background {
            let title = "Emergency Detected"
            let body = "Open the app to call emergency services"
            notificationsManager.scheduleSingleNotification(title: title, body: body)
        }
    }
    
    func stopEmergency() {
        self.appState.shouldNavigateToEmergency = false
        stopEmergencySound()
        strobeController.stopStrobe()
    }
    
    func playEmergencySound() {
        guard let url = Bundle.main.url(forResource: "alarm", withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 1.0 // Set volume to maximum
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    
    func stopEmergencySound() {
        audioPlayer?.stop()
    }
    
    /// Creates a new buffer by copying the buffer pointer of the given `Int16` array.
    private func int16ArrayToData(_ buffer: [Int16]) -> Data {
        let floatData = buffer.map { Float($0) / 32768.0 }
        return floatData.withUnsafeBufferPointer(Data.init)
    }
    
    /// Creates a new array from the bytes of the given unsafe data.
    /// - Returns: `nil` if `unsafeData.count` is not a multiple of `MemoryLayout<Float>.stride`.
    private func dataToFloatArray(_ data: Data) -> [Float]? {
        guard data.count % MemoryLayout<Float>.stride == 0 else { return nil }
        
#if swift(>=5.0)
        return data.withUnsafeBytes { .init($0.bindMemory(to: Float.self)) }
#else
        return data.withUnsafeBytes {
            .init(UnsafeBufferPointer<Float>(
                start: $0,
                count: unsafeData.count / MemoryLayout<Element>.stride
            ))
        }
#endif // swift(>=5.0)
    }
}
