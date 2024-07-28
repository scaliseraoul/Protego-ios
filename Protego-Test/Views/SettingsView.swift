//
//  SettingsView.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 28/07/24.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEmergencyNumberDialog = false
    @State private var tempEmergencyNumber = ""
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Emergency")) {
                    HStack {
                        Text("Emergency Number")
                        Spacer()
                        Text(appState.emergencyNumber)
                        Button("Edit") {
                            tempEmergencyNumber = appState.emergencyNumber
                            showingEmergencyNumberDialog = true
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    Text("Version 1.0")
                    Text("© 2024 Protego")
                    Link("Contact Us", destination: URL(string: "mailto:scaliseraoul00@gmail.com")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert("Set Emergency Number", isPresented: $showingEmergencyNumberDialog) {
                TextField("Emergency Number", text: $tempEmergencyNumber)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    if !tempEmergencyNumber.isEmpty {
                        appState.emergencyNumber = tempEmergencyNumber
                    }
                }
            } message: {
                Text("Please enter the emergency number for your location.")
            }
        }
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppState())
    }
}
