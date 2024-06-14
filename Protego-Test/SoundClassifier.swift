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

class SoundClassifier:  NSObject, ObservableObject, SNResultsObserving {
    
    private let audioEngine = AVAudioEngine()
    private var soundClassifier: Protego?
    private var notificationsManager = NotificationsManager.shared
    private var appState: AppState
    private var audioPlayer: AVAudioPlayer?
    
    var inputFormat: AVAudioFormat!
    var analyzer: SNAudioStreamAnalyzer!
    let analysisQueue = DispatchQueue(label: "Raoul.Protego-Test")
    
    private var aggressionCount = 0
    
    @Published var classificationResult: String = "Identifying sounds..."
    
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
            scheduleListeningNotification()
        } catch {
        }
    }
    
    private func startAudioSession() throws {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.interruptSpokenAudioAndMixWithOthers])
            try audioSession.setActive(true)
            try audioSession.overrideOutputAudioPort(.speaker)
        } catch {
            throw error
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
    
    func request(_ request: SNRequest, didProduce result: SNResult) {
        
        
        guard let result = result as? SNClassificationResult,
              let classification = result.classifications.first,
              classification.confidence > 0.6 else { return }
        
        print("Got a classification: \(result.classifications)")
        
        DispatchQueue.main.async {
            self.classificationResult = "\(Int(classification.confidence * 100.0))% \(classification.identifier)"
            
            let test = false
            var aggressionThreshold = 2
            
            if test {
                aggressionThreshold = 5
            }
            
            if test || ( classification.identifier == "aggression" && classification.confidence > 0.9 )  {
                self.aggressionCount += 1
                if self.aggressionCount >= aggressionThreshold {
                    self.triggerEmergency()
                    self.aggressionCount = 0
                }
            } else {
                self.aggressionCount = 0
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
                audioEngine.prepare()
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
        let interval = 1800.0 //every 30 min
        let identifier = "ListeningNotification"
        
        notificationsManager.scheduleRecurringNotification(title: title, body: body, timeInterval: interval, identifier: identifier)
    }
    
    func triggerEmergency() {
        
        self.appState.shouldNavigateToEmergency = true
        self.playEmergencySound()
        self.triggerVibration()
        
        if UIApplication.shared.applicationState == .background {
            let title = "Emergency Detected"
            let body = "Open the app to call emergency services"
            notificationsManager.scheduleSingleNotification(title: title, body: body)
        }
    }
    
    func stopEmergency() {
        self.appState.shouldNavigateToEmergency = false
        stopEmergencySound()
    }
    
    func playEmergencySound() {
        guard let url = Bundle.main.url(forResource: "alarm", withExtension: "mp3") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 1.0 // Set volume to maximum within the app's audio session
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    
    func stopEmergencySound() {
        audioPlayer?.stop()
    }
    
    private func triggerVibration() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
