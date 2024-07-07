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
import TensorFlowLite

class SoundClassifier: NSObject, ObservableObject {
    
    private let audioEngine = AVAudioEngine()
    private var interpreter: Interpreter!
    private var notificationsManager = NotificationsManager.shared
    private var appState: AppState
    private var audioPlayer: AVAudioPlayer?
    
    let analysisQueue = DispatchQueue(label: "Raoul.Protego-Test")
    private let conversionQueue = DispatchQueue(label: "conversionQueue")

    
    private var aggressionCount = 0
    
    @Published var classificationResult: String = "Identifying sounds..."
    
    let strobeController = StrobeLightController()
    
    private var sampleRate = 16000
    private let requiredSamples = 15600
    private var audioDataBuffer = [Int16]()
    
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
    
    private func initializeAudioEngine() {
        let inputNode = audioEngine.inputNode
        let inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
        
        
        guard let recordingFormat = AVAudioFormat(
          commonFormat: .pcmFormatInt16,
          sampleRate: Double(sampleRate),
          channels: 1,
          interleaved: true
        ), let formatConverter = AVAudioConverter(from:inputFormat, to: recordingFormat) else { return }
        
        let bufferSize = 16000
        
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(bufferSize), format: inputFormat) { [weak self] buffer, time in
            
            self!.conversionQueue.async {
              // An AVAudioConverter is used to convert the microphone input to the format required
              // for the model.(pcm 16)
              guard let pcmBuffer = AVAudioPCMBuffer(
                pcmFormat: recordingFormat,
                frameCapacity: AVAudioFrameCount(bufferSize)
              ) else { return }

              var error: NSError?
              let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = AVAudioConverterInputStatus.haveData
                return buffer
              }

              formatConverter.convert(to: pcmBuffer, error: &error, withInputFrom: inputBlock)

              if let error = error {
                print(error.localizedDescription)
                return
              }
              if let channelData = pcmBuffer.int16ChannelData {
                let channelDataValue = channelData.pointee
                let channelDataValueArray = stride(
                  from: 0,
                  to: Int(pcmBuffer.frameLength),
                  by: buffer.stride
                ).map { channelDataValue[$0] }

                // Converted pcm 16 values are delegated to the controller.
                self!.analysisQueue.async {
                    self!.analyzeBuffer(inputBuffer: channelDataValueArray)
                }
              }
            }
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("Error during audio engine setup: \(error)")
        }
    }
    
    private func initializeInterpreter() {
        guard let modelPath = Bundle.main.path(forResource: "sound_classifier_yamnet", ofType: "tflite") else {
            fatalError("Failed to load model file.")
        }

        do {
            interpreter = try Interpreter(modelPath: modelPath)
            try interpreter!.allocateTensors()
            let inputTensor = try interpreter.input(at: 0)
            print("Input tensor shape: \(inputTensor.shape)")
            print("Input tensor dataType: \(inputTensor.dataType)")
        } catch {
            fatalError("Failed to create interpreter: \(error.localizedDescription)")
        }
    }
    
    private func analyzeBuffer(inputBuffer: [Int16]) {
        let outputTensor: Tensor
        do {
          let audioBufferData = int16ArrayToData(inputBuffer)
          try interpreter.copy(audioBufferData, toInputAt: 0)
          try interpreter.invoke()

          outputTensor = try interpreter.output(at: 0)
        } catch let error {
          print(">>> Failed to invoke the interpreter with error: \(error.localizedDescription)")
          return
        }
    }
    

    
    private func handleClassificationResult(_ results: [Float32]) {
        guard results.count > 1 else { return }
        let aggressionConfidence = results[0]
        let neutralConfidence = results[1]
        
        if aggressionConfidence > 0.6 {
            self.classificationResult = "\(Int(aggressionConfidence * 100.0))% Aggression"
            if aggressionConfidence > 0.9 {
                self.aggressionCount += 1
                if self.aggressionCount >= 2 {
                    //self.triggerEmergency()
                    self.aggressionCount = 0
                }
            }
        } else if neutralConfidence > 0.6 {
            self.classificationResult = "\(Int(neutralConfidence * 100.0))% Neutral"
            self.aggressionCount = 0
        } else {
            self.classificationResult = "Identifying sounds..."
            self.aggressionCount = 0
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
