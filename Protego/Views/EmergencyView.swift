//
//  EmergencyView.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 18/05/24.
//

import Foundation
import SwiftUI

struct EmergencyView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var soundClassifier: SoundClassifier
    @Environment(\.presentationMode) var presentationMode
    var emergencyNumber: String {
        appState.emergencyNumber
    }
    
    var body: some View {
        VStack {
            
            Spacer()
            
            Text("Protego detected an emergency.")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("If this is a false alarm, please cancel immediately by tapping the 'Cancel' button below.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: callEmergency) {
                Text("Call Emergency Services - \(emergencyNumber)")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            .padding(.bottom, 20)
            
            Button(action: {
                soundClassifier.stopEmergency()
            }) {
                VStack {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                    Text("Cancel")
                }
                .padding(.bottom, 20)
            }
            .navigationBarBackButtonHidden(true)
            .padding(.bottom)
        }
        .onAppear {
            callEmergency()
        }
    }
    
    private func callEmergency() {
        guard let url = URL(string: "tel://\(emergencyNumber)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

struct EmergencyView_Previews: PreviewProvider {
    static var previews: some View {
        EmergencyView()
            .environmentObject(AppState())
            .environmentObject(SoundClassifier(appState: AppState()))
    }
}
