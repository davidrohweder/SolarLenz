//
//  AgePickerView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import SwiftUI

struct AgePickerView: View {
    @AppStorage("Constants.Preferences.UserAge") var userAge : Int = 0
    var body: some View {
        Picker("User Age", selection: $userAge) {
            ForEach(0..<100) { i in
                Text("\(i) years old").bold().tag(i)
            }
        }
        .background(RoundedRectangle(cornerRadius: 4).fill(.black).frame(width: UIScreen.main.bounds.width, height: 100))
        .tint(.white)
    }
}

struct AgePickerView_Previews: PreviewProvider {
    static var previews: some View {
        AgePickerView()
    }
}
