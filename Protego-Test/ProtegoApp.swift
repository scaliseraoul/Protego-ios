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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var appState = AppState()
    
    init() {
        
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .onAppear {
                    appState.currentView = .splashScreen
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
    
    struct RootView: View {
        @EnvironmentObject var appState: AppState

        var body: some View {
            switch appState.currentView {
            case .splashScreen:
                SplashScreenView()
                    .onAppear {
                        PermissionsManager.arePermissionsGranted { granted in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                if granted {
                                    appState.currentView = .home
                                }
                                else {
                                    appState.currentView = .onboarding
                                }
                            }
                        }
                    }
            case .onboarding:
                OnboardingView()
            case .home:
                HomeView()
            }
        }
    }
}
