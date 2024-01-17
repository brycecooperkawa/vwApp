//
//  LoginViewController.swift
//  arVW
//
//  Created by cse498 on 10/9/23.
//

import UIKit
import Foundation
import RealityKit
import SceneKit

class LoginViewController: UIViewController, UITextFieldDelegate {
        
    @IBOutlet weak var userText: UITextField!
    @IBOutlet weak var passText: UITextField!
    
    @IBOutlet weak var createACC: UIButton!
    
    @IBOutlet weak var confirmButton: UIButton!
    
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    @IBOutlet weak var downloadLabel: UILabel!
    
    @IBOutlet weak var percentLabel: UILabel!
    
    @IBOutlet weak var userLabel: UILabel!
    
    @IBOutlet weak var passLabel: UILabel!
    
    @IBOutlet weak var logoImage: UIImageView!
    
    @IBOutlet weak var rememberMeButton: UIButton!
    
    
    var jsonStringData: String?
    
    var loginPushed: Bool = false
    
    var userID: String = ""
    var passID: String = ""
    
    var sign: Bool = false
    var modelLoaded: Bool = false
    var imageLoaded: Bool = false
    var beforeURL: String = "https://qtmhmnv5o7skutihfpqeewbknu0hbsoo.lambda-url.us-east-2.on.aws/?UserID="
    var finalURL: String = ""
    
    var databaseAPIURL: String = "https://5nzaz3yjyqxt4pvbkrwblpe4q40mrosg.lambda-url.us-east-2.on.aws/"
    var databaseModels: Set<String> = []
    
    var deleteWhenModelURL: String = "https://4kxu3thlm4jxra3i6kwqpzwch40xyyiv.lambda-url.us-east-2.on.aws/?User="
    var gettingDeleted: Bool = false
    var deletingModel: String = ""
    
    var databaseImages: Set<String> = []
    
    private let dispatchGroup = DispatchGroup()
    var contents = [[String]]()
    
    var realityKitObjects: [Entity] = []
    var sceneKitObjects: [SCNNode] = []
//    var s3ModelUrls = [String: String]
    var interiorPositions: [String: String] = [:]
    var colorsForVehicle: [String: String] = [:]
    var websites: [String: String] = [:]
    var checkAccessory: [String: (Bool, Any)] = [:]
    //var accessories: [String: (SCNNode, Any)] = [:]
    
    var imageObjects: [String: UIImage] = [:]
    
    var modelNum: Int = 0
    var totalModel: Int = 0
    
    var imageNum: Int = 0
    var totalImage: Int = 0
    
    var rememberMeBool : Bool = false
    
    @IBOutlet weak var rememberMeLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()


        rememberMeButton.imageView?.contentMode = .scaleAspectFit
        rememberMeButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        rememberMeButton.setTitle("", for: .normal)
        rememberMeButton.setBackgroundImage(nil, for: .normal)
        rememberMeLabel.text = "Remember Me"
        rememberMeLabel.textColor = UIColor.white
        rememberMeLabel.font = UIFont.systemFont(ofSize: 12.0)
        

        // Adjust the image size
        let imageSize = CGSize(width: 25, height: 25) // Adjust the size as needed


        if let savedUsername = UserDefaults.standard.string(forKey: "savedUsername"),
           let savedPassword = UserDefaults.standard.string(forKey: "savedPassword"),
           UserDefaults.standard.bool(forKey: "isRememberMe") {
           // Auto-fill the username and password fields
           userText.text = savedUsername
           passText.text = savedPassword
            if let originalImage = UIImage(named: "check") {
                let resizedImage = resizeImage(originalImage, targetSize: imageSize)
                rememberMeButton.setImage(resizedImage, for: .normal)
                rememberMeBool = true
            }
           
        }else{
            if let originalImage = UIImage(named: "uncheck") {
                let resizedImage = resizeImage(originalImage, targetSize: imageSize)
                rememberMeButton.setImage(resizedImage, for: .normal)
                rememberMeBool = false
            }
            
        }


        
        
        
        view.backgroundColor = UIColor(hex: "#00008B")
        
        userLabel.textColor = UIColor.white
        passLabel.textColor = UIColor.white
        percentLabel.textColor = UIColor.white
        downloadLabel.textColor = UIColor.white
        
        logoImage.image = UIImage(named:"loginImage")
        
        if let customFont = UIFont(name: "VWHead-BoldItalic", size: 25.0) {
            userLabel.font = customFont
        }else {
            print("Error loading custom font.")
        }
        loading.isHidden = true
        loading.style = .large
        
        confirmButton.setTitle("Login", for: .normal)
        createACC.setTitle("Create Account", for: .normal)
        
//        userText.keyboardType = UIKeyboardType.
        userText.keyboardType = UIKeyboardType.asciiCapable
        userText.autocorrectionType = UITextAutocorrectionType.no
        passText.isSecureTextEntry = true
        jsonStringData = ""
        
        progressBar.progress = 0.0
        progressBar.isHidden = true
        downloadLabel.text = "Downloading Vehicles"
        downloadLabel.isHidden = true
        
        percentLabel.isHidden = true
        percentLabel.text = "0%"
        
        userText.delegate = self
        passText.delegate = self
        
        


        let (localModels, localImages) = contentsFromDocumentsFolder()
        contentsFromDatabase{(databaseModels, databaseImages) in
            if let databaseModels = databaseModels{
                print("Database Models: \(databaseModels)")
                
                let missingModels = databaseModels.subtracting(localModels)
                self.modelNum = missingModels.count
                self.totalModel = missingModels.count
                
                //Delete models in documents directory that are not in database
                for model in localModels {
                    if !databaseModels.contains(model) {
                        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let fileURL = documentsURL.appendingPathComponent(model)

                            do {
                                try FileManager.default.removeItem(at: fileURL)
                                print("Deleted model: \(model)")
                                var newString = String(model.dropLast(5))
                                self.deletingModel = newString
                                self.gettingDeleted = true
                                
                            } catch {
                                print("Error deleting model: \(model), \(error)")
                            }
                        }
                    }
                }
                
                let dispatchGroup = DispatchGroup()
                print("missing models", missingModels)
                self.downloadMissingModels(missingModels)
                {
                    //Update UI?

                }
            } else{
                print("Failed to retrieve database models")
            }
        }
        
        contentsFromDatabase{(databaseModels, databaseImages) in
            if let databaseImages = databaseImages{
                print("Database Images: \(databaseImages)")
                
                let missingImages = databaseImages.subtracting(localImages)
                self.imageNum = missingImages.count
                self.totalImage = missingImages.count
                //Delete models in documents directory that are not in database
                for image in localImages {
                    if !databaseImages.contains(image) {
                        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let fileURL = documentsURL.appendingPathComponent(image)

                            do {
                                try FileManager.default.removeItem(at: fileURL)
                                print("Deleted image: \(image)")
                            } catch {
                                print("Error deleting image: \(image), \(error)")
                            }
                        }
                    }
                }
                
                let dispatchGroup = DispatchGroup()
                self.downloadImages(missingImages){
                    //Update UI?

                }
            } else{
                print("Failed to retrieve database images")
            }
        }
        


        
        
        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }), let navigationController = keyWindow.rootViewController as? UINavigationController {
            navigationController.setNavigationBarHidden(false, animated: false)
        }
    }
    
    
    struct MyData: Codable {
        let data: [[String]]
    }
    @objc func buttonTapped() {
        let imageSize = CGSize(width: 25, height: 25) // Adjust the size as needed
        if rememberMeBool{
            if let originalImage = UIImage(named: "uncheck") {
                let resizedImage = resizeImage(originalImage, targetSize: imageSize)
                rememberMeButton.setImage(resizedImage, for: .normal)
                self.rememberMeBool = false
            }
            
        }else{
            if let originalImage = UIImage(named: "check") {
                let resizedImage = resizeImage(originalImage, targetSize: imageSize)
                rememberMeButton.setImage(resizedImage, for: .normal)
                self.rememberMeBool = true
            }
            
        }


    }
    
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { (context) in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }
    
    

    
    func contentsFromDocumentsFolder() -> (Set<String>, Set<String>){
        var localModels: Set<String> = []
        var localImages: Set<String> = []
        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            do{
                let folderContents = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [])

                for file in folderContents{
                    print("file.lastPathComponent", file.lastPathComponent.suffix(4))
                    if file.lastPathComponent.suffix(4) == "usdz"{
                        localModels.insert(file.lastPathComponent)
                    }else{
                        localImages.insert(file.lastPathComponent)
                    }
                }
            } catch{
                print("Error reading folder contents: \(error)")
            }
        } else{
            print("Folder not found.")
        }

        return (localModels, localImages)
    }
    
    //Find what mdoels are in the MySQL database
    func contentsFromDatabase(completion: @escaping (Set<String>?, Set<String>?) -> Void){
        var databaseModels: Set<String> = []
        var databaseImages: Set<String> = []
        if let url = URL(string:databaseAPIURL){
            let task = URLSession.shared.dataTask(with: url){ (data,response, error) in
                if let error = error{
                    print("Error: \(error)")
                    completion(nil, nil)
                    
                } else if let data = data{
                    
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let dataArray = jsonObject["data"] as? [[Any]]{
//                        print("DataArray: ", dataArray)
                        for item in dataArray{
//                            print("item: ", item)
                            if let modelName = item[0] as? String, let modelWebsite = item[3] as? String{
                                databaseModels.insert(modelName + ".usdz")
                                self.websites[modelName] = modelWebsite
                                //car entity reality and positions to interior
                                self.colorsForVehicle[modelName] = item[6] as? String
                                self.interiorPositions[modelName] = item[7] as? String
                                //car image to selection
                                if item[2] as! String == "0"{
                                    self.checkAccessory[modelName] = (true, item[4])
                                } else{
                                    self.checkAccessory[modelName] = (false, "")
//                                    self.imageObjects[modelName] = item[5] as? String
                                    databaseImages.insert(modelName + ".png")
                                    
                                }
                            }
                        }
                        completion(databaseModels, databaseImages)
                    }else{
                        print("Invalid API response data.")
                        completion(nil, nil)
                    }
                }
            }
            task.resume()
        }else{
            print("invalid API URL")
            completion(nil, nil)
        }
    }

    
    func downloadMissingModels(_ missingModels: Set<String>, completion: @escaping () -> Void){
        for modelName in missingModels{
            print(self.modelNum)
            self.dispatchGroup.enter()
            if let s3BucketURL = URL(string: "https://id-buzz.s3.us-east-2.amazonaws.com/\(modelName)"){
                let destinationDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationURL = destinationDirectory.appendingPathComponent(modelName)
                
                URLSession.shared.downloadTask(with: s3BucketURL){ (tempLocalURL, response, error) in
                    if let error = error {
                        print("Error Downloading \(modelName): \(error)")
                        return
                    }
                    guard let tempLocalURL = tempLocalURL else{
                        return
                    }
                    do {
                        let fileManager = FileManager.default
                        if fileManager.fileExists(atPath: destinationURL.path){
                            try! FileManager.default.removeItem(at: destinationURL)
                            print("File removed")
                        }
                        try fileManager.moveItem(at: tempLocalURL, to: destinationURL)
                        self.modelNum -= 1
                        print(self.modelNum)
                        print(Float(self.totalModel - self.modelNum) / Float(self.totalModel))
                        print("Downloaded and saved \(modelName)")
                        let downloadProgress = Float(self.totalModel - self.modelNum) / Float(self.totalModel)
                        let downloadPercent = Int(downloadProgress * 100)
                        DispatchQueue.main.async {
                            self.progressBar.progress = downloadProgress
                            if downloadPercent >= 80{
                                self.downloadLabel.text = "Loading Entity"
                            }
                            self.percentLabel.text = String(downloadPercent) + "%"
                        }

                    }catch{
                        print("Error saving: \(modelName) to local directory: \(error)")
                    }
                    self.dispatchGroup.leave()
                }.resume()
                
            }
        }
        //Once all the downloaded tasks are complete we can call closure and UI can be updated
        self.dispatchGroup.notify(queue: .main){
            completion()
            self.modelLoaded = true
        }
    }
    
    
    func downloadImages(_ missingImages: Set<String>, completion: @escaping () -> Void){
        for modelImage in missingImages{
            self.dispatchGroup.enter()
            if let s3BucketURL = URL(string: "https://id-buzz.s3.us-east-2.amazonaws.com/\(modelImage)"){
                let destinationDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationURL = destinationDirectory.appendingPathComponent(modelImage)

                URLSession.shared.downloadTask(with: s3BucketURL){ (tempLocalURL, response, error) in
                    if let error = error {
                        print("Error Downloading \(modelImage): \(error)")
                        return
                    }
                    guard let tempLocalURL = tempLocalURL else{
                        return
                    }
                    do {
                        let fileManager = FileManager.default
                        if fileManager.fileExists(atPath: destinationURL.path){
                            try! FileManager.default.removeItem(at: destinationURL)
                            print("File removed")
                        }
                        try fileManager.moveItem(at: tempLocalURL, to: destinationURL)
                        print("Downloaded and saved \(modelImage)")
                    }catch{
                        print("Error saving: \(modelImage) to local directory: \(error)")
                    }
                    self.dispatchGroup.leave()
                }.resume()

            }
        }
        
        //Once all the downloaded tasks are complete we can call closure and UI can be updated
        self.dispatchGroup.notify(queue: .main){
            self.imageLoaded = true
            if self.modelLoaded && self.loginPushed{
                self.performSegue(withIdentifier: "selectionSegue", sender: self)
            }
            completion()
        }
    }
    
    
    
    func makeGETRequest(completion: @escaping (Bool) -> Void){
        if self.deletingModel.isEmpty{
            print("nothing deleted")
        }else{
            self.deleteWhenModelURL += self.userText.text! + "&Password=" + self.passText.text! + "&Model=" + self.deletingModel
            print(self.deleteWhenModelURL)
            let apiUrl = URL(string: self.deleteWhenModelURL)!
            let session = URLSession.shared
            let task = session.dataTask(with: apiUrl) { (_, _, _) in
            }
            task.resume()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.contents = []
            if let url = URL(string:self.finalURL){
                let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                    if error != nil{
                        print("error")
                        completion(false)
                    } else if let data = data {
                        var success = false
                        if var result = String(data: data, encoding: .utf8){
                            let startIndex = result.index(result.startIndex, offsetBy:10)
                            result = String(result[startIndex...])
                            result = String(result.dropLast(3))
                            print("Response data:", result)
                            let listArray = result.components(separatedBy: "],")
                            //
                            //                        print(listArray[0].count, "checking")
                            //                        print(listArray.count, "checking")
                            if listArray[0] != "" {
                                self.sign = true
                                success = true
                                
                                // Add usable rows to configurations list
                                for row in listArray {
                                    var tmp = row.replacingOccurrences(of: "\"", with: "")
                                    tmp = tmp.replacingOccurrences(of: "[", with: "")
                                    var comp = tmp.components(separatedBy: ",")
                                    if comp[3] == "False" {
                                        self.contents.append(comp)
                                    }
                                }
                                
                            }else{
                                self.sign = false
                                success = false
                            }
                        }
                        if success {
                            completion(true)
                        } else {
                            completion(false)
                        }
                    }
                }
                task.resume()
                
            }
        }

    }
    
    
    
    
    
    
    
    func userFieldReturn(_ textField:UITextField) -> Bool {
        return userText.resignFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    

    
    
    @IBAction func confimTapped(_ sender: Any) {
        print("called")
        if self.modelNum != 0{
            progressBar.isHidden = false
            downloadLabel.isHidden = false
            percentLabel.isHidden = false
        }
        loading.isHidden = false
        loading.startAnimating()
        
        self.finalURL = beforeURL + self.userText.text! + "&Password=" + self.passText.text!
        makeGETRequest { [weak self] success in
            if success { // username and password are correct
                DispatchQueue.main.async {
                    self?.loginPushed = true
                    if self?.modelLoaded == true && self?.imageLoaded == true{
                        self?.performSegue(withIdentifier: "selectionSegue", sender: self)
                      }
                }
            } else { // username and password are incorrect
                DispatchQueue.main.async {
                    self?.displayErrorMessage()
                }
            }
            
        }
        

        if rememberMeBool {
            // Save credentials if "Remember Me" is enabled
            UserDefaults.standard.set(userText.text!, forKey: "savedUsername")
            UserDefaults.standard.set(passText.text!, forKey: "savedPassword")
            UserDefaults.standard.set(true, forKey: "isRememberMe")
        } else {
            // Clear saved credentials if "Remember Me" is not enabled
            UserDefaults.standard.removeObject(forKey: "savedUsername")
            UserDefaults.standard.removeObject(forKey: "savedPassword")
            UserDefaults.standard.removeObject(forKey: "isRememberMe")
        }
    }
    
    @IBAction func togglePasscode(_ sender: Any) {
        passText.isSecureTextEntry.toggle()
    }
    
    func displayErrorMessage() {
        let alertController = UIAlertController(title: "Error", message: "Incorrect username or password. Please try again.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
        
        loading.isHidden = true
        loading.stopAnimating()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.loading.stopAnimating()
        self.loading.isHidden = true
        if segue.identifier == "selectionSegue" {
            if let destinationVC = segue.destination as? SelectionViewController {
                destinationVC.realityKitObjects = self.realityKitObjects
                //destinationVC.sceneKitObjects = self.sceneKitObjects
                
                print(self.checkAccessory)
//                destinationVC.accessories = self.accessories
                
                destinationVC.userCredentials = (userText.text!, passText.text!)
                
                destinationVC.configList = self.contents
                destinationVC.websites = self.websites
                destinationVC.checkAccessory = self.checkAccessory
                destinationVC.interiorPositions = self.interiorPositions
                destinationVC.colorsForVehicle = self.colorsForVehicle
                
                destinationVC.imageObjects = self.imageObjects

            }
        }
    }
    
    /// UITextField stubs
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == " " {
            return false
        }
        return true
    }
    
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 0.5) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
