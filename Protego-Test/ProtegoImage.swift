//
//  ProtegoImage.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 18/05/24.
//

import Foundation
import SwiftUI

struct ProtegoImage: View {
    @Environment(\.colorScheme) var colorScheme
    var size: CGFloat
    
    var body: some View {
        if colorScheme == .light {
            Image("protego-transparent-light")
                .resizable()
                .frame(width: size, height: size)
        } else {
            Image("protego-transparent-dark")
                .resizable()
                .frame(width: size, height: size)
        }
    }
}

struct ProtegoImage_Previews: PreviewProvider {
    static var previews: some View {
        ProtegoImage( size: 120)
    }
}
