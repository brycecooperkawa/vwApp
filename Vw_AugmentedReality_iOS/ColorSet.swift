//
//  ColorSet.swift
//  arVW
//
//  Created by Richard Zhou on 2023-10-24.
//

import UIKit

/*
 * This class defines a collection of UIColors that are to be applied
 * to vehicle scenes once the AR app is loaded.
 */
class ColorSet {
    
    private var colors: [String: UIColor]!
    private var names: [String]!
    
    var currentColor = ""
    
    /// Load a list of UIColors along with a dictionary attributing hexcode names to the list indices.
    func loadColors(c: [String: UIColor]!) {
        self.colors = c
    }
    
    /// Set a list of hex string color names to constrict the user's options for a select car.
    func setNames(u: [String]!) {
        self.names = u
    }
    
    /// Get the list of usable colors. This function should primarily be
    /// used to determine the number of colored cells to add to a table.
    func getNames() -> [String]! {
        return self.names
    }
    
    /// Get the usable color at the index specified. This function should
    /// primarily interact with cell selection in CustomizationViewController.
    func getUsableColorAt(i: Int) -> UIColor! {
        currentColor = names[i]
        return colors[currentColor]!
    }
    
    func makeDBString() -> String {
        return "&Color=" + currentColor
    }
    
    func hexToUI(hex: String) -> UIColor {
        let scanner = Scanner(string: hex)
        var hexNumber: UInt64 = 0

        scanner.scanHexInt64(&hexNumber)
        
        let r = CGFloat((hexNumber & 0xffff0000) >> 16) / 255
        let g = CGFloat((hexNumber & 0xff00ff00) >> 8) / 255
        let b = CGFloat((hexNumber & 0xff0000ff)) / 255
        
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
    
}
