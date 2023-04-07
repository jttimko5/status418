//
//  SmartNoteARView.swift
//  SmartNote
//
//  Created by Kane Sweet on 3/16/23.
//

import Foundation
import SwiftUI
import RealityKit

struct SmartNoteARView: View {
    @StateObject private var viewModel = SmartNoteARViewModel(
//        urls:
//        [
//            // Random test URLs
//            "https://www.applesfromny.com/wp-content/uploads/2020/06/SnapdragonNEW.png",
//            "https://www.applesfromny.com/wp-content/uploads/2020/08/Evercrisp_NYAS-Apples2.png",
//            "https://upload.wikimedia.org/wikipedia/commons/1/15/Red_Apple.jpg",
//            "https://www.applesfromny.com/wp-content/uploads/2020/05/20Ounce_NYAS-Apples2.png",
//            "https://www.applesfromny.com/wp-content/uploads/2020/08/Evercrisp_NYAS-Apples2.png",
//            "https://upload.wikimedia.org/wikipedia/commons/1/15/Red_Apple.jpg",
//            "https://www.applesfromny.com/wp-content/uploads/2020/05/20Ounce_NYAS-Apples2.png"
//        ]
    )
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ARViewContainer(arView: viewModel.arView)
                .edgesIgnoringSafeArea(.all)
//                .navigationBarTitle(Text("SmartNote AR View"))
//                .navigationBarTitleDisplayMode(.inline)
//                .navigationBarItems(trailing: Button(action: {
//                    presentationMode.wrappedValue.dismiss()
//                }, label: {
//                    Text("Close")
//                }))
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
            entity: entity
        )
        arView.addGestureRecognizer(swipeGestureRecognizer)
    }

    @objc func handleSwipe(_ recognizer: MaterialSwipeGestureRecognizer) {
        guard var modelEntity = recognizer.entity else { return }
        
        // hit test
        let touchLocation = recognizer.location(in: arView)
        print(touchLocation)
        let hitTestResults = arView.hitTest(touchLocation)
        print(hitTestResults)
        var found = false
        for result in hitTestResults {
            if result.entity == modelEntity {
                found = true
            }
        }
        if !found { return }

        print("handling swipe")
        let imageName = recognizer.imageNames[recognizer.imageIdx % recognizer.imageNames.count]
        recognizer.imageIdx += 1

        if var modelComponent = modelEntity.components[ModelComponent.self] as? ModelComponent {
            for (index, material) in modelComponent.materials.enumerated() {
                if var simpleMaterial = material as? SimpleMaterial {
                    // Update the texture of the existing material
                    simpleMaterial.color.texture = .init(try! .load(named: imageName))
                    modelComponent.materials[index] = simpleMaterial
                }
            }
            // Apply the updated materials to the model entity
            modelEntity.components[ModelComponent.self] = modelComponent
        }
        
    }
    // Constructor for handling multiple images from url
    init(urls: Array<String>) {
        for (i, url) in urls.enumerated() {
            
            //-------------------------------------------------------------------------
            // File retrieval
            // Temporary implementation. Very slow blocking code added to help test anchoring
            // Zhihao will replace with better code later
            let remoteURL = URL(string: url)!
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let data = try! Data(contentsOf: remoteURL)
            try! data.write(to: fileURL)
            //-------------------------------------------------------------------------
            
            // Create a box mesh
            let len = 0.2
            let height = 0.2
            let mesh = MeshResource.generateBox(size: [Float(len), 0.0001, Float(height)])
            
            // Create a material
            var material = SimpleMaterial()
            let texture = try! TextureResource.load(contentsOf: fileURL)
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
            arView.scene.addAnchor(anchor)
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

class MaterialSwipeGestureRecognizer: UISwipeGestureRecognizer {
    var entity: ModelEntity?
    let imageNames = ["petergriffin", "amongus"]
    var imageIdx = 0

    convenience init(target: Any?, action: Selector?, entity: ModelEntity) {
        self.init(target: target, action: action)
        self.entity = entity
    }
}
