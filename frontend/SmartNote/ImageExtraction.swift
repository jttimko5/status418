//
//  ImageExtraction.swift
//  SmartNote
//
//  Created by Pengzhou Chen on 2023/3/18.
//

import SwiftUI
import Photos
import Vision

func showPhotosForKeywords(keywords: [String]) -> [String] {
    var photoURLs: [String] = []
    
    // Create a request for classifying the contents of an image
    let classifyRequest = VNClassifyImageRequest()
    
    // Create a fetch options object to specify search criteria for the photos
    let fetchOptions = PHFetchOptions()
    fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
    
    // Fetch the photos that match the specified search criteria
    let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
    
    // Create a dispatch group to wait for all requests to complete
    let dispatchGroup = DispatchGroup()
    
    // Enumerate the fetched photos and classify their contents
    fetchResult.enumerateObjects { asset, index, pointer in
        dispatchGroup.enter()
        // Request an image representation of the photo
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.normalizedCropRect = CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1) // Center crop
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 512, height: 512),
                                              contentMode: .aspectFit, options: options) { image, _ in
            if let image = image, let cgImage = image.cgImage {
                // Perform the classification request on the image
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([classifyRequest])
                    if let classifications = classifyRequest.results, !classifications.isEmpty {
                        // Check if the photo contains any of the specified keywords
                        let matchedKeywords = classifications.filter { keywords.contains($0.identifier.lowercased()) }
                        if !matchedKeywords.isEmpty {
                            // Add the URL of the matching photo to the result array
                            if let assetURL = asset.value(forKey: "uniformTypeIdentifier") as? String {
                                photoURLs.append(assetURL)
                            }
                        }
                    }
                } catch {
                    print("Error classifying image: \(error.localizedDescription)")
                }
            }
            dispatchGroup.leave()
        }
    }
    
    // Wait for all requests to complete
    dispatchGroup.wait()
    
    return photoURLs
}

