//
//  SmartNoteARView.swift
//  SmartNote
//
//  Created by Kane Sweet on 3/16/23.
//

import Foundation
import SwiftUI
import RealityKit
import Photos
import ARKit
import AVKit
import SpriteKit
import Vision

struct SmartNoteARView: View {
    var IdentifierInput: Array<String>
    @StateObject private var viewModel: SmartNoteARViewModel
        
    init(IdentifierInput: Array<String>) {
        self.IdentifierInput = IdentifierInput
        self._viewModel = StateObject(wrappedValue: SmartNoteARViewModel(identifiers: IdentifierInput))
    }
//    init(IdentifierInput: Array<String>, fitnessdata: String) {
//        self.IdentifierInput = IdentifierInput
//        self._viewModel = StateObject(wrappedValue: SmartNoteARViewModel(identifiers: IdentifierInput, fitnessdata: fitnessdata))
//    }
    init(IdentifierInput: Array<String>, fitnessdata: String, videoIdentifier: Array<String>) {
        self.IdentifierInput = IdentifierInput
        self._viewModel = StateObject(wrappedValue: SmartNoteARViewModel(identifiers: IdentifierInput, fitnessdata: fitnessdata, videoIdentifiers: videoIdentifier))
    }
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ARViewContainer(arView: viewModel.arView)
                .edgesIgnoringSafeArea(.all)
        }
    }
    
}

class SmartNoteARViewModel: ObservableObject {
    let arView = ARView(frame: .zero)
    
    // Default constructor to test single image from Assets folder
    init() {
        // Create a box mesh
        let mesh = MeshResource.generateBox(size: [0.2, 0.0001, 0.2])
        
        // Create a material
        let imageName = "amongus"
        var material = SimpleMaterial()
        material.color.texture = .init(try! .load(named: imageName))
        
        // Create a model entity with the mesh and material
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        // Create an anchor and add the entity to the scene
        let anchor = AnchorEntity(world: [0, -0.5, -0.5])
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
    }
    
    // Constructor for handling multiple images from url
    init(identifiers: Array<String>) {
        for (i, identifier) in identifiers.enumerated() {
            
            //Access photos by local identifiers
            let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            
            //Check whether you can find the image
            guard let asset = assetResults.firstObject else {
                print("Could not find asset with local identifier: \(identifier)")
                return
            }
            let options = PHContentEditingInputRequestOptions()
            if asset.mediaType == .image {
                asset.requestContentEditingInput(with: options) { input, _ in
                    guard let imageURL = input?.fullSizeImageURL else {
                        print("Could not retrieve image URL for asset: \(asset)")
                        return
                    }
                    // Create a box mesh
                    let len = 0.2
                    let height = 0.2
                    let mesh = MeshResource.generateBox(size: [Float(len), 0.0001, Float(height)])
                    
                    // Create a material
                    var material = SimpleMaterial()
                    let texture = try! TextureResource.load(contentsOf: imageURL)
                    material.color.texture = PhysicallyBasedMaterial.Texture(texture)
                    
                    // Create a model entity with the mesh and material
                    let entity = ModelEntity(mesh: mesh, materials: [material])
                    
                    // Create an anchor and add the entity to the scene
                    let numRows = 3
                    let row = i % numRows
                    let col = Int(i / numRows)
                    let x = 0 + ((len + 0.01) * Double(col))
                    let y = -0.5
                    let z = -0.5 + ((height + 0.01) * Double(row))
                    let anchor = AnchorEntity(world: [Float(x), Float(y), Float(z)])
                    anchor.addChild(entity)
                    self.arView.scene.addAnchor(anchor)
                }
            }
// TODO: Show video in AR
//            else if asset.mediaType == .video {
//                VideoARView(identifier: identifier)
//            }
        }
    }
    init(identifiers: Array<String>, fitnessdata: String, videoIdentifiers: Array<String>) {
        for (i, identifier) in identifiers.enumerated() {
            
            //Access photos by local identifiers
            let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            
            //Check whether you can find the image
            guard let asset = assetResults.firstObject else {
                print("Could not find asset with local identifier: \(identifier)")
                return
            }
            let options = PHContentEditingInputRequestOptions()
            if asset.mediaType == .image {
                asset.requestContentEditingInput(with: options) { input, _ in
                    guard let imageURL = input?.fullSizeImageURL else {
                        print("Could not retrieve image URL for asset: \(asset)")
                        return
                    }
                    // Create a box mesh
                    let len = 0.2
                    let height = 0.2
                    let mesh = MeshResource.generateBox(size: [Float(len), 0.0001, Float(height)])
                    
                    // Create a material
                    var material = SimpleMaterial()
                    let texture = try! TextureResource.load(contentsOf: imageURL)
                    material.color.texture = PhysicallyBasedMaterial.Texture(texture)
                    
                    // Create a model entity with the mesh and material
                    let entity = ModelEntity(mesh: mesh, materials: [material])
                    
                    // Create an anchor and add the entity to the scene
                    let numRows = 3
                    let row = i % numRows
                    let col = Int(i / numRows)
                    let x = 0 + ((len + 0.01) * Double(col))
                    let y = -0.5
                    let z = -0.5 + ((height + 0.01) * Double(row))
                    let anchor = AnchorEntity(world: [Float(x), Float(y), Float(z)])
                    anchor.addChild(entity)
                    self.arView.scene.addAnchor(anchor)
                }
            }
//            else if asset.mediaType == .video {
//                VideoARView(identifier: identifier)
//            }
        }
        if fitnessdata.isEmpty == false {
            let textEntity = Entity()
            let textMesh = MeshResource.generateText(fitnessdata, extrusionDepth: 0.01)
            let textMaterial = SimpleMaterial(color: .orange, roughness: 0.5, isMetallic: false)
            let textModel = ModelEntity(mesh: textMesh, materials: [textMaterial])
            textEntity.addChild(textModel)
            
            // Set the font and font size for the text
            textModel.scale = SIMD3<Float>(repeating: 0.01)
            textModel.position.y += 0.1
            
            // Position the text entity in the scene
            let initialPosition = SIMD3<Float>(-1, -1, -1)
            let anchor = AnchorEntity(world: initialPosition)
            anchor.addChild(textEntity)
            
            // Add the anchor to the ARView's scene
            arView.scene.addAnchor(anchor)
            // Add interaction
            
        }
        for (i, identifier) in videoIdentifiers.enumerated() {
            
            //Access photos by local identifiers
            let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            
            //Check whether you can find the image
            guard let asset = assetResults.firstObject else {
                print("Could not find asset with local identifier: \(identifier)")
                return
            }
            let options = PHContentEditingInputRequestOptions()
            if asset.mediaType == .video {
            VideoARView(identifier: identifier)
            }
        }
        }
}

struct ARViewContainer: UIViewRepresentable {
    let arView: ARView
    
    func makeUIView(context: Context) -> ARView {
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}



class VideoARView: ObservableObject {

    @IBOutlet weak var arView: ARSCNView!
    @IBOutlet var pauseButton: UIButton!
    @IBOutlet var progressSlider: UISlider!
    @IBOutlet var nextButton: UIButton!

    let player = AVPlayer()
    var videoNode = SKVideoNode()

    init() {
    }

    init(identifier: String) {

        // Replace with the local identifier of the video you want to load
        let localIdentifier = identifier

        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestAVAsset(forVideo: PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject!, options: options) { asset, _, _ in
            guard let asset = asset else {
                return
            }

            DispatchQueue.main.async {
                self.player.replaceCurrentItem(with: AVPlayerItem(asset: asset))
                self.videoNode = SKVideoNode(avPlayer: self.player)
            }
        }

        let skScene = SKScene(size: CGSize(width: 1280, height: 720))
        skScene.addChild(videoNode)

        let plane = SCNPlane(width: 1.0, height: 0.5)
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.diffuse.contents = skScene

        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2

        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        arView.scene.rootNode.addChildNode(planeNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let videoAnchor = anchor as? ARImageAnchor, videoAnchor == arView.session.currentFrame?.anchors.first {
            player.play()
        }
    }
    //    @IBAction func pauseButtonTapped(_ sender: Any) {
    //        if player?.rate == 0 {
    //            // Player is currently paused, so play it
    //            player?.play()
    //            pauseButton.setTitle("Pause", for: .normal)
    //        } else {
    //            // Player is currently playing, so pause it
    //            player?.pause()
    //            pauseButton.setTitle("Play", for: .normal)
    //        }
    //    }
    //    @IBAction func progressSliderValueChanged(_ sender: UISlider) {
    //        if let player = player {
    //            player.seek(to: CMTime(seconds: Double(sender.value), preferredTimescale: 1))
    //        }
    //    }
    //
    //    @IBAction func nextButtonTapped(_ sender: Any) {
    //        currentVideoIndex = (currentVideoIndex + 1) % videoNodes.count
    //        playVideo()
    //        sceneView.scene.rootNode.childNodes.filter { $0 != videoNodes[currentVideoIndex] }.forEach { $0.removeFromParentNode() }
    //        sceneView.scene.rootNode.addChildNode(videoNodes[currentVideoIndex])
    //    }

}


//class ARVideoDisplay: UIViewController, ARSCNViewDelegate {
//
//    @IBOutlet var sceneView: ARSCNView!
//    @IBOutlet var pauseButton: UIButton!
//    @IBOutlet var progressSlider: UISlider!
//    @IBOutlet var nextButton: UIButton!
//
//    var player: AVPlayer?
//    var playerLayer: AVPlayerLayer?
//    var videoNodes: [SCNNode] = []
//    var currentVideoIndex: Int = 0
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        sceneView.delegate = self
//
//        // Add container node for video content
//        let videoContainerNode = SCNNode()
//        sceneView.scene.rootNode.addChildNode(videoContainerNode)
//
//        // Create AVPlayerLayer and add to container node
//        playerLayer = AVPlayerLayer(player: player)
//        playerLayer?.frame = view.bounds
//        playerLayer?.videoGravity = .resizeAspectFill
//
//        let videoNode = SCNNode()
//        videoNode.geometry = SCNPlane(width: 1.0, height: 0.5)
//        videoNode.geometry?.firstMaterial?.diffuse.contents = playerLayer
//        videoNode.eulerAngles.x = -.pi / 2
//        videoContainerNode.addChildNode(videoNode)
//        videoNodes.append(videoNode)
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        let configuration = ARWorldTrackingConfiguration()
//        sceneView.session.run(configuration)
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//
//        sceneView.session.pause()
//    }
//
//    func playVideo() {
//        guard let videoURL = Bundle.main.url(forResource: "video\(currentVideoIndex)", withExtension: "mp4") else {
//            print("Error: Could not find video file")
//            return
//        }
//        player = AVPlayer(url: videoURL)
//        playerLayer?.player = player
//        player?.play()
//    }
//
//    @IBAction func pauseButtonTapped(_ sender: Any) {
//        if player?.rate == 0 {
//            // Player is currently paused, so play it
//            player?.play()
//            pauseButton.setTitle("Pause", for: .normal)
//        } else {
//            // Player is currently playing, so pause it
//            player?.pause()
//            pauseButton.setTitle("Play", for: .normal)
//        }
//    }
//
//
//    @IBAction func progressSliderValueChanged(_ sender: UISlider) {
//        if let player = player {
//            player.seek(to: CMTime(seconds: Double(sender.value), preferredTimescale: 1))
//        }
//    }
//
//    @IBAction func nextButtonTapped(_ sender: Any) {
//        currentVideoIndex = (currentVideoIndex + 1) % videoNodes.count
//        playVideo()
//        sceneView.scene.rootNode.childNodes.filter { $0 != videoNodes[currentVideoIndex] }.forEach { $0.removeFromParentNode() }
//        sceneView.scene.rootNode.addChildNode(videoNodes[currentVideoIndex])
//    }
//
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
//
//        // Resize video node to match plane size
//        let size = CGSize(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
//        videoNodes.forEach { $0.scale = SCNVector3(size.width, 1.0, size.height) }
//    }
//}
