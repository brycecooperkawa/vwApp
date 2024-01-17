//
//  SelectionViewController.swift
//  arVW
//
//  Created by Richard Zhou on 2023-10-31.
//

import UIKit
import SceneKit
import RealityKit
import ARKit

struct Garage {
    var baseModels = [(String, String, Int)]() // Display name, car ID, Cell ID
    var customModels = [(String, String, String, [String], Int)]() // Display name, ID, color, accessory list, Cell ID
    
    var filterText = ""
    var selectionTracker = [Int]() // Up to 2 Cell IDs
    
    func getBase() -> [(String, String, Int)] {
        if filterText != "" {
            return baseModels.filter({$0.0.lowercased().hasPrefix(filterText.lowercased())})
        } else {
            return baseModels
        }
    }
    
    func getCustom() -> [(String, String, String, [String], Int)] {
        if filterText != "" {
            return customModels.filter({$0.0.lowercased().hasPrefix(filterText.lowercased())})
        } else {
            return customModels
        }
    }
    
    mutating func toggleOn(cellID: Int) {
        selectionTracker.append(cellID)
    }
    
    mutating func toggleOff(cellID: Int) {
        //if selectionTracker.contains(cellID) { // Toggle OFF
        var i = 0
        while i < selectionTracker.count {
            if selectionTracker[i] == cellID {
                break
            }
            i += 1
        }
        selectionTracker.remove(at: i)
    }
    
    func checkSelected(cellID: Int) -> Bool {
        return selectionTracker.contains(cellID)
    }
    
    func carWithID(cellID: Int) -> Any {
        if cellID < 0 {
            for car in baseModels {
                if car.2 == cellID { return car }
            }
        } else {
            for car in customModels {
                if car.4 == cellID { return car }
            }
        }
        return baseModels[0]
    }
    
    func IDtoIndex(cellID: Int) -> IndexPath {
        if cellID < 0 { // Base models
            for i in 0...baseModels.count-1 {
                if baseModels[i].2 == cellID {
                    return IndexPath(row: i, section: 0)
                }
            }
        } else {
            for i in 0...customModels.count-1 {
                if customModels[i].4 == cellID {
                    return IndexPath(row: i, section: 1)
                }
            }
        }
        return IndexPath(row: 0, section: 0)
    }
}

class SelectionViewController: UIViewController {
    
    @IBOutlet weak var deleteButt: UIButton!
    @IBOutlet var selectionTable: UITableView!
    //private var selectedCells = [IndexPath]()
    @IBOutlet var carSearch: UISearchBar!
    
    var garage = Garage()

    var carScenes: [String: SCNScene] = [:]
    var carModels: [String: (ModelEntity, String?)] = [:]
    var carName: String?
    var carEntity = ModelEntity()
        
    var realityKitObjects: [Entity] = []
    var sceneKitObjects: [(SCNNode,ARAnchor)] = []
    var imageObjects: [String: UIImage] = [:]
    
    var imageDict: [String: UIImage] = [:]
    var beforeURL: String = "https://fkypvd2hglkhkrfa4sqdd4pi5y0ndngt.lambda-url.us-east-2.on.aws/?User="
    
    
//    var accessories: [String: SCNNode] = [:]
    var accessories: [String: (SCNNode, Any)] = [:]
    var websites: [String: String] = [:]
    var checkAccessory: [String: (Bool, Any)] = [:]
    var interiorPositions: [String: String] = [:]
    var colorsForVehicle: [String: String] = [:]
    
    var userCredentials: (String, String)!
    var configList = [[String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deleteButt.isEnabled = false
        
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first{
            do{
                let documentsContents = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: [])
                
                var cellid = -1 // Base models are identified by negative integers
                for key in websites.keys {
                    if !(checkAccessory[key]?.0 ?? true){ // we want only models, not accessories or null
                        let nameFormatted = key.components(separatedBy: "_")
                        var displayName = ""
                        if nameFormatted.count > 1 {
                            for i in 1...nameFormatted.count-1 {
                                displayName += nameFormatted[i]
                                if i < nameFormatted.count-1 {
                                    displayName += " "
                                }
                            }
                        }
                        garage.baseModels.append((displayName, key, cellid))
                        cellid -= 1
                    }
                }
                
                for fileURL in documentsContents{
                    let url = fileURL.lastPathComponent
                    let name = url.components(separatedBy: ".")[0]
                    if fileURL.pathExtension == "png"{
                        let model_name = String(fileURL.lastPathComponent)
                        self.imageDict[String(model_name.dropLast(4))] = UIImage(contentsOfFile: fileURL.path)
                    } else {
                        do{
                            if checkAccessory[name]!.0 == true {
                                // If the file start is from the accessory database
                                let temp = try SCNScene(url: fileURL, options: nil)
                                accessories[name] = (temp.rootNode, checkAccessory[name]!.1)
                            } else {
                                let temp = try SCNScene(url: fileURL, options: nil)
                                carScenes[name] = temp
                                
                                let temp2 = try ModelEntity.loadModel(contentsOf: fileURL)
                                temp2.name = name
                                carModels[name] = (temp2, interiorPositions[name])
                            }
                        }
                        catch{
                            print("Error loading scene from \(fileURL): \(error)")
                        }
                    }
                }
            } catch{
                print("Error listing contents of 'Documents' directory: \(error)")
            }
        }
        
        var cellid = 0 // Custom configs are identified by 0+ integers
        for conf in configList {
            let name = conf[8]
            let car = conf[2]
            let col = conf[4]
            var accs = [String]()
            if conf[5] != "null" { accs.append(conf[5]) }
            if conf[6] != "null" { accs.append(conf[6]) }
            if conf[7] != "null" { accs.append(conf[7]) }
            garage.customModels.append((name, car, col, accs, cellid))
            cellid += 1
        }
        
        selectionTable.delegate = self
        selectionTable.dataSource = self
        
        carSearch.delegate = self

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    func enableButtons(name: String = "") {
        for case let button as UIButton in self.view.subviews {
            if name != "" {
                if button.titleLabel?.text == name {
                    button.isEnabled = true
                }
            } else {
                button.isEnabled = true
            }
        }
    }
    
    func disableButtons(name: String = "") {
        for case let button as UIButton in self.view.subviews {
            if name != "" {
                if button.titleLabel?.text == name {
                    button.isEnabled = false
                }
            } else {
                button.isEnabled = false
            }
        }
    }
    
    @IBAction func interiorButton(_ sender: Any) {
        if garage.selectionTracker.isEmpty == false {
            let id = garage.selectionTracker.last!
            if id < 0 {
                self.carName = (garage.carWithID(cellID: id) as! (String, String, Int)).1
            }
            else { // 0+ is for CUSTOMIZED cars
                self.carName = (garage.carWithID(cellID: id) as! (String, String, String, [String], Int)).1
            }
            carEntity = carModels[self.carName!]!.0
        } else{
            let alertController = UIAlertController(title: "No Car Selected", message: "Please select a car to view its interior.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }
        
    }
    @IBAction func customizeButton(_ sender: Any) {
        if garage.selectionTracker.isEmpty == false {
            let cellID = garage.selectionTracker[0]
            if cellID < 0 {
                self.carName = (garage.carWithID(cellID: cellID) as! (String, String, Int)).1
            }
            else { // section 1 is for CUSTOMIZED cars
                self.carName = (garage.carWithID(cellID: cellID) as! (String, String, String, [String], Int)).1
            }
        }
        else{
            let alertController = UIAlertController(title: "No Car Selected", message: "Please select a car to customize it.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }
        
    }
    @IBAction func continueButton(_ sender: Any) {
        if garage.selectionTracker.isEmpty == false {
            sceneKitObjects = [(SCNNode,ARAnchor)]()
            for i in 0..<garage.selectionTracker.count
            {
                let cellID = garage.selectionTracker[i]
                if cellID < 0 {
                    let name = (garage.carWithID(cellID: cellID) as! (String, String, Int)).1
                    let anchor = ARAnchor(transform: simd_float4x4())
                    let newCar = carScenes[name]!.rootNode.childNode(withName: name, recursively: true)!.copy() as!
                                  SCNNode
                    sceneKitObjects.append((newCar,anchor))
                }
                else {
                    let car = garage.carWithID(cellID: cellID) as! (String, String, String, [String], Int)
                    
                    let premadeCarNode = carScenes[car.1]?.rootNode.childNode(withName: car.1, recursively: true)!.copy() as? SCNNode
                    let maxY = premadeCarNode!.boundingBox.max.y
                    
                    if let index = premadeCarNode!.geometry!.materials.firstIndex(where: {$0.name == "body"}) {
                        let materialCopy = premadeCarNode!.geometry!.materials[index].copy() as! SCNMaterial
                        
                        let converter = ColorSet()
                        materialCopy.diffuse.contents = converter.hexToUI(hex: car.2)
                        premadeCarNode!.geometry!.replaceMaterial(at: index, with: materialCopy)
                    }
                                        
                    for acc in car.3 {
                        
//                        let accUrl = Bundle.main.url(forResource: acc, withExtension: ".usdz")!
                        let accNode = accessories[acc]!.0
                        
                        accNode.name = acc
                        accNode.position.y = maxY
                        accNode.isHidden = false
                        
                        premadeCarNode!.addChildNode(accNode)
                    }
                    
                    let anchor = ARAnchor(transform: simd_float4x4())
                    sceneKitObjects.append((premadeCarNode!,anchor))
                    print(premadeCarNode!.geometry!.material(named: "body")!.diffuse)

                    //premadeCarNode = model?.flattenedClone()
                }
            }
        }
    }
    @IBAction func infoButton(_ sender: Any) {
        if garage.selectionTracker.isEmpty == false {
            if garage.selectionTracker[0] < 0 {
                self.carName = (garage.carWithID(cellID: garage.selectionTracker[0]) as! (String, String, Int)).1
            }
            else {
                print("no info")
            }
        }
        else{
            let alertController = UIAlertController(title: "No Car Selected", message: "Please select a car to view its information.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func deleteButton(_ sender: Any){
        if garage.selectionTracker.isEmpty == false {
            let cellID = garage.selectionTracker.last! // Only one selection can exist
            //print(garage.selectionTracker.first?.last)
            let realListIndex = garage.IDtoIndex(cellID: cellID)
            var pseudoIndexRow = -1
            for i in 0..<garage.getCustom().count {
                if garage.selectionTracker.last! == garage.getCustom()[i].4 {
                    pseudoIndexRow = i
                }
            }
            let name = (garage.carWithID(cellID: cellID) as! (String, String, String, [String], Int)).0
            if pseudoIndexRow != -1 { // Cell is visible
                tableView(selectionTable, didSelectRowAt: IndexPath(row: pseudoIndexRow, section: 1))
                garage.customModels.remove(at: realListIndex.row) // Remove car object AFTER deselecting the cell
                selectionTable.deleteRows(at: [IndexPath(row: pseudoIndexRow, section: 1)] as! [IndexPath], with: .fade)
            } else {
                garage.toggleOff(cellID: cellID)
                disableButtons()
                garage.customModels.remove(at: realListIndex.row)
            }
            
            print("Custom car deleted. There are", garage.getCustom().count, "remaining.")
            
            let completedURL = beforeURL + self.userCredentials.0 + "&Password=" + self.userCredentials.1 + "&customName=" + name
            print(completedURL)
            let apiUrl = URL(string: completedURL)!

            let session = URLSession.shared

            let task = session.dataTask(with: apiUrl) { (_, _, _) in
            }
            task.resume()

        }
        
    }
    // END OF BUTTONS
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "interiorSegue" {
            if let carName = carName {
                let vc = segue.destination as! InteriorViewController
                vc.setCar(String: carName, ModelEntity: carEntity, String: interiorPositions[carName] ?? "")

            }
            
        }
        if segue.identifier == "customizationSegue" {
            if let carName = carName {
                let vc = segue.destination as! CustomizationViewController
                
                print(carName, "has children", carScenes[carName]?.rootNode.childNode(withName: carName, recursively: true)!.childNodes)
                vc.setCar(String: carName, SCNScene: carScenes[carName]!)
                vc.userCredentials = userCredentials
                
//                var accAtPos = [String: String]()
//                for (accName, tup) in self.accessories {
//                    accAtPos[accName] = (tup.1 as! String)
//                }
                
                vc.accAtPos = self.accessories
                vc.loadColors(hexListStr: colorsForVehicle[carName]!)
                
                if garage.selectionTracker[0] >= 0 {
                    let car = garage.carWithID(cellID: garage.selectionTracker[0]) as! (String, String, String, [String], Int)
                    vc.thingsToSelect = (car.2, car.3)
                }
            }
            
        }
        if segue.identifier == "continueSegue" {
            let vc = segue.destination as! CarDisplayViewController
            
            vc.cars = sceneKitObjects
        }
        if segue.identifier == "infoSegue" {
            if let carName = carName {
                let vc = segue.destination as! InfoViewController
                vc.setCar(String: carName)
                vc.websites = self.websites
            }
            
        }
    }
  //name the segue that goes from view 1 to view 2 ex demo to interior name segue interior segue
  //override prepare function and access the view 2 controller and set the variable
  //be careful if you have multiple segues out, if you do make sure you check for which is which otherwise itll crash
}

// Extension

extension SelectionViewController: UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    /// Table View stubs
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Base car models and customized models
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return garage.getBase().count
        } else {
            return garage.getCustom().count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 90.0
        }
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let name = garage.getBase()[indexPath.row].0
            let carID = garage.getBase()[indexPath.row].1
            let cellID = garage.getBase()[indexPath.row].2
            
            let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: name)
            cell.textLabel?.text = name
            
            // https://stackoverflow.com/a/33675160 for filling with color
            
            UIGraphicsBeginImageContextWithOptions(CGRect(origin: .zero, size: CGSize(width: 90, height: 90)).size, false, 0.0)
            
            UIRectFill(CGRect(origin: .zero, size: CGSize(width: 90, height: 90)))
            var image = self.imageDict[carID]
            if image == nil{
                image = UIGraphicsGetImageFromCurrentImageContext()
            }
            UIGraphicsEndImageContext()
            let cgImage = (image?.cgImage)
            cell.imageView?.image = UIImage.init(cgImage: cgImage!)
            // -------------------------------------------------------------------
            
            if garage.checkSelected(cellID: cellID) {
                cell.selectionStyle = .default
                cell.accessoryType = .checkmark
            } else {
                cell.selectionStyle = .none
                cell.accessoryType = .none
            }
            
            return cell
        } else {
//            name = garage.customModels[indexPath.row].0 + " in " + garage.customModels[indexPath.row].1
//            name += " with " + String(garage.customModels[indexPath.row].2.count) + " accessories"
            let name = garage.getCustom()[indexPath.row].0
            let cellID = garage.getCustom()[indexPath.row].4
            
            let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: name)
            cell.textLabel?.text = name
            
            if garage.checkSelected(cellID: cellID) {
                cell.selectionStyle = .default
                cell.accessoryType = .checkmark
            } else {
                cell.selectionStyle = .none
                cell.accessoryType = .none
            }
            
            return cell
        }
    }
    
    /// This function also controls enabled buttons
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var cellID = 0
        if indexPath.section == 0 {
            cellID = garage.getBase()[indexPath.row].2
        } else {
            cellID = garage.getCustom()[indexPath.row].4
        }
        if garage.selectionTracker.isEmpty {
            // None currently selected
            // This should mean 1 cell is now selected
            
            garage.toggleOn(cellID: cellID)
            
            tableView.cellForRow(at: indexPath)?.selectionStyle = .default
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark

            enableButtons()
        } else {
            if garage.checkSelected(cellID: cellID) {
                print("This cell is selected. Removing.")
                // Selected a highlighted cell
                // This should mean this cell is being deselected
                
                garage.toggleOff(cellID: cellID)
                
                if garage.selectionTracker.count == 1 {
                    enableButtons()
                }
                
                tableView.cellForRow(at: indexPath)?.selectionStyle = .none
                tableView.cellForRow(at: indexPath)?.accessoryType = .none
            } else {
                // Selected different cell
                // This should mean multiple cells are being/still selected
                
                if garage.selectionTracker.count >= 2 {
                    let oldestCell = garage.selectionTracker.first
                    var indexOldest = garage.IDtoIndex(cellID: oldestCell!)
                    tableView.cellForRow(at: indexOldest)?.selectionStyle = .none
                    tableView.cellForRow(at: indexOldest)?.accessoryType = .none
                    print("Toggling off", oldestCell)
                    garage.toggleOff(cellID: oldestCell!)
                } else {
                    disableButtons()
                    enableButtons(name: "Display")
                }
                
                //garage.selectionTracker.append(indexPath)
                garage.toggleOn(cellID: cellID)

                tableView.cellForRow(at: indexPath)?.selectionStyle = .default
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            }
        }
        
        if garage.selectionTracker.isEmpty {
            disableButtons()
        } else {
            if garage.selectionTracker.count == 1 {
                if garage.selectionTracker.last! >= 0 {
                    deleteButt.isEnabled = true
                    disableButtons(name: "Car")
                } else {
                    deleteButt.isEnabled = false
                }
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Vehicles"
        } else {
            return "My Saved Configurations"
        }
    }
    
    /// Search bar stubs
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let t = searchText.lowercased()
        
        garage.filterText = searchText
        
        selectionTable.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.searchTextField.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        garage.filterText = ""
        searchBar.text = ""
        searchBar.searchTextField.endEditing(true)
        
        selectionTable.reloadData()
    }
}
