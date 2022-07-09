import Foundation
import Alamofire

protocol PhotosManagerDelegate {
    func didUpdatePhotos(_ photosManager: PhotosManager, _ photos: [Photo])
    func didFailWithError(_ error: Error)
}

struct PhotosManager {
    
    var delegate: PhotosManagerDelegate?
    
    func fetchPhotos(page: Int) {
        performRequest(with: "https://api.unsplash.com/photos?per_page=30&page=\(page)&client_id=\(K.ACCESS_KEY)")
    }
    
    func fetchPhotos(search: String, page: Int) {
        performRequest(with: "https://api.unsplash.com/search/photos?per_page=30&page=\(page)&query=\(search.replacingOccurrences(of: " ", with: "+"))&client_id=\(K.ACCESS_KEY)")
    }
    
    func fetchPhotos(with username: String, page: Int) {
        performRequest(with: "https://api.unsplash.com/users/\(username)/photos?per_page=30&page=\(page)&client_id=\(K.ACCESS_KEY)")
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
