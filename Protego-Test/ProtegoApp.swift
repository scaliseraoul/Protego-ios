//
//  Protego_TestApp.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 01/05/24.
//

import SwiftUI

@main
struct ProtegoApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    private var permissionManager = PermissionsManager.shared
    private var notificationsManager = NotificationsManager.shared
    @State private var showOnboarding = true
    @State private var showSplashscreen = true
    
    init() {
        
    }
    
    var body: some Scene {
        WindowGroup {
            
            if showSplashscreen {
                SplashScreenView()
                    .onAppear {
                        PermissionsManager.arePermissionsGranted { granted in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                showOnboarding = !granted
                                showSplashscreen = false
                            }
                        }
                    }
            } else {
                if showOnboarding {
                    OnboardingView(isOnboardingComplete: $showOnboarding)
                } else {
                    HomeView()
                }
            }
            
            
        }.onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                //notificationsManager.scheduleSingleNotification(title: "Protego is listening", body: "No data is uploaded or stored.")
            } else if newPhase == .active {
                //scheduleAppBackgroundNotification(state: "active")
            } else if newPhase == .inactive {
                //scheduleAppBackgroundNotification(state: "inactive")
            }
        }
    }
}
