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
    
//    API TEST STUFF      =====================================================
//    @State var message = "Some short sample text."
//    private let serverUrl = "http://127.0.0.1:3000"
//    END API TEST STUFF  =====================================================
    
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
                    }
                    Button(action: {
                        self.sourceType = .photoLibrary
                        self.isImagePickerDisplay.toggle()
                    }) {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 25)
                    }
                    NavigationLink(destination: KeywordView()) {
                            Image(systemName: "arrow.right")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 25)
                    }
                }.frame(height: 100)
            }.navigationBarTitle("SmartNote")
                .sheet(isPresented: self.$isImagePickerDisplay) {
                    ImagePickerView(selectedImage: self.$selectedImage, sourceType: self.$sourceType)
                }
            
            
        }
        
        
//        TESTING THE API =====================================================
//        HStack(alignment: VerticalAlignment.top) {
//            Text(verbatim: "TEST API ENDPOINT")
//            TextEditor(text: $message)
//                .padding(EdgeInsets(top: 10, leading: 18, bottom: 0, trailing: 4))
//            Button(action: {
//                let jsonObj = ["text": message]
//                print(jsonObj)
//                guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj) else {
//                    print("contentView: jsonData serialization error")
//                    return
//                }
//                guard let apiUrl = URL(string: serverUrl+"keywords") else {
//                    print("postChatt: Bad URL")
//                    return
//                }
//                var request = URLRequest(url: apiUrl)
//                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type") // request is in JSON
//                request.httpMethod = "POST"
//                request.httpBody = jsonData
//                URLSession.shared.dataTask(with: request) { data, response, error in
//                    guard let _ = data, error == nil else {
//                        print("contentView: NETWORKING ERROR")
//                        return
//                    }
//                    if let httpStatus = response as? HTTPURLResponse {
//                        if httpStatus.statusCode != 200 {
//                            print("contentView: HTTP STATUS: \(httpStatus.statusCode)")
//                            return
//                        } else {
//                            print("Success")
//                        }
//                    }
//                }.resume()
//            }) {
//                Image(systemName: "paperplane")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 100, height: 25)
//            }
//        }
//        END TESTING API =====================================================
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct KeywordView: View {
    @State private var newKeyword = ""
    @State private var keywords = ["shoes", "pen", "cat"]
    @State private var isEditing = false
    
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
    
    // Use this one when completed AR View modification
//    func findPhotos() -> Array<Array<String>> {
//        let photosIdentifier = showPhotosForKeywords(keywords: keywords)
//        let videosIdentifier = showVideosForKeywords(keywords: keywords)
//        return [photosIdentifier, videosIdentifier]
//    }
}


// Delete this function after activate the one above
func findPhotos() -> [String] {
    let temp = KeywordView()
    let photosIdentifier = showPhotosForKeywords(keywords: temp.getKeywords())
    return photosIdentifier
}
