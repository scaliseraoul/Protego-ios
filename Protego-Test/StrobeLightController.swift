//
//  StrobeLightController.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 30/06/24.
//

import Foundation
import UIKit
import AVFoundation

class StrobeLightController {

    private var isStrobing = false
    private var timer: Timer?

    // Method to start the strobe light
    func startStrobe() {
        guard !isStrobing else { return }
        isStrobing = true

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.toggleFlash()
        }
    }

    // Method to stop the strobe light
    func stopStrobe() {
        guard isStrobing else { return }
        isStrobing = false

        timer?.invalidate()
        timer = nil
        setFlashState(on: false) // Ensure the light is off
    }

    // Method to toggle the flashlight on and off
    private func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
            } else {
                try device.setTorchModeOn(level: 1.0)
            }
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
    }

    // Ensure the flashlight is off
    private func setFlashState(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
    }
}
