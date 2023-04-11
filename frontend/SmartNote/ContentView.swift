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

struct ContentView: View {
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @State private var isImagePickerDisplay = false
    @State private var isLinkActive = false
    @State private var recognizedText: String = ""
    @State private var parsedText: [String: [String]] = [:]
    @State private var isParsingText = false


    var body: some View {
        NavigationView {
            
            VStack {
                Text("Take a picture of your journal to see related media")
                        .font(.title2)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                
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
                    }) {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 25)
                            .foregroundColor(Color.blue)
                    }
                    ZStack {
                        if self.isParsingText {
                            ProgressView()
                        } else {
                            NavigationLink(destination: KeywordView(parsedText: parsedText), isActive: $isLinkActive) {
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
            
            let url = URL(string: "https://3.15.29.245/keywords")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")


            
            let jsonObj = ["text": self.recognizedText]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj) else {
                print("postExtractKeywords: jsonData serialization error")
                return
            }
            request.httpBody = jsonData

            self.isParsingText = true
            let session = URLSession.shared
            session.dataTask(with: request) { (data, response, error) in
                if let response = response {
                    print(response)
                }

                if let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [String]]
                        self.parsedText = json ?? [:]
                    } catch {
                        print(error)
                    }
                }
                self.isParsingText = false
            }.resume()
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
    @State private var dates: [String] = ["12/31/2022", "12/21/2022"]
    @State private var keywords: [String] = ["people"]
    @State private var isEditing = false
    @State public var parsedText: [String: [String]]
    @State private var dateText = ""
    
    var body: some View {
        VStack {
            Text("Here is the infomration parsed from your journal entry, please edit or add        information that was missed.")
                .font(.title2)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
            TextField("Journal Date :", text: $dateText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 250)
                .onAppear {
                    if let date = parsedText["dates"]?.first {
                        let year = String(date.dropLast(6))
                        let day = String(date.dropFirst(8))
                        let month = String(String(date.dropFirst(5)).dropLast(3))
                        let result = month + "/" + day + "/" + year
                        parsedText["dates"] = [result]
                        dateText = result
                    }
                }
                .onChange(of: dateText) { newDateText in
                    parsedText["dates"] = [newDateText]
                }

            List {
                ForEach(parsedText["keywords"]!.indices, id: \.self) { index in
                    let keyword = parsedText["keywords"]![index]
                    if isEditing {
                        TextField("Enter keyword", text: Binding(
                            get: { keyword },
                            set: { parsedText["keywords"]![index] = $0 }
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
        .navigationTitle("Keywords and Date")
    }
    
    func addKeyword() {
        guard !newKeyword.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        withAnimation {
            parsedText["keywords"]?.append(newKeyword)
        }
        
        newKeyword = ""
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
    }
    
    func delete(at offsets: IndexSet) {
        withAnimation {
            parsedText["keywords"]?.remove(atOffsets: offsets)
        }
    }
    
    func getKeywords() -> Array<String> {
        // TODO: we want to return parsedText["keywords"] instead of the preset list of keywords
        // not sure if this works but if i just do return parsedText["keywords"] ?? [] it crashes
        keywords = parsedText["keywords"] ?? []
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


// Delete this function after activate the one above
func findPhotos() -> [String] {
    let temp = KeywordView(parsedText: [:])
    let photosIdentifier = showPhotosForKeywords(keywords: temp.getKeywords(), time: temp.getDates() ?? [])
    return photosIdentifier
}

func findVideos() -> [String] {
    
    return []
}
