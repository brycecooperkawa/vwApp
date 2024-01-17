//
//  CustomizationViewController.swift
//  arVW
//
//  Created by Richard Zhou on 2023-09-28.
//

import UIKit
import SceneKit

/// Modified table cell class, which is used in this context
/// for the cells used for color customization.
class CustomCell: UITableViewCell {
    
    func setContent() {
        self.contentView.layer.borderWidth = 6
        self.contentView.layer.cornerRadius = 10
        self.contentView.layer.borderColor = UIColor(red: 0.0, green: 0.122, blue: 0.325, alpha: 1.0).cgColor
        //self.autoresizesSubviews = false
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        if (selected) {
            self.contentView.layer.borderWidth = 6
        } else {
            self.contentView.layer.borderWidth = 0
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
}

class CustomizationViewController: UIViewController {
    
    var userCredentials = ("u", "u")
    var databaseAPIURL = "https://hjwtamibcy4jtpa5u6uzdbg4za0jwvwf.lambda-url.us-east-2.on.aws/?"
    
    // View Outlets
    @IBOutlet var sceneView: SCNView!
    @IBOutlet var colorView: UITableView!
    @IBOutlet var accView: UITableView!
    @IBOutlet var accSearch: UISearchBar!
    
    var keepAccessories = false // Required to either preserve or discard accessory visibility
    
    var thingsToSelect = ("", [""])
    
    // AR Car Object components
    private var carNode: SCNNode!
    private var carBoxMax: SCNVector3!
    var carScene = SCNScene()
    var accAtPos: [String: (SCNNode, Any)] = [:] // Name, (node, position)
    //private var carScalar = Float(1) // modifier sets scale for AR Scene
    
    // String representation of the car
    private var car = CustomCar()
    
    func setCar(String modelName: String, SCNScene scene: SCNScene)
    {
        car.name = modelName
        carScene = scene
    }
    
    /// Load all colors in dictionary
    func loadColors(hexListStr: String) {
        var converted = [String: UIColor]()
        
        let hexList = (hexListStr).components(separatedBy: ",")
        
        for hex in hexList {
            converted[hex] = car.colors.hexToUI(hex: hex)
        }
        car.colors.loadColors(c: converted)
        car.colors.setNames(u: hexList)
    }
    
    /// Load all accessories in list
    func loadAccessories() {
        var topLeft = [String]()
        var topMiddle = [String]()
        var topRight = [String]()
        
//        var existingNodes = carScene.rootNode.childNode(withName: car.name, recursively: true)!.childNodes
//        print(existingNodes)
        
        for (accName, nodePos) in accAtPos {
            if nodePos.1 as! String == "1" {
                topLeft.append(accName)
            } else if nodePos.1 as! String == "2" {
                topMiddle.append(accName)
            } else if nodePos.1 as! String == "3" {
                topRight.append(accName)
            }
            
            nodePos.0.name = accName
            nodePos.0.position.y = carBoxMax.y
            nodePos.0.isHidden = true
            
            carScene.rootNode.childNode(withName: car.name, recursively: true)!.addChildNode(nodePos.0)
        }

        let accsAtPositions = ["Top Left": topLeft, "Top Middle": topMiddle, "Top Right": topRight]
        
        car.accessories.loadAccessories(accListAtPos: accsAtPositions)
        
        car.accessories.posInteractions["Top Left"]!.append("Top Middle")
        car.accessories.posInteractions["Top Right"]!.append("Top Middle")
        car.accessories.posInteractions["Top Middle"]!.append(contentsOf: ["Top Left", "Top Right"])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("customize vc accessories: ", accAtPos)
        
//        sceneView.layer.borderWidth = 6
//        sceneView.layer.borderColor = super.view.layer.backgroundColor
//        sceneView.layer.cornerRadius = 20

        //sceneView.allowsCameraControl = true
        //sceneView.cameraControlConfiguration.allowsTranslation = false
        
        sceneView.scene = carScene
        carNode = carScene.rootNode.childNode(withName: car.name, recursively: true)
        
        // Get bounding box of car and set scale
        carBoxMax = carNode.boundingBox.max
        
        // Create camera and point of view
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = carNode.position
        cameraNode.position.z = (carBoxMax.z * 2.1)
        cameraNode.position.y = (carBoxMax.y * 0.5)
        carScene.rootNode.addChildNode(cameraNode)
        sceneView.pointOfView = cameraNode
        sceneView.pointOfView?.camera?.zFar = Double(carBoxMax.z * 2.8)
        sceneView.allowsCameraControl = true
        
        loadAccessories()
        
        sceneView.autoenablesDefaultLighting = true
//        sceneView.backgroundColor = UIColor(red: 0.0, green: 0.122, blue: 0.325, alpha: 1.0)
        sceneView.backgroundColor = UIColor.clear
        
        view.addSubview(sceneView)
        
        colorView.delegate = self
        colorView.dataSource = self
        
        accView.delegate = self
        accView.dataSource = self
        
        accSearch.delegate = self

        if thingsToSelect == ("", [""]) {
            self.colorView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
            tableView(colorView, didSelectRowAt: IndexPath(row: 0, section: 0))
        } else {
            selectCells(colorName: thingsToSelect.0, accList: thingsToSelect.1)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        keepAccessories = false // Assume we will return to Selection by default
        
        // Select top (default) color and assure it matches displayed color
//        self.colorView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
//        tableView(colorView, didSelectRowAt: IndexPath(row: 0, section: 0))
        
        self.colorView.sectionHeaderHeight = 0
        
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).clearButtonMode = .never
        
// Way to hide static headers when scrolling down (also hides search bar)
//        accView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: accView.frame.size.width , height: 30))
//        accView.contentInset = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)
//
        if #available(iOS 15.0, *) {
            self.accView.sectionHeaderTopPadding = 0
        } else {
            // Padding did not exist prior to iOS 15
        }
        
        sceneView.play(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if keepAccessories == false {
            loadAccessories()
        }
        
        // Pause the view's session
        sceneView.pause(self)
    }
    
    func toggleAccessory(name: String) -> Bool{
        let root = sceneView.scene!.rootNode
        let acc = root.childNode(withName: name, recursively: true)!
        
        var clash = true
        
        // Accessories can always be toggled off (AS OF NOW)*******
        if acc.isHidden == false {
            acc.isHidden = true
            car.accessories.toggleOff(acc: name)
            return true // (****** CURRENTLY ******* never results in a clash)
        }
        
        clash = car.accessories.checkClash(acc: name)

        if !clash {
            acc.isHidden = false
            car.accessories.toggleOn(acc: name)
        }
        
        return !clash // false if clash, true if there was no clash. Used for cell highlights
    }
    
    @IBAction func saveConfig(_ sender: Any) {
        let alert = UIAlertController(title: "Save customization?", message: "Enter a name:", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = ""
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [alert] (_) in
            let textField = alert.textFields![0]
            let formattedName = (textField.text?.replacingOccurrences(of: " ", with: ""))!
            
//            self.customizations.append(customizationName)
            if formattedName != "" {
                var output = self.databaseAPIURL + "UserID=" + self.userCredentials.0 + "&Password=" + self.userCredentials.1 + "&Login=False"
                output += self.car.makeDBString() + "&Custom=" + formattedName
                
                let url = NSURL(string: output)
                let task = URLSession.shared.dataTask(with: url! as URL)
                task.resume()
                
                print(output)
            } else {
                print("User attempted to save using invalid name")
            }
        }))
        
        self.present(alert, animated: true, completion: nil)

    }
    
    func selectCells(colorName: String, accList: [String]) {
        // Get the color row to select
        for i in 0...self.colorView.numberOfRows(inSection: 0)-1 {
            if self.colorView.cellForRow(at: IndexPath(row: i, section: 0))?.reuseIdentifier == colorName {
                self.colorView.selectRow(at: IndexPath(row: i, section: 0), animated: true, scrollPosition: .none)
                tableView(colorView, didSelectRowAt: IndexPath(row: i, section: 0))
                break
            }
        }
        // Get the accessory rows to select
        for i in 0...self.accView.numberOfSections-1 {
            for j in 0...self.accView.numberOfRows(inSection: i)-1 {
                if accList.contains((self.accView.cellForRow(at: IndexPath(row: j, section: i))?.reuseIdentifier)!) {
                    self.accView.selectRow(at: IndexPath(row: j, section: i), animated: true, scrollPosition: .none)
                    tableView(accView, didSelectRowAt: IndexPath(row: j, section: i))
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "displaySegue"{
            let vc = segue.destination as! CarDisplayViewController
            
            keepAccessories = true // We want to return to visible accessories
            
            // Create copy of car and remove hidden accessories
            let newCarNode = carScene.rootNode.childNode(withName: car.name, recursively: true)!.clone()
            for acc in newCarNode.childNodes {
                if acc.isHidden {
                    acc.removeFromParentNode()
                }
            }
            
            vc.carNode = newCarNode//.flattenedClone()
            vc.carName = car.name
            
        }
    }
    
}

// Extension

extension CustomizationViewController: UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    /// Table View stubs
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView === self.accView {
            return car.accessories.getPositions().count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === self.colorView {
            return car.colors.getNames().count
        } else if tableView === self.accView {
            return car.accessories.getAccessoriesAtPos(pos: car.accessories.getPositions()[section]).count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView === accView {
            let frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 30)
            let view = UITableViewHeaderFooterView(frame: frame)
            
            let label = UILabel(frame: frame)
            label.text = car.accessories.getPositions()[section]
            label.textAlignment = NSTextAlignment.center
            label.textColor = UIColor.systemGray
            label.font = label.font.withSize(13)
            //label.font = UIFont(name: "VW Head Bold", size: 10)
            
            //view.clipsToBounds = true
            view.addSubview(label)
            
            return view
        }
        return tableView.tableHeaderView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.colorView {
            let i = indexPath.row
            let cell = CustomCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: car.colors.getNames()[i])
            cell.setContent()
            cell.selectionStyle = .none
            cell.contentView.layer.backgroundColor = car.colors.getUsableColorAt(i: i).cgColor
            
            return cell
        }
        else if tableView == self.accView {
            let pos = car.accessories.getPositions()[indexPath.section]
            if indexPath.row < car.accessories.getAccessoriesAtPos(pos: pos).count {
                let name = car.accessories.getAccessoriesAtPos(pos: pos)[indexPath.row]
                
                let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: name)
                cell.textLabel?.text = name
                cell.textLabel?.textAlignment = NSTextAlignment.center
                
                // Unhighlight the cell. Only clashed cells get highlighted, so they will
                // unhighlight when the user scrolls far enough. This is intended behavior.
                cell.selectionStyle = .none
                
                if car.accessories.getVisibilityOf(acc: name) == true {
                    // If accessory is visible, apply checkmark
                    cell.accessoryType = .checkmark
                }
                else {
                    // Clear the cell's checkmark if it's not visible
                    cell.accessoryType = .none
                }
                
                return cell
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView === self.colorView {
            carNode.geometry?.material(named: "body")?.diffuse.contents = car.colors.getUsableColorAt(i: indexPath.row)
        } else if tableView === self.accView {
            let cell = tableView.cellForRow(at: indexPath)
            cell!.selectionStyle = .none // Manually unhighlight the cell for custom interactions
            
            let name = (cell?.reuseIdentifier)!

            if toggleAccessory(name: name) == false {
                // Highlight the cell only if the accessory couldn't be placed due to a clash
                cell?.selectionStyle = .blue
            }
            
            // Same block of code as in (just as a manual trigger)
            if car.accessories.getVisibilityOf(acc: name) == true {
                cell?.accessoryType = .checkmark
            }
            else {
                cell?.accessoryType = .none
            }
        }
    }
    
    /// Search bar stubs
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        accView.beginUpdates()
        accView.sectionHeaderHeight = 0
        accView.endUpdates()
        
        searchBar.text = ""
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        car.accessories.filterText = searchText
        accView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.searchTextField.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        car.accessories.filterText = ""
        searchBar.text = ""
        searchBar.showsCancelButton = false
        searchBar.searchTextField.endEditing(true)
        
        accView.reloadData()
        
        accView.beginUpdates()
        accView.sectionHeaderHeight = 30
        accView.endUpdates()
    }
}
