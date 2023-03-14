//
//  ImageView.swift
//  SmartNote
//
//  Created by Tim Stauder on 3/14/23.
//

import Foundation
import UIKit
import SwiftUI

struct ImagePickerView: UIViewControllerRepresentable {
    
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var isPresented
    @Binding var sourceType: UIImagePickerController.SourceType
        
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = self.sourceType
        imagePicker.delegate = context.coordinator // confirming the delegate
        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {

    }

    // Connecting the Coordinator class with this struct
    func makeCoordinator() -> Coordinator {
        return Coordinator(picker: self)
    }
}



class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var picker: ImagePickerView
    
    init(picker: ImagePickerView) {
        self.picker = picker
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        self.picker.selectedImage = selectedImage
        self.picker.isPresented.wrappedValue.dismiss()
    }
    
}

//final class ImageView: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//
//    @State private var isPresenting = false
//
//    static let shared = ImageView()
//    weak var scanImage: UIImageView!
//
//    func pickMedia() {
////        print("REACHED PICK MEDIA")
//
//        presentPicker(.photoLibrary)
//    }
//
//    func accessCamera() {
////        print("REACHED ACCESS CAMERA")
//
//        if UIImagePickerController.isSourceTypeAvailable(.camera) {
//            presentPicker(.camera)
//        } else {
//            print("Camera not available. iPhone simulators don't simulate the camera.")
//        }
//    }
//
//    private func presentPicker(_ sourceType: UIImagePickerController.SourceType) {
//        let imagePickerController = UIImagePickerController()
//        imagePickerController.sourceType = sourceType
//        imagePickerController.delegate = self
//        imagePickerController.allowsEditing = true
//        imagePickerController.mediaTypes = ["public.image","public.movie"]
//        imagePickerController.videoMaximumDuration = TimeInterval(5) // secs
//        imagePickerController.videoQuality = .typeHigh
//        present(imagePickerController, animated: true, completion: nil)
//    }
//
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey : Any]) {
//        if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String {
//            if mediaType  == "public.image" {
//                scanImage.image = (info[UIImagePickerController.InfoKey.editedImage] as? UIImage ??
//                                       info[UIImagePickerController.InfoKey.originalImage] as? UIImage)//?
////                .resizeImage(targetSize: CGSize(width: 150, height: 181))
//            } else if mediaType == "public.movie" {
//                print("Select image, not movie")
//                // can convert to absoluteString ONLY after picker.dismiss
//            }
//        }
//        picker.dismiss(animated: true, completion: nil)
//    }
//}
