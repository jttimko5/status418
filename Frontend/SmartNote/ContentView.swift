//
//  ContentView.swift
//  SmartNote
//
//  Created by Tim Stauder on 3/14/23.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @State private var isImagePickerDisplay = false
    
//    API TEST STUFF
    @State var message = "Some short sample text."
    private let serverUrl = "https://18.206.89.117/"
//    END API TEST STUFF
    
    var body: some View {
        NavigationView {
            VStack {
                if selectedImage != nil {
                    Image(uiImage: selectedImage!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }.navigationBarTitle("SmartNote")
                .sheet(isPresented: self.$isImagePickerDisplay) {
                    ImagePickerView(selectedImage: self.$selectedImage, sourceType: self.$sourceType)
                }
        }
        
        
//        TESTING THE API
        HStack(alignment: VerticalAlignment.top) {
            Text(verbatim: "TEST API ENDPOINT")
            TextEditor(text: $message)
                .padding(EdgeInsets(top: 10, leading: 18, bottom: 0, trailing: 4))
            Button(action: {
                let jsonObj = ["text": message]
                guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj) else {
                    print("contentView: jsonData serialization error")
                    return
                }
                guard let apiUrl = URL(string: serverUrl+"keywords/") else {
                    print("postChatt: Bad URL")
                    return
                }
                var request = URLRequest(url: apiUrl)
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type") // request is in JSON
                request.httpMethod = "POST"
                request.httpBody = jsonData
                URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let _ = data, error == nil else {
                        print("contentView: NETWORKING ERROR")
                        return
                    }
                    if let httpStatus = response as? HTTPURLResponse {
                        if httpStatus.statusCode != 200 {
                            print("contentView: HTTP STATUS: \(httpStatus.statusCode)")
                            return
                        }
                    }
                }.resume()
                
            }) {
                Image(systemName: "paperplane")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 25)
            }
        }
//        END TESTING API
        
        
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
        }.frame(height: 100)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
