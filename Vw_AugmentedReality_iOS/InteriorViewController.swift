//
//  InteriorViewController.swift
//  arVW
//
//  Created by Bryce Cooperkawa on 9/28/23.
//

import UIKit
import RealityKit
import ARKit
import AVFoundation

class InteriorViewController: UIViewController {
    
    @IBOutlet weak var arView: ARView!
    
    //name of car to determine which car should be shown
    var carName = "DANNY 'DIMES' JONES"
    
    //holds the positions string that is being passed from the database
    var positions = ""
    
    //the car entity holder
    var carEntity = ModelEntity()
    
    //var that represents the sphere entity to make sound happen
    var sphereEntity: ModelEntity!
    
    //var that represents the audio player
    var audioPlayer: AVAudioPlayer?
    
    //will hold the positions converted to an array of SIMD3 positions
    var simdPositionsArray: [SIMD3<Float>] = []
    
    //represents the current position in the model except for the inital open
    var seatCounter = 1;

    //sets the car in the prepare segue
    func setCar(String modelName:String,ModelEntity carModel: ModelEntity, String interiorPositions:String){
        carName = modelName
        carModel.name = carName
        carEntity = carModel
        positions = interiorPositions
    }
    
    //on load will set inital anchor in driver seat
    override func viewDidLoad(){
        super.viewDidLoad()
           
        //loads the sound
        loadSound()
           
        //convert positions string to an array of SIMD3 positions
        //coordinates = positions string with () removed and split into seperate coordinates
        let coordinates = positions.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").components(separatedBy: ",")
        //loop through the seperated coordinates and set the individual SIMD3 vectors
        for i in stride(from: 0, to: coordinates.count, by: 3) {
            if let x = Float(coordinates[i]), let y = Float(coordinates[i + 1]), let z = Float(coordinates[i + 2]) {
                //set the vector
                let simdPositionsVector = SIMD3<Float>(x: x, y: y, z: z)
                //add the vector to the positions array
                simdPositionsArray.append(simdPositionsVector)
            }
        }
           
        //set anchor for car with positions
        var carAnchor = AnchorEntity()
        carAnchor = AnchorEntity(world: simdPositionsArray[0])
        carAnchor.addChild(carEntity)
           
        //add anchor to scene
        arView.scene.addAnchor(carAnchor)
           
        //sphere that will be used for sound
        let sphere = MeshResource.generateSphere(radius: 1)
        let material = UnlitMaterial(color: .clear)
        sphereEntity = ModelEntity(mesh: sphere, materials: [material])
        
        //set the sphere in front of the user
        let sphereAnchor = AnchorEntity(world: SIMD3(x: 0, y: -1.45, z: 3 ))
        sphereAnchor.addChild(sphereEntity)
        arView.scene.addAnchor(sphereAnchor)
        
        //turn on user interaction for the sphere and the ar view
        sphereEntity.generateCollisionShapes(recursive: true)
        arView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        //add the function as the handler for interaction
        arView.addGestureRecognizer(tapGesture)
    }

    
    //activates on button press to take user to next seat
    @IBAction func swapButtonPressed(_ sender: Any) {
        //set the anchor to the new position
        setAnchor(newPosition: simdPositionsArray[seatCounter], model: carEntity, arView: arView)
        
        //update counter to cycle through seat positions
        if (seatCounter + 1) == simdPositionsArray.count{
            seatCounter = 0
        }else{
            seatCounter = seatCounter + 1
        }
        
        //enables sphere for honk sound
        enableSphere()
    }

    
    //sets the anchor given the new position, model and ar view
    func setAnchor(newPosition: SIMD3<Float>, model: ModelEntity, arView: ARView){
        //remove any existing anchor
        if let anchor = model.anchor {
            arView.scene.anchors.remove(anchor)
        }
        
        //new anchor
        let newAnchor = AnchorEntity(world: newPosition)
        newAnchor.addChild(model)
        
        //add anchor to scene
        arView.scene.addAnchor(newAnchor)
    }
    
    //on the user touching the sphere that exists over the steering wheel will play a sound
    @objc func handleTap(_ gesture: UITapGestureRecognizer){
        //get location of the tap
        let tapLocation = gesture.location(in: arView)
        
        //get the entity that was hit
        let hitEntity = arView.entity(at: tapLocation)
        //if the entity exists then play the horn sound
        if hitEntity != nil{
            playSound()
        }
        
    }
    
    //sets up the functionality of playing the sound, gets it ready to play
    func loadSound() {
        if let soundURL = Bundle.main.url(forResource: "car_horn", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error loading sound: \(error.localizedDescription)")
            }
        } else {
            print("Sound file not found.")
        }
    }
    
    //used to play the sound
    func playSound() {
        audioPlayer?.play()
    }
    
    //enables the sphere for sound only when user is in drivers seat
    func enableSphere(){
        if seatCounter == 1 {
            sphereEntity.isEnabled = true
        }else{
            sphereEntity.isEnabled = false
        }
    }
        
}

