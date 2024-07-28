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

class SoundClassifier: NSObject, ObservableObject, SNResultsObserving {
    
    private let audioEngine = AVAudioEngine()
    private var soundClassifier: Protego?
    private var notificationsManager = NotificationsManager.shared
    private var appState: AppState
    private var audioPlayer: AVAudioPlayer?
    
    var inputFormat: AVAudioFormat!
    var analyzer: SNAudioStreamAnalyzer!
    let analysisQueue = DispatchQueue(label: "Raoul.Protego-Test")
    
    private var classificationWindow: [Bool] = []
    
    @Published var classificationResult: String = "Identifying sounds..."
    
    let strobeController = StrobeLightController()
    
    enum SystemAudioClassificationError: Error {
        case audioStreamInterrupted
        case noMicrophoneAccess
    }
    
    init(appState: AppState) {
        self.appState = appState
        super.init()
        do {
            try startAudioSession()
            initializeAudioEngine()
            NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        } catch {
            print("Failed to initialize audio session: \(error)")
        }
    }
    
    private func startAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers, .defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true)
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
    
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult,
              let classification = result.classifications.first,
              classification.confidence > 0.6 else { return }
        
        print("Got a classification: \(result.classifications)")
        
        DispatchQueue.main.async {
            self.classificationResult = "\(Int(classification.confidence * 100.0))% \(classification.identifier)"
            
            let test = false
            var aggressionThreshold = 4
            let windowSize = 5
            
            if test {
                aggressionThreshold = 1
            }
            
            // Update the window with the latest classification
            self.classificationWindow.append(classification.identifier == "aggression" && classification.confidence > 0.85)
            
            // Keep only the last 'windowSize' classifications
            if self.classificationWindow.count > windowSize {
                self.classificationWindow.removeFirst()
            }
            
            // Count aggression detections in the current window
            let aggressionCount = self.classificationWindow.filter { $0 }.count
            
            if aggressionCount >= aggressionThreshold {
                self.triggerEmergency()
                self.classificationWindow.removeAll() // Reset the window after triggering
            }
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
}
