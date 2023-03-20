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
    var matchedCount = 0
    
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
        if matchedCount >= 5 {
            return
        }
        dispatchGroup.enter()
        // Request the image data and orientation of the photo
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.normalizedCropRect = CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1) // Center crop
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
            if let data = data {
                // Perform the classification request on the image data
                let handler = VNImageRequestHandler(data: data, options: [:])
                do {
                    try handler.perform([classifyRequest])
                    if let classifications = classifyRequest.results, !classifications.isEmpty {
                        // Check if the photo contains any of the specified keywords
                        let matchedKeywords = classifications.filter {
                            keywords.contains($0.identifier.lowercased()) && $0.confidence >= 0.9
                        }
                        print(matchedKeywords)
                        if !matchedKeywords.isEmpty {
                            // Add the local identifier of the matching photo to the result array
                            let localIdentifier = asset.localIdentifier
                            photoURLs.append(localIdentifier)
                            matchedCount += 1
                            if matchedCount >= 5 {
                                dispatchGroup.leave()
                                return
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


// Video part still under working
//func showVideosForKeywords(keywords: [String]) -> [String] {
//    var videoURLs: [String] = []
//    var matchedCount = 0
//
//    // Create a fetch options object to specify search criteria for the videos
//    let fetchOptions = PHFetchOptions()
//    fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
//
//    // Fetch the videos that match the specified search criteria
//    let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
//
//    // Create a dispatch group to wait for all requests to complete
//    let dispatchGroup = DispatchGroup()
//
//    // Enumerate the fetched videos and check their metadata for keywords
//    fetchResult.enumerateObjects { asset, index, pointer in
//        if matchedCount >= 2 {
//            return
//        }
//        dispatchGroup.enter()
//        // Request the AV asset for the video
//        let options = PHVideoRequestOptions()
//        options.isNetworkAccessAllowed = true
//        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
//            if let avAsset = avAsset {
//                // Check if the video contains any of the specified keywords in its metadata
//                let metadataList = avAsset.metadata.filter { $0.commonKey?.rawValue == AVMetadataIdentifier.quickTimeUserDataKeywords.rawValue }
//                let keywordStrings = metadataList.compactMap { $0.value?.description }
//                let matchedKeywords = keywordStrings.filter { keywords.contains($0.lowercased()) }
//                if !matchedKeywords.isEmpty {
//                    // Add the local identifier of the matching video to the result array
//                    let localIdentifier = asset.localIdentifier
//                    videoURLs.append(localIdentifier)
//                    matchedCount += 1
//                    if matchedCount >= 2 {
//                        dispatchGroup.leave()
//                        return
//                    }
//                }
//            }
//            dispatchGroup.leave()
//        }
//    }
//
//    // Wait for all requests to complete
//    dispatchGroup.wait()
//
//    return videoURLs
//}
