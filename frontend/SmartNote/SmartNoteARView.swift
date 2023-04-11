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
    
//    // Default constructor to test single image from Assets folder
//    init() {
//        // Create a box mesh
//        let mesh = MeshResource.generateBox(size: [0.2, 0.0001, 0.2])
//
//        // Create a material
//        let imageName = "amongus"
//        var material = SimpleMaterial()
//        material.color.texture = .init(try! .load(named: imageName))
//
//        // Create a model entity with the mesh and material
//        let entity = ModelEntity(mesh: mesh, materials: [material])
//
//        // Add collision component
//        let collisionShape = ShapeResource.generateBox(size: [0.2, 0.0001, 0.2])
//        let collisionComponent = CollisionComponent(shapes: [collisionShape])
//        entity.components.set([
//            collisionComponent
//        ])
//
//        // Create an anchor and add the entity to the scene
//        let anchor = AnchorEntity(world: [0, -0.5, -0.5])
//        anchor.addChild(entity)
//        arView.scene.addAnchor(anchor)
//
//        // Add swipe gesture recognizer
//        let swipeGestureRecognizer = MaterialSwipeGestureRecognizer(
//            target: self,
//            action: #selector(handleSwipe(_:)),
//            entity: entity
//        )
//        arView.addGestureRecognizer(swipeGestureRecognizer)
//    }

    // Constructor for handling multiple images from url
    init(identifiers: Array<String>) {
        print("hello from ar view")
        print("identifiers.count:", identifiers.count)
        handleAlbum(identifiers: identifiers)
    }
    
//    // Constructor for handling multiple images from url
//    init(identifiers: Array<String>) {
//        for (i, identifier) in identifiers.enumerated() {
//
//            //Access photos by local identifiers
//            let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
//
//            //Check whether you can find the image
//            guard let asset = assetResults.firstObject else {
//                print("Could not find asset with local identifier: \(identifier)")
//                return
//            }
//            let options = PHContentEditingInputRequestOptions()
//            asset.requestContentEditingInput(with: options) { input, _ in
//                guard let imageURL = input?.fullSizeImageURL else {
//                    print("Could not retrieve image URL for asset: \(asset)")
//                    return
//                }
//                // Create a box mesh
//                let len = 0.2
//                let height = 0.2
//                let mesh = MeshResource.generateBox(size: [Float(len), 0.0001, Float(height)])
//
//                // Create a material
//                var material = SimpleMaterial()
//                let texture = try! TextureResource.load(contentsOf: imageURL)
//                material.color.texture = PhysicallyBasedMaterial.Texture(texture)
//
//                // Create a model entity with the mesh and material
//                let entity = ModelEntity(mesh: mesh, materials: [material])
//
//                // Create an anchor and add the entity to the scene
//                let numRows = 3
//                let row = i % numRows
//                let col = Int(i / numRows)
//                let x = 0 + ((len + 0.01) * Double(col))
//                let y = -0.5
//                let z = -0.5 + ((height + 0.01) * Double(row))
//                let anchor = AnchorEntity(world: [Float(x), Float(y), Float(z)])
//                anchor.addChild(entity)
//                self.arView.scene.addAnchor(anchor)
//            }
//        }
//    }
    
    func handleAlbum(identifiers: Array<String>) {
        if (identifiers.count == 0) {
            print("no images found")
            return
        }
        
        // extract assets
        var assets: [PHAsset] = []
        for (i, identifier) in identifiers.enumerated() {
            print(i)
            //Access photos by local identifiers
            let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            print("a")
            //Check whether you can find the image
            guard let asset = assetResults.firstObject else {
                print("Could not find asset with local identifier: \(identifier)")
                return
            }
            assets.append(asset)
        }

        // create entity
        let mesh = MeshResource.generateBox(size: [0.2, 0.0001, 0.2])
        let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial()])
        displayAlbumAsset(asset: assets[0], modelEntity: entity)
        
        // Add collision component
        let collisionShape = ShapeResource.generateBox(size: [0.2, 0.0001, 0.2])
        let collisionComponent = CollisionComponent(shapes: [collisionShape])
        entity.components.set([
            collisionComponent
        ])
        
        // Create an anchor and add the entity to the scene
        let anchor = AnchorEntity(world: [0, -0.5, -0.5])
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        
        // Add swipe gesture recognizer
        let swipeGestureRecognizer = MaterialSwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipe(_:)),
            entity: entity,
            albumAssets: assets
        )
        arView.addGestureRecognizer(swipeGestureRecognizer)
    }
    
    func displayAlbumAsset(asset: PHAsset, modelEntity: ModelEntity) {
        let options = PHContentEditingInputRequestOptions()
        asset.requestContentEditingInput(with: options) { input, _ in

            guard let imageURL = input?.fullSizeImageURL else {
                print("Could not retrieve image URL for asset: \(asset)")
                return
            }
            if var modelComponent = modelEntity.components[ModelComponent.self] as? ModelComponent {
                for (index, material) in modelComponent.materials.enumerated() {
                    if var simpleMaterial = material as? SimpleMaterial {
                        // Update the texture of the existing material
                        let texture = try! TextureResource.load(contentsOf: imageURL)
                        simpleMaterial.color.texture = PhysicallyBasedMaterial.Texture(texture)
                        modelComponent.materials[index] = simpleMaterial
                    }
                }
                // Apply the updated materials to the model entity
                modelEntity.components[ModelComponent.self] = modelComponent
            }
        }
    }
    
    @objc func handleSwipe(_ recognizer: MaterialSwipeGestureRecognizer) {
        guard let modelEntity = recognizer.entity else { return }

        // hit test
        let touchLocation = recognizer.location(in: arView)
        print(touchLocation)
        let hitTestResults = arView.hitTest(touchLocation)
        print(hitTestResults)
        var found = false
        for result in hitTestResults {
            if result.entity == modelEntity { found = true }
        }
        if !found { return }
        let asset = recognizer.albumAssets[recognizer.imageIdx % recognizer.albumAssets.count]
        recognizer.imageIdx += 1
        
        displayAlbumAsset(asset: asset, modelEntity: modelEntity)
    }
}


struct ARViewContainer: UIViewRepresentable {
    let arView: ARView
    
    func makeUIView(context: Context) -> ARView {
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}


class MaterialSwipeGestureRecognizer: UISwipeGestureRecognizer {
    var entity: ModelEntity?
    var albumAssets: [PHAsset] = []
    var imageIdx = 1

    convenience init(target: Any?, action: Selector?, entity: ModelEntity, albumAssets: [PHAsset]) {
        self.init(target: target, action: action)
        self.entity = entity
        self.albumAssets = albumAssets
    }
}



//TODO: Videos show in AR!
//class VideoARView: ObservableObject {
//
//    @IBOutlet weak var arView: ARSCNView!
//
//    let player = AVPlayer()
//    var videoNode = SKVideoNode()
//
//    init() {
//    }
//
//    init(identifier: String) {
//
//        // Replace with the local identifier of the video you want to load
//        let localIdentifier = identifier
//
//        let options = PHVideoRequestOptions()
//        options.isNetworkAccessAllowed = true
//
//        PHImageManager.default().requestAVAsset(forVideo: PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject!, options: options) { asset, _, _ in
//            guard let asset = asset else {
//                return
//            }
//
//            DispatchQueue.main.async {
//                self.player.replaceCurrentItem(with: AVPlayerItem(asset: asset))
//                self.videoNode = SKVideoNode(avPlayer: self.player)
//            }
//        }
//
//        let skScene = SKScene(size: CGSize(width: 1280, height: 720))
//        skScene.addChild(videoNode)
//
//        let plane = SCNPlane(width: 1.0, height: 0.5)
//        plane.firstMaterial?.isDoubleSided = true
//        plane.firstMaterial?.diffuse.contents = skScene
//
//        let planeNode = SCNNode(geometry: plane)
//        planeNode.eulerAngles.x = -.pi / 2
//
//        let configuration = ARWorldTrackingConfiguration()
//        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
//
//        arView.scene.rootNode.addChildNode(planeNode)
//    }
//
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        if let videoAnchor = anchor as? ARImageAnchor, videoAnchor == arView.session.currentFrame?.anchors.first {
//            player.play()
//        }
//    }
//}

