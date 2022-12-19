//
//  AppCommands.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 11/28/22.
//

import Foundation

enum AppCommands: String ,CaseIterable, Identifiable {
    var id: String { self.rawValue }
    case none, go_to, enable_ar_for, show_info_for
}
