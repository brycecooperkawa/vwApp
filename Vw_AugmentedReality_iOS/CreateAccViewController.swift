//
//  CreateAccViewController.swift
//  arVW
//
//  Created by cse498 on 10/12/23.
//

import UIKit

class CreateAccViewController: UIViewController, UITextFieldDelegate {


    
//    @IBOutlet weak var userName: UITextField!
//
//    @IBOutlet weak var passWord: UITextField!
    
    var checkURL: String = "https://tjpivd6qjticywuddwzyzfju3q0dygms.lambda-url.us-east-2.on.aws/?UserID="
    var finalURL: String = ""
    var contents = [[String]]()
    
    
    @IBOutlet weak var userName: UITextField!
    
    @IBOutlet weak var passWord: UITextField!
    @IBOutlet weak var confirmPass: UITextField!
    
//    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var createButton: UIButton!
    
    @IBOutlet weak var userLabel: UILabel!
    
    @IBOutlet weak var passLabel: UILabel!
    
    @IBOutlet weak var confirmLabel: UILabel!
    
    var beforeURL = "https://jwpoyq5nsnvbefkomgqojmoqxu0gxhcr.lambda-url.us-east-2.on.aws/?"
    var color = "Violet"
    var completedURL: String!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userName.keyboardType = UIKeyboardType.asciiCapable
        userName.autocorrectionType = UITextAutocorrectionType.no
        
        passWord.isSecureTextEntry = true
        confirmPass.isSecureTextEntry = true
        
        userName.delegate = self
        passWord.delegate = self
        confirmPass.delegate = self
        
        userLabel.textColor = UIColor.white
        passLabel.textColor = UIColor.white
        confirmLabel.textColor = UIColor.white

        view.backgroundColor = UIColor(hex: "#00008B")
        
    }
    
    /// UITextField stubs
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == " " {
            return false
        }
        return true
    }
    
    func userFieldReturn(_ textField:UITextField) -> Bool {
        return userName.resignFirstResponder()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
//    @IBAction func createTapped(_ sender: Any) {
//        var a = false
//        var b = false
//
//        if passWord.text == confirmPass.text {
//
//            a = true
//
//        } else {
//
//            let alert = UIAlertController(title: "Error", message: "Passwords do not match", preferredStyle: .alert)
//
//            let okay = UIAlertAction(title: "Okay", style: .default){(action) in
//                print(action)
//            }
//            alert.addAction(okay)
//            present(alert, animated: true, completion: nil)
//        }
//
//        if(passWord.text == "" || confirmPass.text == "") {
//            //alert saying there are empty fields
//
//        } else {
//
//            b = true
//        }
//
//        if a == true && b == true {
//            loginButton.isEnabled = true
//        }
//
//
//    }
    
    
    @IBAction func confirmTapped(_ sender: Any) {
        var a = false
        var b = false

        if passWord.text == confirmPass.text {

            a = true

        } else {

            let alert = UIAlertController(title: "Error", message: "Passwords do not match", preferredStyle: .alert)
            
            let okay = UIAlertAction(title: "Okay", style: .default){(action) in
                print(action)
            }
            alert.addAction(okay)
            present(alert, animated: true, completion: nil)
        }

        if(passWord.text == "" || confirmPass.text == "") {
            //alert saying there are empty fields

        } else {

            b = true
        }
        
        
//        print("called")
//        loading.isHidden = false
//        loading.startAnimating()
//


        if a == true && b == true {
//            loginButton.isEnabled = true
            completedURL = beforeURL + "UserID=" + userName.text! + "&Password=" + passWord.text! + "&Color=" + color + "&Login=True&Modelname=null&TopLeft=null&TopMiddle=null&TopRight=null"
            
            
            self.finalURL = checkURL + self.userName.text!
            print(finalURL)
            makeGETRequest { [weak self] success in
                if success { // username and password are correct
                    DispatchQueue.main.async {
                        let url = NSURL(string: self!.completedURL)
                        let task = URLSession.shared.dataTask(with: url! as URL)
                        task.resume()
                        
                        let alert = UIAlertController(title: "Success", message: "You have successfully created an account", preferredStyle: .alert)
                        
                        let okay = UIAlertAction(title: "Okay", style: .default){(action) in
                            print(action)
                            self?.navigationController?.popToRootViewController(animated: true)
                        }
                        alert.addAction(okay)
                        self?.present(alert, animated: true, completion: nil)
                        
                    }
                } else { // username and password are incorrect
                    DispatchQueue.main.async {
                        self?.displayAccountExist()
                    }
                }
                
            }

        }
        
    }
    
    
    func makeGETRequest(completion: @escaping (Bool) -> Void){
        print(finalURL)
        if let url = URL(string:finalURL){
            let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
                if error != nil{
                    print("error")
                    completion(false)
                } else if let data = data {
                    var success = true
                    if var result = String(data: data, encoding: .utf8){
                        let startIndex = result.index(result.startIndex, offsetBy:10)
                        result = String(result[startIndex...])
                        result = String(result.dropLast(3))
                        print("Response data:", result)
                        let listArray = result.components(separatedBy: "],")
                        
                        if listArray[0] != "" {
                            success = false
                            
                        }else{
                            success = true
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
    func displayAccountExist(){
        let alertController = UIAlertController(title: "Error", message: "There is already an account with this User ID", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    
    
//    @IBAction func loginTapped(_ sender: Any) {
//        completedURL = beforeURL + "UserID=" + userName.text! + "&Password=" + passWord.text! + "&Color=" + color + "&Login=True&Modelname=null&TopLeft=null&TopMiddle=null&TopRight=null"
//
//        let url = NSURL(string: completedURL)
//        let task = URLSession.shared.dataTask(with: url! as URL)
//        task.resume()
//
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectionSegue2" {
            if let destinationVC = segue.destination as? SelectionViewController {
//                destinationVC.realityKitObjects = self.realityKitObjects
//                destinationVC.sceneKitObjects = self.sceneKitObjects
//
//                destinationVC.configList = self.contents
//                destinationVC.websites = self.websites
                destinationVC.userCredentials = (userName.text!, passWord.text!)
            }
        }
    }
    
}


