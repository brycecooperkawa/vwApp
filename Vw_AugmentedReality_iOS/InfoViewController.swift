//
//  InfoViewController.swift
//  arVW
//
//  Created by Swathi Thippireddy on 11/4/23.
//

import SwiftUI
import UIKit
import WebKit

class InfoViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet weak var webView: WKWebView!
    var carName: String?
    var websites: [String: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.navigationDelegate = self

        if let carName = carName{
            if carName == "not selected" {
                let alertController = UIAlertController(title: "No Car Selected", message: "Please select a car to view its information.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
            }
            if carName == "ID Buzz 2023"{
                let url = URL(string: websites["Volkswagen_ID_Buzz_2023"]!)
                let request = URLRequest(url: url!)
                webView.load(request)
            }
            else if  carName == "Atlas 2024"{
                let url = URL(string: websites["Volkswagen_Atlas_2024"]!)!
                let request = URLRequest(url: url)
                webView.load(request)
            }
            else if let url = URL(string: websites[carName] ?? "https://www.example.com") {
                let request = URLRequest(url: url)
                webView.load(request)
            }
        }
    }

    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    func setCar(String modelName:String)
    {
        carName = modelName
    }
}
