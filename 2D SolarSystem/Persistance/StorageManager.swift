//
//  StorageManager.swift
//  US States
//
//  Created by Hannan, John Joseph on 10/17/22.
//

import Foundation

class StorageManager<T:Codable> {
    var modelData : T?
    let filename : String
    let fileInfo : FileInfo
    init(name:String, ext: String) {
        filename = name
        fileInfo = FileInfo(for: filename, ext: ext)
        if fileInfo.exists {
            let decoder = JSONDecoder()
            do {
                let data = try Data(contentsOf: fileInfo.url)
                modelData = try  decoder.decode(T.self, from: data)
            } catch {
                print(error)
                modelData = nil
            }
            return
        }
        // First time here -
        let solutionURL = Bundle.main.url(forResource: filename, withExtension: "json")
        do {
            let data = try Data(contentsOf: solutionURL!)
            let decoder = JSONDecoder()
            modelData = try decoder.decode(T.self, from: data)

        } catch { // Handle error
            print(error)
            modelData = nil
        }
    }
    
    func save(_ modelData: T) {
        do {
             let encoder = JSONEncoder()
            let datajson = try encoder.encode(modelData)
            try datajson.write(to: fileInfo.url)
        }
        catch {
            print(error)
        }
    }
}

