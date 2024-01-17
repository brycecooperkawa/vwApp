//
//  CustomCar.swift
//  arVW
//
//  Created by Richard Zhou on 2023-10-24.
//

import UIKit

class CustomCar {
    
    var name = ""
    var colors = ColorSet()
    var accessories = AccessorySet()
    
    func makeDBString() -> String {
        let output = "&Modelname=" + name + colors.makeDBString() + accessories.makeDBString()
        return output
    }
    
    func parseDBString(dbstr: String) -> [String] {
        let components = dbstr.components(separatedBy: "&")
        return components
    }
}
