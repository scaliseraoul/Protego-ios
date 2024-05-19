//
//  SplashScreen.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 18/05/24.
//

import Foundation
import SwiftUI

struct SplashScreenView: View {
    
    var body: some View {
        VStack {
            Spacer()
            ProtegoImage(size: 100)
            Spacer()
        }
    }
}



struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
