//
//  FileInfo.swift
//  2D Solar System
//
//  Created by Hannan, John Joseph on 10/17/22.
//

import Foundation

/// Convenient struct for generating URL and exists property
/// for a file in the documents directory
struct FileInfo {
    let name : String
    let url : URL
    let exists : Bool
    
    init(for filename:String, ext: String) {
        name = filename
        let fileManager = FileManager.default
        let documentURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url =  documentURL.appendingPathComponent(filename + ext)
        exists = fileManager.fileExists(atPath: url.path)
    }
    
    private init(name:String, url:URL, exists:Bool) {
        self.init(for:"", ext: ".json")
    }
}
