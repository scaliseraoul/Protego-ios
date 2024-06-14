//
//  AppState.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 18/05/24.
//

import Foundation

class AppState: ObservableObject {
    @Published var shouldNavigateToEmergency: Bool = false
    
    enum FirstViewState {
        case splashScreen
        case onboarding
        case home
    }
    
    @Published var currentView: FirstViewState = .splashScreen
}
