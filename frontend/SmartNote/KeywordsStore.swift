//
//  KeywordsStore.swift
//  SmartNote
//
//  Created by Thomas Day on 3/19/23.
//

import Foundation

final class KeywordsStore: ObservableObject {
    static let shared = KeywordsStore() // create one instance of the class to be shared
    private init() {}                // and make the constructor private so no other
                                     // instances can be created; aka a singleton
    private(set) var keywords = Keywords(dates: [], keywords: [])
//    private let nFields = Mirror(reflecting: Keywords()).children.count
    
    private let serverUrl = "https://3.15.29.245/"
    
    func postExtractKeywords(_ text: String, completion: ((Bool) -> ())?) {
        let jsonObj = ["text": text]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonObj) else {
            print("postExtractKeywords: jsonData serialization error")
            return
        }
        
        guard let apiUrl = URL(string: serverUrl+"keywords") else {
            print("postExtractKeywords: Bad URL")
            return
        }
        
        var request = URLRequest(url: apiUrl)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            var success = false
            defer { completion?(success) }
            
            guard let data = data, error == nil else {
                print("postExtractKeywords: NETWORKING ERROR")
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("postExtractKeywords: HTTP STATUS: \(httpStatus.statusCode)")
                return
            }
            
            // get data from response
            guard let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String:Any] else {
                print("postExtractKeywords: failed JSON deserialization")
                return
            }
            let keywordsReceived = jsonObj["keywords"] as? [String] ?? []
            let datesReceived = jsonObj["dates"] as? [Date] ?? []
            self.keywords = Keywords(dates: [], keywords: [])
            self.keywords.keywords = keywordsReceived
            self.keywords.dates = datesReceived
            
            success = true // for completion(success)
        }.resume()
    }
}
