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
import Vision

struct SmartNoteARView: View {
    var URLinput: Array<String>
//    @StateObject private var viewModel = SmartNoteARViewModel(
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
//    )
    @StateObject private var viewModel: SmartNoteARViewModel
        
    init(URLinput: Array<String>) {
        self.URLinput = URLinput
        self._viewModel = StateObject(wrappedValue: SmartNoteARViewModel(urls: URLinput))
    }
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
        
        // Create an anchor and add the entity to the scene
        let anchor = AnchorEntity(world: [0, -0.5, -0.5])
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
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

