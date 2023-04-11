//
//  ImageExtraction.swift
//  SmartNote
//
//  Created by Pengzhou Chen on 2023/3/18.
//
import SwiftUI
import Photos
import Vision

func photoAnalyzePerformer(fetchOptions: PHFetchOptions, keywords: [String],
                           currentMatch: Int, currentSearch: Int) -> (Int, Int, [String]) {
    var matchedCount = currentMatch
    var totalSearch = currentSearch
    var photoURLs: [String] = []
    // Create a request for classifying the contents of an image
    let classifyRequest = VNClassifyImageRequest()
    
    // Create a dispatch group to wait for all requests to complete
    let dispatchGroup = DispatchGroup()

    let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    // Enumerate the fetched photos and classify their contents
    fetchResult.enumerateObjects { asset, index, pointer in
        if matchedCount >= keywords.count || totalSearch >= 500 {
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
                    totalSearch += 1
                    if let classifications = classifyRequest.results, !classifications.isEmpty {
                        // Check if the photo contains any of the specified keywords
                        let matchedKeywords = classifications.filter {
                            keywords.contains($0.identifier.lowercased())  && $0.confidence >= 0.9
                        }
                        if !matchedKeywords.isEmpty {
                            // Add the local identifier of the matching photo to the result array
                            let localIdentifier = asset.localIdentifier
                            photoURLs.append(localIdentifier)
                            matchedCount += 1
                            if matchedCount >= keywords.count {
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

    // Wait for all requests to complete or until the semaphore is released
    dispatchGroup.wait()
    
    return (matchedCount, totalSearch, photoURLs)
}


func returnImagesForDate(fetchOptions: PHFetchOptions) -> (Int, [String]) {
    let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    var photoURLs: [String] = []
    var count = 0
    
    if fetchResult.count > 5 {
        // Generate 5 random indexes
        var randomIndexes: Set<Int> = []
        while randomIndexes.count < 5 {
            let randomIndex = Int.random(in: 0..<fetchResult.count)
            randomIndexes.insert(randomIndex)
        }
        
        // Loop through the fetch result and retrieve the images
        fetchResult.enumerateObjects { (asset, index, stop) in
            if randomIndexes.contains(index) {
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = true
                requestOptions.deliveryMode = .highQualityFormat
                requestOptions.resizeMode = .exact
                
                photoURLs.append(asset.localIdentifier)
                count += 1
            }
            if count >= 5 {
                stop.pointee = true
            }
        }
    } else {
        // Loop through the fetch result and retrieve the images
        fetchResult.enumerateObjects { (asset, index, stop) in
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.resizeMode = .exact
            
            photoURLs.append(asset.localIdentifier)
            count += 1
        }
    }

    return (count, photoURLs)
}

func showPhotosForKeywords(keywords: [String], time: [String]) -> [String] {
    var photoURLs: [String] = []
    var matchedCount = 0
    var totalSearch = 0
    var totalReturn = 0
    
    var dates: [Date] = []
    for date in time {
        let comp = date.components(separatedBy: "/")
        if let month = Int(comp[0]), let day = Int(comp[1]), let year = Int(comp[2]) {
            dates.append(Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!)
        }
    }
    
    for date in dates {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@", start as NSDate, end as NSDate)
        let maxReturn = dates.count * 5
        
        if keywords.isEmpty {
            let analyzeResults = returnImagesForDate(fetchOptions: fetchOptions)
            totalReturn += analyzeResults.0
            photoURLs += analyzeResults.1
            if totalReturn >= maxReturn {
                return photoURLs
            }
        } else {
            let analyzeResults = photoAnalyzePerformer(fetchOptions: fetchOptions, keywords: keywords,
                                                       currentMatch: matchedCount, currentSearch: totalSearch)
            matchedCount = analyzeResults.0
            totalSearch = analyzeResults.1
            photoURLs += analyzeResults.2
            if matchedCount >= keywords.count || totalSearch >= 500 {
                return photoURLs
            }
        }
    }
    
    // Create a fetch options object to specify search criteria for the photos
    let fetchOptions = PHFetchOptions()
    
    if !dates.isEmpty {
        if keywords.isEmpty {
            return photoURLs
        }
        
        var oldestDate = Date()
        var newestDate = Date()
        let calendar = Calendar.current
        if dates.count > 1 {
            oldestDate = dates.min()!
            newestDate = dates.max()!
            
            let datePoint = calendar.startOfDay(for: Date())
            let dateRange = calendar.date(byAdding: .day, value: -5, to: datePoint)!
            if newestDate >= dateRange {
                newestDate = Date()
            } else {
                newestDate = calendar.date(byAdding: .day, value: 5, to: newestDate)!
            }
            
            oldestDate = calendar.date(byAdding: .day, value: -5, to: oldestDate)!
        } else {
            oldestDate = calendar.date(byAdding: .day, value: -5, to: dates[0])!
        }

        var predicates: [NSPredicate] = []
        for date in dates {
            let exclusionStartDate = calendar.startOfDay(for: date)
            let exclusionEndDate = calendar.date(byAdding: .day, value: 1, to: exclusionStartDate)!
            let predicate = NSPredicate(format: "creationDate < %@ OR creationDate >= %@",
                                        exclusionStartDate as NSDate, exclusionEndDate as NSDate)
            predicates.append(predicate)
        }
        predicates.append(NSPredicate(format: "creationDate >= %@ AND creationDate <= %@",
                                      oldestDate as NSDate, newestDate as NSDate))
        fetchOptions.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        
    } else {
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 500
    }
    
    let analyzeResults = photoAnalyzePerformer(fetchOptions: fetchOptions, keywords: keywords,
                                               currentMatch: matchedCount, currentSearch: totalSearch)

    photoURLs += analyzeResults.2

    // If no matches were found, print a message indicating that there are no related photos
    if photoURLs.isEmpty {
        print("No photo related to the specified keywords.")
    }

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
