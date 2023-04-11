//
//  ContentView.swift
//  SmartNote
//
//  Created by Tim Stauder on 3/14/23.
//

import SwiftUI
import UIKit
import Photos
import Vision
import EventKit

struct ContentView: View {
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @State private var isImagePickerDisplay = false
    @State private var isLinkActive = false
    @State private var recognizedText: String = ""

    var body: some View {
        NavigationView {
            
            VStack {
                if selectedImage != nil {
                    Image(uiImage: selectedImage!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                Spacer()
                HStack (alignment: .bottom){
                    Button(action: {
                        self.sourceType = .camera
                        self.isImagePickerDisplay.toggle()
                    }) {
                        Image(systemName: "camera")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 25)
                            .foregroundColor(Color.blue)
                    }
                    Button(action: {
                        self.sourceType = .photoLibrary
                        self.isImagePickerDisplay.toggle()
//                        TODO: remove these prints
//                        print("============ Calendar event titles =============")
//                        print(findEvents())
                        print("============ Steps info =============")
                        print(findSteps())
                    }) {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 25)
                            .foregroundColor(Color.blue)
                    }
                    ZStack {
                        NavigationLink(destination: KeywordView(recognizedText: recognizedText), isActive: $isLinkActive) {
                            EmptyView()
                        }
                        Image(systemName: "arrow.right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 25)
                            .foregroundColor(Color.blue)
                            .opacity(selectedImage == nil ? 0.2 : 1.0) // make the arrow image transparent when no image is selected
                            .onTapGesture {
                                if selectedImage != nil {
                                    if let image = selectedImage {
                                        recognizeTextFromImage(image)
                                    }
                                    self.isLinkActive = true
                                }
                            }
                    }
                }.frame(height: 100)
            }.navigationBarTitle("SmartNote")
                .sheet(isPresented: self.$isImagePickerDisplay) {
                    ImagePickerView(selectedImage: self.$selectedImage, sourceType: self.$sourceType)
                }
        }
    }
    
    private func recognizeTextFromImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
//        guard let cgImage = imageWithText.image?.cgImage else {return}
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                return
            }
            let recognizedStrings = observations.compactMap { observation in
                return observation.topCandidates(1).first?.string
            }
            self.recognizedText = recognizedStrings.joined(separator: "\n")
        }
        request.recognitionLevel = .accurate
        do {
            try requestHandler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct KeywordView: View {
    @State private var newKeyword = ""
    @State private var dates: [String] = ["02-14-2022", "09-26-2022"]
    @State private var keywords: [String] = []
    @State private var isEditing = false
    var recognizedText: String
    
    var body: some View {
        VStack {
            List {
                ForEach(keywords.indices, id: \.self) { index in
                    let keyword = keywords[index]
                    if isEditing {
                        TextField("Enter keyword", text: Binding(
                            get: { keyword },
                            set: { keywords[index] = $0 }
                        ))
                    } else {
                        Button(action: {
                            withAnimation {
                                isEditing = true
                            }
                        }) {
                            Text(keyword)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            
            
            Text("Recognized text: \(recognizedText)")
            
            HStack {
                if isEditing {
                    Button(action: {
                        withAnimation {
                            isEditing = false
                        }
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
                    }) {
                        Text("Done")
                    }
                } else {
                    Button(action: {
                        withAnimation {
                            isEditing = true
                        }
                    }) {
                        Text("Edit")
                    }
                }
                
                TextField("New keyword", text: $newKeyword, onCommit: addKeyword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: addKeyword) {
                    Image(systemName: "plus")
                }
            }
            
            NavigationLink(destination: SmartNoteARView(IdentifierInput: findPhotos())) {
                Text("Search Related Photos")
                Image(systemName: "chevron.right")
            }
        }
        .navigationTitle("Keywords")
    }
    
    func addKeyword() {
        guard !newKeyword.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        withAnimation {
            keywords.append(newKeyword)
        }
        
        newKeyword = ""
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
    }
    
    func delete(at offsets: IndexSet) {
        withAnimation {
            keywords.remove(atOffsets: offsets)
        }
    }
    
    func getKeywords() -> Array<String> {
        return keywords
    }
    
    func getDates() -> Array<String>? {
        return dates
    }
    
    // Use this one when completed AR View modification
//    func findPhotos() -> Array<Array<String>> {
//        let photosIdentifier = showPhotosForKeywords(keywords: keywords)
//        let videosIdentifier = showVideosForKeywords(keywords: keywords)
//        return [photosIdentifier, videosIdentifier]
//    }
}


func getConvertedDates() -> [Date?] {
    let temp = KeywordView(recognizedText: "")
    let dates = temp.getDates()
    
    var list: [Date?] = []
    
    for date in dates ?? [] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyy"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        let date_object: Date? = dateFormatter.date(from: date)
        list.append(date_object)
    }
    return list
}


// Delete this function after activate the one above
func findPhotos() -> [String] {
    let temp = KeywordView(recognizedText: "")
    let photosIdentifier = showPhotosForKeywords(keywords: temp.getKeywords())
    return photosIdentifier
}

func findEvents() -> [String]? {
    let temp = KeywordView(recognizedText: "")
    let dates = temp.getDates()
    if (dates != nil) {
        return pullEvents(dates: dates)
    }
    return nil
}

func findSteps() -> Void {
    let dates = getConvertedDates()
    let hkmodel = HealthKitViewModel()
    if (dates[0] != nil) {
        hkmodel.healthRequest(date: dates[0] ?? Date())
    }
//    retrieveStepCount(date_in: dates![0]) { (steps, error) in
//                print(error?.localizedDescription)
//
//                if error == nil {
//
//                    print("Health kit Walked steps  \(steps ?? 0)")
//                }
//    }
}
