//
//  WaveformView.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 18/05/24.
//

import Foundation
import SwiftUI

struct WaveformView: View {
    @State private var phase: CGFloat = 0
    @State private var timer: Timer?
    
    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            let amplitude: CGFloat = 20
            let path = Path { path in
                path.move(to: CGPoint(x: 0, y: midY + sin(phase) * amplitude))
                for x in stride(from: 1, through: size.width, by: 1) {
                    let angle = (x / size.width) * .pi * 2 + phase
                    let y = midY + sin(angle) * amplitude
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(path, with: .color(.primary), lineWidth: 4)
        }
        .frame(height: 50)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            withAnimation(.linear(duration: 0.01)) {
                phase += .pi / 45
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct WaveformView_Previews: PreviewProvider {
    static var previews: some View {
        WaveformView()
    }
}
