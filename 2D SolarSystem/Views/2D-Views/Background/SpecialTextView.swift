//
//  SpecialTextView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/21/22.
//

import SwiftUI

struct SpecialTextView: View {
    let text: String
    var body: some View {
        Text(text)
            .bold()
            .foregroundColor(.black)
            .frame(width: UIScreen.main.bounds.width, height: 75)
            .background(RoundedRectangle(cornerRadius: 4).fill())
    }
}

struct SpecialTextView_Previews: PreviewProvider {
    static var previews: some View {
        SpecialTextView(text: "hey")
    }
}
