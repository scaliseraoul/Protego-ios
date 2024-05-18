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
                        This app monitors audio to detect emergencies.
                        
                        The app listens for danger signs both in the foreground and background.
                        
                        Keep the app open when you feel unsafe, and close it when you are safe.
                        
                        🔒 No data is uploaded or stored.
                        """)
                .font(.body)
                .padding()
                
                /*
                 Text("Protego is listening...")
                 .font(.title)
                 .padding()
                 .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                 */
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
