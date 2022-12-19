//
//  DismissView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import SwiftUI

struct DismissView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    var body: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "x.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .tint(.white)
        }
    }
}

struct DismissView_Previews: PreviewProvider {
    static var previews: some View {
        DismissView()
    }
}
