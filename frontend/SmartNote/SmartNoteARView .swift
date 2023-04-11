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
        
//    init(IdentifierInput: Array<String>) {
//        self.IdentifierInput = IdentifierInput
//        self._viewModel = StateObject(wrappedValue: SmartNoteARViewModel(identifiers: IdentifierInput))
//    }
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
    
    init(identifiers: Array<String>, fitnessdata: String, videoIdentifiers: Array<String>) {
        handleAlbum(identifiers: identifiers)
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
            // Add interaction to the entity
            let gesture = EntityGestureRecognizer(for: textEntity, on: arView)
            gesture.addTarget(self, action: #selector(handleGesture(_:)))
            self.arView.scene.addAnchor(anchor)
            
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
        // Add interaction to the entity
        let gesture = EntityGestureRecognizer(for: entity, on: arView)
        gesture.addTarget(self, action: #selector(handleGesture(_:)))
        self.arView.scene.addAnchor(anchor)
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
            print("There is a call to handleSwipe!")
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
    
    
    // Handle the move function
    @objc func handleGesture(_ gestureRecognizer: EntityGestureRecognizer) {
        print("There is a call to handleGesture function!")
        guard let entity = gestureRecognizer.entity else { return }
        let translation = gestureRecognizer.translation
        let position = entity.position
        entity.position = SIMD3<Float>(x: position.x + Float(translation.x / 100), y: position.y + Float(-translation.y / 100), z: position.z)
        gestureRecognizer.translation = .zero
    }
    }

struct ARViewContainer: UIViewRepresentable {
    let arView: ARView
    
    func makeUIView(context: Context) -> ARView {
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

// Swipe for images
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




// Video displayed:
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
    

}

// Gesture (move the AR objects)
class EntityGestureRecognizer: UIGestureRecognizer {
    weak var entity: Entity?
    weak var arView: ARView?
    var translation: CGPoint = .zero
    
    init(for entity: Entity, on arView: ARView) {
        self.entity = entity
        self.arView = arView
        super.init(target: nil, action: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if touches.count > 1 {
            state = .cancelled
            return
        }
        state = .began
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first, let view = arView else { return }
        if state == .began || state == .changed {
            let location = touch.location(in: view)
            let prevLocation = touch.previousLocation(in: view)
            let dx = location.x - prevLocation.x
            let dy = location.y - prevLocation.y
            translation = CGPoint(x: dx, y: dy)
            state = .changed
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .ended
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
}
