//
//  OnboardingView.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 18/05/24.
//

import Foundation
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var permissionDenied = false
    
    var body: some View {
        VStack {
            Spacer()
            
            ProtegoImage(size: 80)
                .padding(.bottom, 20)
            
            Text("Welcome to Protego")
                .font(.title)
                .padding(.bottom, 10)
            
            Text("""
                    This app monitors audio to detect emergencies.
                    
                    We need access to your microphone and permission to send notifications.
                    
                    The app listens for danger signs both in the foreground and background.
                    
                    Keep the app open when you feel unsafe, and close it when you are safe.
                    
                    🔒 No data is uploaded or stored.
                    """)
            .font(.body)
            .padding()
            
            if permissionDenied {
                Text("Permissions were denied. Please enable permissions in settings to proceed.")
                    .foregroundColor(.red)
                    .padding()
                
                Button(action: openSettings) {
                    Text("Go to Settings")
                        .font(.headline)
                        .padding()
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            } else {
                Button(action: requestPermissions) {
                    Text("Enable Permissions")
                        .font(.headline)
                        .padding()
                        .cornerRadius(10)
                }
                .padding(.top, 20)
            }
            
            
            
            Spacer()
        }
        .padding()
    }
    
    private func requestPermissions() {
        PermissionsManager.ensureMicrophoneAccess { microphoneGranted in
            if microphoneGranted {
                PermissionsManager.requestNotificationPermission { notificationGranted in
                    DispatchQueue.main.async {
                        if notificationGranted {
                            appState.currentView = .home
                        } else {
                            permissionDenied = true
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    permissionDenied = true
                }
            }
        }
    }
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: nil)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
