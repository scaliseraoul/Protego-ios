//
//  PermissionsManager.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 18/05/24.
//

import Foundation
import AVFoundation
import UserNotifications

class PermissionsManager : NSObject{
    static let shared = PermissionsManager()
    
    private override init() {
        super.init()
    }
    
    static func ensureMicrophoneAccess(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        case .authorized:
            completion(true)
        @unknown default:
            fatalError("Unknown authorization status for microphone access")
        }
    }
    
    static func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            completion(granted)
        }
    }
    
    static func requestCriticalAlertPermission(completion: @escaping (Bool) -> Void) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.criticalAlert]) { granted, error in
                completion(granted)
            }
    }
    
    static func arePermissionsGranted(completion: @escaping (Bool) -> Void) {
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        completion(microphoneStatus == .authorized)
    }
    
}
