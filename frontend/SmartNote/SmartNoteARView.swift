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
import UIKit
import AVFoundation

struct SmartNoteARView: View {
    @StateObject private var viewModel: SmartNoteARViewModel
  
    init(keywords: [String], dates: [String]) {
        self._viewModel = StateObject(wrappedValue: SmartNoteARViewModel(
            keywords: keywords,
            dates: dates
        )
        )
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
    let keywords: [String]
    let dates: [String]

    // Constructor for handling multiple images from url
    init(
        keywords: [String],
        dates: [String]
    ) {
        print("hello from ar view")
        print("keywords", keywords)
        print("dates", dates)
        self.keywords = keywords
        self.dates = dates

        // album
        DispatchQueue.global().async {
            let identifiers: Array<String> = self.findPhotos()
            DispatchQueue.main.async {
                self.handleAlbum(identifiers: identifiers)
            }
        }
        // steps
        DispatchQueue.global().async {
            let stepsInput = self.findSteps()
            DispatchQueue.main.async {
                self.handleSteps(stepsInput: stepsInput)
            }
        }
        // events
        DispatchQueue.global().async {
            let eventsInput = self.findEvents()
            DispatchQueue.main.async {
                self.handleEvents(eventsInput: eventsInput)
            }
        }
        // videos
//        DispatchQueue.global().async {
//            let identifiers: String = self.findVideos()
//            DispatchQueue.main.async {
//                self.displayVideo(identifier: "D20156CC-2A09-4FBF-BF7D-19C516E3D5A3/L0/001")
//            }
//        }
    }
    
    func handleSteps(stepsInput: HealthKitViewModel) {
        print("handleSteps called")
        print("steps:", stepsInput.userStepCount)
        let stepsString = "Steps: " + String(stepsInput.userStepCount)
        // create entity
        let mesh = MeshResource.generateBox(size: [0.2, 0.0001, 0.2])
        let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial()])
        displayTextAsset(text: stepsString, modelEntity: entity)
        
        let collisionShape = ShapeResource.generateBox(size: [0.2, 0.0001, 0.2])
        let collisionComponent = CollisionComponent(shapes: [collisionShape])
        entity.components.set([
            collisionComponent
        ])
        
        // Create an anchor and add the entity to the scene
        let anchor = AnchorEntity(world: [0.42, -0.5, -0.5])
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
        
        // Add interaction to the entity
        let stepsGesture = EntityGestureRecognizer(for: entity, on: arView)
        stepsGesture.addTarget(self, action: #selector(handleStepsGesture(_:)))
        arView.addGestureRecognizer(stepsGesture)
        entity.generateCollisionShapes(recursive: true)
        arView.installGestures(.all, for: entity)
    }
    
    func handleEvents(eventsInput: String?) {
        print("handleEvents called. Events:", eventsInput!)
        if eventsInput != nil {
            // create entity
            let mesh = MeshResource.generateBox(size: [0.2, 0.0001, 0.2])
            let entity = ModelEntity(mesh: mesh, materials: [SimpleMaterial()])
            displayTextAsset(text: eventsInput!, modelEntity: entity)
            
            let collisionShape = ShapeResource.generateBox(size: [0.2, 0.0001, 0.2])
            let collisionComponent = CollisionComponent(shapes: [collisionShape])
            entity.components.set([
                collisionComponent
            ])
            
            // Create an anchor and add the entity to the scene
            let anchor = AnchorEntity(world: [0.21, -0.5, -0.5])
            anchor.addChild(entity)
            arView.scene.addAnchor(anchor)
            
            // Add interaction to the entity
            let eventsGesture = EntityGestureRecognizer(for: entity, on: arView)
            eventsGesture.addTarget(self, action: #selector(handleEventsGesture(_:)))
            arView.addGestureRecognizer(eventsGesture)
            entity.generateCollisionShapes(recursive: true)
            arView.installGestures(.all, for: entity)
        
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
        
        // Add interaction to the entity
        let albumGesture = EntityGestureRecognizer(for: entity, on: arView)
        albumGesture.addTarget(self, action: #selector(handleAlbumGesture(_:)))
        arView.addGestureRecognizer(albumGesture)
        entity.generateCollisionShapes(recursive: true)
        arView.installGestures(.all, for: entity)
        
        // Add double tap gesture recognizer
        let doubleTapGestureRecognizer = EntityDoubleTapGestureRecognizer(
            target: self,
            action: #selector(handleDoubleTap(_:)),
            entity: entity,
            albumAssets: assets
        )
        arView.addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    func displayVideo(identifier: String) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject!, options: options) { (avAsset, _, _) in
            DispatchQueue.main.async {
                guard let asset = avAsset else { return }
                let playerItem = AVPlayerItem(asset: asset)
                let player = AVQueuePlayer(playerItem: playerItem) // Replace AVPlayer with AVQueuePlayer
                
                let playerNode = VideoPlayerNode(avPlayer: player)
                let playerEntity = playerNode.generateModelEntity(width: 0.4, height: 0.3)
                
                let collisionShape = ShapeResource.generateBox(size: [0.2, 0.0001, 0.2])
                let collisionComponent = CollisionComponent(shapes: [collisionShape])
                playerEntity.components.set([
                    collisionComponent
                ])
                
                let anchor = AnchorEntity(world: [0.63, -0.5, -0.5])
                anchor.addChild(playerEntity)
                self.arView.scene.addAnchor(anchor)
                
                let playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
                
                // Create and configure the play/pause button
                let playPauseButton = UIButton(type: .system)
                playPauseButton.setTitle("Pause", for: .normal)
                playPauseButton.frame = CGRect(x: 325, y: 45, width: 60, height: 30)
                playPauseButton.backgroundColor = UIColor.white.withAlphaComponent(0.8)
                playPauseButton.addTarget(self, action: #selector(self.playPauseButtonTapped(_:)), for: .touchUpInside)
                self.arView.addSubview(playPauseButton)
                
                // Play the video
                player.play()
            }
        }
    }

    @objc func playPauseButtonTapped(_ sender: UIButton) {
        if let playerNode = arView.scene.findEntity(named: "VideoPlayerNode") as? VideoPlayerNode {
            let player = playerNode.avPlayer
            
            if player.rate == 0 {
                player.play()
                sender.setTitle("Pause", for: .normal)
            } else {
                player.pause()
                sender.setTitle("Play", for: .normal)
            }
        }
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
    
    func displayTextAsset(text: String, modelEntity: ModelEntity) {
        // convert text to something that can be loaded into texture resource
        if let texture = createTextTexture(
            text: text,
            font: UIFont.systemFont(ofSize: 24),
            size: CGSize(width: 128, height: 128)) {
            if var modelComponent = modelEntity.components[ModelComponent.self] as? ModelComponent {
                for (index, material) in modelComponent.materials.enumerated() {
                    if var simpleMaterial = material as? SimpleMaterial {
                        // Update the texture of the existing material
                        simpleMaterial.color.texture = PhysicallyBasedMaterial.Texture(texture)
                        modelComponent.materials[index] = simpleMaterial
                    }
                }
                // Apply the updated materials to the model entity
                modelEntity.components[ModelComponent.self] = modelComponent
            }
        }
    }
    
    @objc func handleDoubleTap(_ recognizer: EntityDoubleTapGestureRecognizer) {
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
    @objc private func handleGesture(_ gestureRecognizer: EntityGestureRecognizer) {
        guard let entity = gestureRecognizer.entity else { return }
        let translation = gestureRecognizer.translation
        let position = entity.position
        entity.position = SIMD3<Float>(x: position.x + Float(translation.x / 100), y: position.y + Float(-translation.y / 100), z: position.z)
        gestureRecognizer.translation = .zero
    }

    //TO make all three objects moving
    @objc private func handleAlbumGesture(_ gestureRecognizer: EntityGestureRecognizer) {
        handleEntityGesture(gestureRecognizer)
    }
    @objc private func handleStepsGesture(_ gestureRecognizer: EntityGestureRecognizer) {
        handleEntityGesture(gestureRecognizer)
    }

    @objc private func handleEventsGesture(_ gestureRecognizer: EntityGestureRecognizer) {
        handleEntityGesture(gestureRecognizer)
    }
    private func handleEntityGesture(_ gestureRecognizer: EntityGestureRecognizer) {
        guard let entity = gestureRecognizer.entity else { return }
        let translation = gestureRecognizer.translation
        let position = entity.position
        entity.position = SIMD3<Float>(x: position.x + Float(translation.x / 100), y: position.y + Float(-translation.y / 100), z: position.z)
        gestureRecognizer.translation = .zero
    }
    
    // Delete this function after activate the one above
    func findPhotos() -> [String] {
        print("findPhotos called")
        print("keywords:", self.keywords)
        print("dates:", self.dates)
        let photosIdentifier = showPhotosForKeywords(keywords: self.keywords, time: self.dates)
        print("findPhotos finished")
        print(photosIdentifier)
        return photosIdentifier
    }
    
    func findVideos() -> String {
        print("findPhotos called")
        print("keywords:", self.keywords)
        print("dates:", self.dates)
        let videoIdentifier = fetchVideoIdentifier(withKeywords: ["4", "3", "0", "objects", "Bronx", "Haiyang Park", "People"])
        print("findVideos finished")
        print(videoIdentifier)
        return videoIdentifier
    }

    func findEvents() -> String? {
        print("findEvents called")
        let dates = getConvertedDates()
        let events = pullEvents(dates: dates)
        print("findEvents finished")
        return events
    }

    func findSteps() -> HealthKitViewModel {
        print("findSteps called")
        let dates = getConvertedDates()
        let hkmodel = HealthKitViewModel()
        if (dates[0] != nil) {
            hkmodel.healthRequest(date: dates[0] ?? Date())
            for date in dates {
                hkmodel.readStepsTakenToday(date: date!)
            }
        }
        while hkmodel.userStepCount == "" {
            // do nothing
        }
        print("findSteps finished")
        return hkmodel
    }
    
    func getConvertedDates() -> [Date?] {
        let dates = self.dates
        
        var list: [Date?] = []
        
        for date in dates ?? [] {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            dateFormatter.timeZone = TimeZone.current
            dateFormatter.locale = Locale.current
            let date_object: Date? = dateFormatter.date(from: date)
            list.append(date_object)
        }
        return list
    }
}


struct ARViewContainer: UIViewRepresentable {
    let arView: ARView
    
    func makeUIView(context: Context) -> ARView {
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}


//class MaterialSwipeGestureRecognizer: UISwipeGestureRecognizer {
//    var entity: ModelEntity?
//    var albumAssets: [PHAsset] = []
//    var imageIdx = 1
//
//    convenience init(target: Any?, action: Selector?, entity: ModelEntity, albumAssets: [PHAsset]) {
//        self.init(target: target, action: action)
//        self.entity = entity
//        self.albumAssets = albumAssets
//    }
//}

class EntityDoubleTapGestureRecognizer: UITapGestureRecognizer {
    var entity: ModelEntity?
    var albumAssets: [PHAsset] = []
    var imageIdx = 1

    convenience init(target: Any?, action: Selector?, entity: ModelEntity, albumAssets: [PHAsset]) {
        self.init(target: target, action: action)
        self.entity = entity
        self.albumAssets = albumAssets
        self.numberOfTapsRequired = 2
    }
}


func createTextTexture(text: String, font: UIFont, size: CGSize) -> TextureResource? {
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { context in
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        attributedText.draw(in: CGRect(origin: .zero, size: size))
    }
    let options = TextureResource.CreateOptions(semantic: TextureResource.Semantic.raw)
    let texture = try? TextureResource.generate(
        from: image.cgImage!,
        options: options)
    return texture
}

// Gesture (move the AR objects)
class EntityGestureRecognizer: UIGestureRecognizer {
    weak var entity: Entity?
    weak var arView: ARView?
    var translation: CGPoint = .zero
    var isTouchOnEntity: Bool = false
    
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
            let hitTestResults = view.hitTest(location, types: .existingPlaneUsingGeometry)
            isTouchOnEntity = false
            for result in hitTestResults {
                if let anchor = result.anchor {
                    let hitEntities = view.entities(at: location)
                    for hitEntity in hitEntities {
                        if hitEntity == self.entity {
                            isTouchOnEntity = true
                        }
                    }
                }
            }

            if isTouchOnEntity {
                let prevLocation = touch.previousLocation(in: view)
                let dx = location.x - prevLocation.x
                let dy = location.y - prevLocation.y
                translation = CGPoint(x: dx, y: dy)
                state = .changed
            } else {
                state = .cancelled
            }
        }
    }

    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .ended
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
    
}


class VideoPlayerNode: Entity {
    let avPlayer: AVQueuePlayer // Replace AVPlayer with AVQueuePlayer
    
    init(avPlayer: AVQueuePlayer) { // Replace AVPlayer with AVQueuePlayer
        self.avPlayer = avPlayer
        super.init()
    }
    
    func generateModelEntity(width: Float, height: Float) -> ModelEntity {
        let videoMaterial = VideoMaterial(avPlayer: self.avPlayer)
        let mesh = MeshResource.generateBox(size: [0.2, 0.0001, 0.2])
        let videoPlane = MeshResource.generatePlane(width: width, height: height)
        let modelEntity = ModelEntity(mesh: mesh, materials: [videoMaterial])
        return modelEntity
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}

