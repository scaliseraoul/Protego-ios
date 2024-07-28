//
//  ContentView.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 01/05/24.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var soundClassifier: SoundClassifier
    @State private var showSettings = false
    
    init() {
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
                
                NavigationLink(
                    destination: EmergencyView().environmentObject(appState)
                        .environmentObject(soundClassifier), isActive: $appState.shouldNavigateToEmergency) {
                        }
                Spacer()
                Button(action: testEmergency) {
                    Text("Test Emergency")
                        .font(.footnote)
                        .padding()
                        .cornerRadius(10)
                }
            }
            .navigationBarTitle(Text("Protego"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        
    }
    
    func testEmergency() {
        soundClassifier.triggerEmergency()
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
        .environmentObject(SoundClassifier(appState: AppState()))
}
