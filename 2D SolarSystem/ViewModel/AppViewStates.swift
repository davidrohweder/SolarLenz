//
//  AppViewStates.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/16/22.
//

import Foundation


enum ViewStates: String ,CaseIterable, Identifiable {
    var id: String { self.rawValue }
    case dim_two, dim_three, dim_two_single
}
