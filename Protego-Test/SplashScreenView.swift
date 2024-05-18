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
            Image("protego-transparent")
                .resizable()
                .frame(width: 100, height: 100)
                .padding(.bottom, 20)
            
            Spacer()
        }
    }
}



struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
