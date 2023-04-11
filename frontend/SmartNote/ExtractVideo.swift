import Photos

func fetchVideoIdentifier(withKeywords keywords: [String]) -> String {
    let options = PHFetchOptions()
    options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)

    let allVideos = PHAsset.fetchAssets(with: options)

    var matchingVideoIdentifier: String? = nil

    allVideos.enumerateObjects { (asset, _, stop) in
        for keyword in keywords {
            if asset.localIdentifier.lowercased().contains(keyword.lowercased()) {
                matchingVideoIdentifier = asset.localIdentifier
                stop.pointee = true
                break
            }
        }
    }

    print("We found one video")
    if let matchingVideoIdentifier = matchingVideoIdentifier {
        print("Matching video identifier: \(matchingVideoIdentifier)")
        return matchingVideoIdentifier
    } else {
        print("No matching video found")
        return ""
    }
}
