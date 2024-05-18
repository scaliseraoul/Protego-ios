//
//  AppState.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 18/05/24.
//

import Foundation

class AppState: ObservableObject {
    @Published var shouldNavigateToEmergency: Bool = false
}
