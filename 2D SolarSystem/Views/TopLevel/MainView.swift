//
//  ContentView.swift
//  2D SolarSystem
//
//  Created by David Rohweder on 10/30/22.
//

//REF:
// 2d transparent planet pics :: https://nineplanets.org/planets-transparent-background/
// 3d planet models :: https://solarsystem.nasa.gov/resources/all/?order=pub_date+desc&per_page=50&page=0&search=&condition_1=1%3Ais_in_resource_list&fs=&fc=324&ft=&dp=&category=324
// planet data :: https://nssdc.gsfc.nasa.gov/planetary/factsheet/


import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: PlanetManager
    @AppStorage("Constants.Preferences.UserAge") var userAge : Int = 0
    var body: some View {
        switch(manager.show_dim) {
        case .dim_two:
            if userAge != 0 {
                Main_Flat()
            } else {
                SetUserAgeView()
            }
        case .dim_two_single:
            SelectedPlanetView(planet: manager.currentPlanet)
        case .dim_three:
            AR_Main()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
