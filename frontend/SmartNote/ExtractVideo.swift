import Photos

func fetchVideoIdentifier(dates: [String]) -> String {
    var matchingVideoIdentifier: String? = nil
    
    var videoDate = Date()
    let comp = dates[0].components(separatedBy: "/")
    if let month = Int(comp[0]), let day = Int(comp[1]), let year = Int(comp[2]) {
        videoDate = Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }
    
    let start = Calendar.current.startOfDay(for: videoDate)
    let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
    let fetchOptions = PHFetchOptions()
    fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@ AND mediaType == %d",
                                         start as NSDate, end as NSDate, PHAssetMediaType.video.rawValue)
    
    let allVideos = PHAsset.fetchAssets(with: fetchOptions)

    allVideos.enumerateObjects { (asset, _, stop) in
        matchingVideoIdentifier = asset.localIdentifier
        stop.pointee = true
    }

    if let matchingVideoIdentifier = matchingVideoIdentifier {
        print("We found one video")
        print("Matching video identifier: \(matchingVideoIdentifier)")
        return matchingVideoIdentifier
    } else {
        print("No matching video found")
        return ""
    }
}
