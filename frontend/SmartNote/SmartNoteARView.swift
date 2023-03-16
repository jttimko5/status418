//
//  SmartNoteARView.swift
//  SmartNote
//
//  Created by Kane Sweet on 3/16/23.
//

import SwiftUI
import RealityKit

struct SmartNoteARView: View {
    @StateObject private var viewModel = SmartNoteARViewModel()
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
    
    init() {

        // Create a box mesh
        let mesh = MeshResource.generateBox(size: [0.2, 0.2, 0.001])
        
        let imageName = "amongus"
        
        // Create a material
        var material = SimpleMaterial()
        material.color.texture = .init(try! .load(named: imageName))
        
        // Create a model entity with the mesh and material
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        // Create an anchor and add the entity to the scene
        let anchor = AnchorEntity(world: [0, 0, -0.5])
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
    }
}

struct ARViewContainer: UIViewRepresentable {
    let arView: ARView
    
    func makeUIView(context: Context) -> ARView {
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

