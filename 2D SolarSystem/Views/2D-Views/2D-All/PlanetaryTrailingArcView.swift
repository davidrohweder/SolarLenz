//
//  PlanetaryTrailingArcView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/21/22.
//

import SwiftUI

// end angle is start, and start is end
struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)

        return path
    }
}
