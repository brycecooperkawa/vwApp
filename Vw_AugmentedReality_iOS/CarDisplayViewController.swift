
// CarDisplayViewController.swift
// arVW
//
// Created by Swathi Thippireddy on 10/7/23.
//
import UIKit
import ARKit
import SceneKit
import AVFoundation
import Photos
import SwiftUI
import ReplayKit

class CarDisplayViewController: UIViewController, ARSCNViewDelegate {
    let ACTUALSCALE = 0.0275 as Float
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var addCar: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var fakeButton: UIButton!
    @IBOutlet weak var recapture: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var sizeSelector: UISegmentedControl!
    
    @IBOutlet weak var navigationBack: UINavigationItem!
    var overlayWindow: UIWindow!
    
    @IBOutlet weak var stop: UIButton!
    
    let recorder = RPScreenRecorder.shared()
    
    //record
     var isRecording = false
    var videoWriterInput: AVAssetWriter?
    var videoInputAsset: AVAssetWriterInput?
    var pixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?
    var captureSession: AVCaptureSession!
    var videoDevice: AVCaptureDevice!
    var videoInputCapture: AVCaptureDeviceInput!
    var videoOutput: AVCaptureMovieFileOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var videoOutputURL: URL?
    
    var videoInput: AVCaptureDeviceInput!
    var videoWriter: AVAssetWriter?
    var videoInputWriter: AVAssetWriterInput?
    

    var lastPositions:[SCNVector3] = []
    //record
    
    var finalImage: UIImage?
    
    
    // Interactions
    var carNode: SCNNode!
    
    var cars:[(SCNNode,ARAnchor)] = []
    var currentCarDex = 0
    var carName = ""
    
    var lastCarPlaced = false
    
    var focusSquare = FocusSquare()
    
    let coachingOverlay = ARCoachingOverlayView()
    
    let updateQueue = DispatchQueue(label: "com.example.apple-samplecode.arkitexample.serialSceneKitQueue")
    
    let alignment:ARRaycastQuery.TargetAlignment = .horizontal
    
    var session: ARSession {
             return sceneView.session
         }

    var notAdded = true
    var firstTime = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        
        //videoButton.setTitle("Record", for: .normal)
        //saveButton.setTitle("Save", for: .normal)
        //shareButton.setTitle("Share", for: .normal)
        recapture.setTitle("Retake", for: .normal)
        videoButton.isHidden = true
        saveButton.isHidden = true
        shareButton.isHidden = true
        captureButton.isHidden = true
        recapture.isHidden = true
        sizeSelector.isHidden = true
        
        
        // Set the view’s delegate
        sceneView.delegate = self
        
        // Set up view’s technical parameters
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
//        sceneView.showsStatistics = true
        
        // Set up coaching overlay.
        setupCoachingOverlay()
        
        //var guideCar = carNode.copy() as! SCNNode
        
        if carNode != nil {
            var anchor = ARAnchor(transform: simd_float4x4())
            cars.append((carNode.clone(), anchor))
            carNode = nil
        }
        
        
        
        //cars.append((newCar,anchor))
        
        //carNode.isHidden = true
        //guideCar.isHidden = false
        //guideCar.opacity = 0.5
        //sceneView.scene.rootNode.addChildNode(cars[currentCarDex].0)


//        print("In AR:", carNode.childNodes)
        
        sceneView.scene.rootNode.addChildNode(focusSquare)
        //sceneView.scene.rootNode.addChildNode(cars[currentCarDex].0)

        captureButton.addTarget(self, action: #selector(captureButtonPressed), for: .touchUpInside)
        
        //        videoButton.addTarget(self, action: #selector(recordButtonPressed), for: .touchUpInside)
        
        // Run the view’s session
        sceneView.scene.rootNode.light?.shadowMode = SCNShadowMode.forward
        sceneView.session.run(configuration)
    }
    
    @IBAction func addCarToView() { // THIS FUNCTION ALSO CONTROLS THE "CAPTURE" BUTTON!!!!
        if lastCarPlaced == false {
            sizeSelector.selectedSegmentIndex = 2
            sizeSelector.isHidden = false
        }
        
        let query = getRaycastQuery()
        
        if query != nil {
            //let cast = sceneView.session.raycast(query!).first
            
            placeCar()
            
        } else { print("Cast broke") }
        //    print(car?.worldPosition.x, car?.worldPosition.z)
        //    //print(focusSquare.lastPosition)
        //    print(sceneView.scene.rootNode.childNode(withName: carName, recursively: true)?.worldPosition)
    }
    
    func placeCar()
    {

        if notAdded == false{
            // If car was successfully added to the scene
            sizeSelector.isHidden = true
            
            cars[self.currentCarDex].0.opacity = 1
            
            currentCarDex += 1
        
            notAdded = true
            addCar.setTitle("Next Car", for: .normal)
            if currentCarDex >= cars.count
            {
                lastCarPlaced = true
                addCar.setTitle("Capture", for: .normal)

            }
            return
        }
        
        if currentCarDex >= cars.count{
            lastCarPlaced = true
            
            addCar.isHidden = true
            captureButton.isHidden = false
            videoButton.isHidden = false
        }
        else
        {
            print("Placing a car")
            
            addCar.setTitle("Add", for: .normal)
            cars[self.currentCarDex].0.scale.x = ACTUALSCALE
            cars[self.currentCarDex].0.scale.y = ACTUALSCALE
            cars[self.currentCarDex].0.scale.z = ACTUALSCALE
            cars[self.currentCarDex].0.opacity = 0.7
            cars[self.currentCarDex].0.geometry?.materials[3].lightingModel = .physicallyBased
            cars[self.currentCarDex].0.movabilityHint = SCNMovabilityHint.movable
            cars[self.currentCarDex].0.isHidden = false
            
            sceneView.scene.rootNode.addChildNode(cars[currentCarDex].0)
            notAdded = false
            
        }
        

    }
    
    
//    func setTransform(of virtualObject: VirtualObject, with result: ARRaycastResult) {
//        virtualObject.simdWorldTransform = result.worldTransform
//    }
    
    
    func updateElements(isObjectVisible: Bool) {
        if coachingOverlay.isActive {
            focusSquare.hide()
        }   else {
            focusSquare.unhide()
        }
        
        
        // Perform ray casting only when ARKit tracking is in a good state.
        if let camera = sceneView.session.currentFrame?.camera, case .normal = camera.trackingState,
           let query = getRaycastQuery(),
           let cast = sceneView.session.raycast(query).first {
            updateQueue.async {
                //self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
                //self.focusSquare.state = .detecting(raycastResult: cast, camera: camera)
                self.cars[self.currentCarDex].0.isHidden = false
                self.focusSquare.isHidden = true
                //self.cars[self.currentCarDex].0.simdTransform = cast.worldTransform
                ///replace old anchor with new one
                //self.session.remove(anchor: self.cars[self.currentCarDex].1 )

                let anchor = ARAnchor(transform: cast.worldTransform)
                //self.cars[self.currentCarDex].1 = anchor
                self.session.add(anchor: anchor)
                
                
                self.cars[self.currentCarDex].0.worldPosition =  SCNVector3(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
//                self.cars[self.currentCarDex].0.position =  SCNVector3(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
                
               // self.sceneView.session.setWorldOrigin(relativeTransform: cast.worldTransform)
                DispatchQueue.main.async{
                    self.addCar.isEnabled = true
                }
            }
        }
        else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.focusSquare.isHidden = false
                self.cars[self.currentCarDex].0.isHidden = true
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
                DispatchQueue.main.async{
                    if self.firstTime == false{
                        self.addCar.isEnabled = false
                    }
                }
            }
        }
    }
    
    
    // - Tag: GetRaycastQuery
    func getRaycastQuery(for alignment: ARRaycastQuery.TargetAlignment = .any) -> ARRaycastQuery? {
        let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
        return sceneView.raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: alignment)
    }
    /*
     func createRaycastAndUpdate3DPosition(of virtualObject: VirtualObject, from query: ARRaycastQuery) {
     guard let result = sceneView.session.raycast(query).first else {
     return
     }
     self.setTransform(of: virtualObject, with: result)
     }
     */
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sceneView.play(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view’s session
//        sceneView.session.pause()
        sceneView.pause(self)
    }
    
    @IBAction func sizeChange(_ sender: UISegmentedControl) {
        var scale = Float(ACTUALSCALE)
        if sender.selectedSegmentIndex == 0 {
            scale = 0.001
        } else if sender.selectedSegmentIndex == 1 {
            scale = 0.01
        } else {
            scale = ACTUALSCALE
        }
        
        if self.currentCarDex <= cars.count-1 {
            cars[self.currentCarDex].0.scale = SCNVector3(x: scale, y: scale, z: scale)
        } else { print("Error: There is no car at index", self.currentCarDex) }

    }
    
    @IBAction func captureButtonPressed(_ sender: Any) {
        let snapshot = sceneView.snapshot()
        // Save the screenshot to the Photos library or perform other actions
        
        UIGraphicsBeginImageContext(snapshot.size)
        let imageDate = snapshot.pngData()
        let finalImage = UIImage(data: imageDate!)
        self.finalImage = finalImage
        
        
        let flashNode = SCNNode()
        flashNode.geometry = SCNBox(width: 10, height: 10, length: 0.01, chamferRadius: 0)
        flashNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        flashNode.opacity = 1.0
        
        sceneView.scene.rootNode.addChildNode(flashNode)
        
        //        UIImageWriteToSavedPhotosAlbum(snapshot, nil, nil, nil)
        
        let fadeOutAction = SCNAction.fadeOut(duration: 1.0)
        flashNode.runAction(fadeOutAction) {
            flashNode.removeFromParentNode()
        }
        
        shareButton.isHidden = false
        saveButton.isHidden = false
        recapture.isHidden = false
        
        captureButton.isHidden = true
        
        
        startPulseAnimation()
        self.shareButton.backgroundColor = UIColor.red
        self.saveButton.backgroundColor = UIColor.red
        
    }
    
    
    
    
    
    private func presentShareSheet(){
        guard let image = UIImage(systemName: "bell") else {
            return
        }
        let shareSheetVC = UIActivityViewController(
            activityItems: [
                image,
                "Hello did this send"
            ],
            applicationActivities: nil
        )
        present(shareSheetVC, animated: true)
    }
    
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        
        let textShare = "This is a Volkswagen car in AR"
        let activityViewController = UIActivityViewController(activityItems: [self.finalImage, textShare], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
        
    }
    
    func shareImage(image: UIImage) {
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
    
    
    func startPulseAnimation() {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 0.5
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.1
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        
        shareButton.layer.add(pulseAnimation, forKey: "pulse")
        saveButton.layer.add(pulseAnimation, forKey: "pulse")
    }
    
    
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        
        saveButton.layer.removeAnimation(forKey: "pulse")
        
        if self.finalImage != nil{
            UIImageWriteToSavedPhotosAlbum(self.finalImage!, nil, nil, nil)
            let alertController = UIAlertController(title: "Saved Image", message: "You have successfully saved your image", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            }))
            
            present(alertController, animated: true, completion: nil)
        }else{
            let alertController = UIAlertController(title: "Error", message: "There was no image to save", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            }))
            
            present(alertController, animated: true, completion: nil)
        }
        
    }
    
    
    
    

    
    

    

    
    @IBAction func startRecord(_ sender: Any) {
        
        videoButton.isHidden = true
        saveButton.isHidden = true
        shareButton.isHidden = true
        captureButton.isHidden = true
        recapture.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: true)

        
        
        overlayWindow = UIWindow(frame: UIScreen.main.bounds)
        overlayWindow?.windowLevel = UIWindow.Level.alert
        overlayWindow?.rootViewController = UIViewController()
        overlayWindow?.makeKeyAndVisible()

        // Add a button with the same appearance as the actual button to the overlay
        let fakeButton = UIButton(type: .system)
        fakeButton.frame = videoButton.frame
        

        fakeButton.setTitle("Stop", for: .normal)
        fakeButton.backgroundColor = UIColor.systemBlue
        fakeButton.setTitleColor(UIColor.white, for: .normal)
        fakeButton.layer.cornerRadius = 10
        fakeButton.addTarget(self, action: #selector(fakeButtonTapped), for: .touchUpInside)
        overlayWindow?.rootViewController?.view.addSubview(fakeButton)
        

        
        addCar.isHidden = true
//        stop.isHidden = true


        recorder.startRecording { (error) in
            if let error = error {
                print(error)
            }
        }
        
//        AVCaptureDevice.requestAccess(for: .audio) { granted in
//            if granted {
//                // Start screen recording
//                RPScreenRecorder.shared().startRecording { error in
//                    if let error = error {
//                        print("Error starting recording: \(error.localizedDescription)")
//                    } else {
//                        print("Recording started")
//
//                        // Stop recording after a delay (adjust the delay as needed)
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
//                            self.stopRecording()
//                        }
//                    }
//                }
//            } else {
//                print("Microphone access denied.")
//                // Handle the denial of microphone access
//            }
//        }
        
        
    }
    
    
    func stopRecording(){
        
        RPScreenRecorder.shared().stopRecording { previewViewController, error in
            
            if let error = error {
                print("Error stopping recording: \(error.localizedDescription)")
            } else if let previewViewController = previewViewController {
                // Handle the preview controller (optional)
                // You can present the previewViewController to allow the user to preview and share the recording.
                self.present(previewViewController, animated: true, completion: nil)
            }
        }
        
    }

    
    @IBAction func stopRecord(_ sender: Any) {
        recorder.stopRecording { (previewVC, error) in
            if let previewVC = previewVC {
                previewVC.previewControllerDelegate = self
                self.present(previewVC, animated: true, completion: nil)
            }
            
            if let error = error {
                print("error")
            }
        }
        // Remove the overlay window
        self.overlayWindow?.isHidden = true
        self.overlayWindow = nil
        
        
        videoButton.isHidden = false
        saveButton.isHidden = false
        shareButton.isHidden = false
        captureButton.isHidden = false
        recapture.isHidden = false
        stop.isHidden = false
        
    }
    
    
    
    
    
    @IBAction func retakeButtonTapped(_ sender: Any) {
        recapture.isHidden = true
        captureButton.isHidden = false
        saveButton.isHidden = true
        shareButton.isHidden = true
        
    }
    
    
    @objc func fakeButtonTapped() {
        // Handle the tap on the fake button
        print("Fake button tapped")
        recorder.stopRecording { (previewVC, error) in
            if let previewVC = previewVC {
                previewVC.previewControllerDelegate = self
                self.present(previewVC, animated: true, completion: nil)
            }
            
            if let error = error {
                print("error")
            }
        }
        // Remove the overlay window
        self.overlayWindow?.isHidden = true
        self.overlayWindow = nil
        
        videoButton.isHidden = false
        captureButton.isHidden = false
        navigationController?.setNavigationBarHidden(false, animated: true)

        
        
    }
    
}


    extension CarDisplayViewController: SCNSceneRendererDelegate {
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            //Code to update the scene at each frame
            DispatchQueue.main.async{
        if !self.lastCarPlaced{
            self.updateElements(isObjectVisible: false)
                }
            }
        }
        

    }



extension CarDisplayViewController: RPPreviewViewControllerDelegate {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true, completion: nil)
    }
}
