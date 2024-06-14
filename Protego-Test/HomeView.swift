//
//  ContentView.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 01/05/24.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var appState = AppState()
    @StateObject private var soundClassifier: SoundClassifier
    
    init() {
        let appState = AppState()
        _soundClassifier = StateObject(wrappedValue: SoundClassifier(appState: appState))
        _appState = StateObject(wrappedValue: appState)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                
                ProtegoImage(size: 100)
                    .padding(.bottom, 20)
                
                Text("""
                        This app listens for danger signs in the foreground and background to detect emergencies.
                        
                        📢 Keep it open and turn up the volume when you feel unsafe; close it when you're safe.
                        
                        🔒 No data is uploaded or stored.
                        """)
                .font(.body)
                .padding()
                WaveformView()
                    .padding()
                    .padding(.bottom,  0)
                
                Text(soundClassifier.classificationResult)
                    .font(.body)
                
                NavigationLink(destination: EmergencyView(soundClassifier: soundClassifier), isActive: $appState.shouldNavigateToEmergency) {
                }
                Spacer()
                Button(action: testEmergency) {
                    Text("Test Emergency")
                        .font(.footnote)
                        .padding()
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Protego")
        }
        
    }
    
    func testEmergency() {
        soundClassifier.triggerEmergency()
    }
}

#Preview {
    HomeView()
}
