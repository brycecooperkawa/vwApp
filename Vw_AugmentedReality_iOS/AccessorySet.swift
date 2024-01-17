//
//  AccessorySet.swift
//  arVW
//
//  Created by Richard Zhou on 2023-10-24.
//

/*
 * This class defines a collection of Accessories that are to be used once
 * the AR application is loaded.
 */
class AccessorySet {

    private var accListAtPos: [String: [String]]!
    private var allAccessories = [String]()
    private var posAtAcc: [String: (String, Bool)]! // [Accessory : (Position, Boolean visibility)]
    private var posVisibility: [String: Bool]! // [Position : Boolean visibility]
    private var positions = ["Top Left", "Top Middle", "Top Right"]
    
    var posInteractions = [String: [String] ]() // Interactions between accessory positions
    // eg. ["TopMiddle": ["TopMiddle", "TopLeft", "TopRight"] ]
    
    var searching = false
    var filterText = ""
    
    func loadInteractions() {
        for pos in posVisibility.keys {
            posInteractions[pos] = [pos] // All positions interact with themselves at least
        }
        posInteractions["Top Left"]!.append("Top Middle")
        posInteractions["Top Right"]!.append("Top Middle")
        posInteractions["Top Middle"]!.append(contentsOf: ["Top Left", "Top Right"])
    }
    
    func loadAccessories(accListAtPos: [String: [String]]) {
        self.accListAtPos = accListAtPos
        posAtAcc = [:]
        posVisibility = [:]
        
        for (pos, accList) in accListAtPos {
            // Set relationship dictionary for accessory position and visibility
            for acc in accList {
                posAtAcc[acc] = (pos, false)
                allAccessories.append(acc)
            }
            
            // Create visibility tracker from available positions (init to "not visible")
            posVisibility[pos] = false
        }
        
        loadInteractions()
    }
    
    func checkClash(acc: String) -> Bool {

        var clash = false
        
        let interactions = posInteractions[posAtAcc[acc]!.0]!
        
        for pos in interactions {
            if posVisibility[pos]! {
                clash = true
                break
            }
        }
        
        return clash // true if clash, false if there was no clash
    }
    
    func toggleOn(acc: String) {
        posAtAcc[acc]!.1 = true
        posVisibility[posAtAcc[acc]!.0] = true
    }
    
    func toggleOff(acc: String) {
        posAtAcc[acc]!.1 = false
        posVisibility[posAtAcc[acc]!.0] = false
    }
    
    func getVisibilityOf(acc: String) -> Bool {
        return posAtAcc[acc]!.1
    }
    
    func getPositions() -> [String] {
        return positions
    }
    
    func getNames() -> [String] {
        return allAccessories
    }
    
    func getAccessoriesAtPos(pos: String) -> [String] {
        if filterText == "" {
            return accListAtPos[pos]!
        } else {
            return accListAtPos[pos]!.filter({$0.lowercased().hasPrefix(filterText.lowercased())})
        }
    }
    
    func makeDBString() -> String {
        var output = ""
        
        for (acc, info) in posAtAcc {
            if info.1 == true {
                output += "&" + info.0.replacingOccurrences(of: " ", with: "")
                output += "=" + acc
            } else {
                output += "&" + info.0.replacingOccurrences(of: " ", with: "")
                output += "=" + "null"
            }
        }
        
        return output
    }
    
}
