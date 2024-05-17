//
//  ContentView.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 01/05/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = SoundClassifierViewModel()

    var body: some View {
        VStack {
            Text("Detecting hazardous situations in real-time...")
                .font(.title)
                .padding()
            Text(viewModel.classificationResult)
                .font(.title2)
                .padding()
            }
    }
}

#Preview {
    ContentView()
}
