import Foundation
import Alamofire

struct PhotosManager {
    
    var delegate: PhotosManagerDelegate?
    
    func fetchPhotos() {
        for index in 1...10 {
            performRequest(with: "https://api.unsplash.com/photos?per_page=30&page\(index)&client_id=\(K.ACCESS_KEY)")
        }
    }
    
    func fetchPhotos(search: String) {
        for index in 1...10 {
            performRequest(with: "https://api.unsplash.com/search/photos?per_page=30&page\(index)&query=\(search.replacingOccurrences(of: " ", with: "+"))&client_id=\(K.ACCESS_KEY)")
        }
    }
    
    func performRequest(with url: String) {
        AF.request(url).response { response in
            if let result = response.response {
                if result.statusCode == 200 {
                    if let safeData = response.data {
                        if let photos = parseJSON(safeData, url.contains("search")) {
                            delegate?.didUpdatePhotos(self, photos)
                        }
                    }
                }
            } else {
                delegate?.didFailWithError(response.error!)
            }
        }
    }
    
    func parseJSON(_ data: Data, _ isSearch: Bool) -> [Photo]? {
        let decoder = JSONDecoder()
        
        do {
            if isSearch {
                return try decoder.decode(Search.self, from: data).results
            } else {
                return try decoder.decode([Photo].self, from: data)
            }
        } catch {
            delegate?.didFailWithError(error)
            return nil
        }
    }
}
