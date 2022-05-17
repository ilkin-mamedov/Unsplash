import Foundation
import Alamofire

struct FavoriteManager {
    
    var delegate: FavoriteManagerDelegate?
    
    func fetchFavorite(with id: String) {
        performRequest(with: "https://api.unsplash.com/photos/\(id)?client_id=\(K.ACCESS_KEY)")
    }
    
    func performRequest(with url: String) {
        AF.request(url).response { response in
            if let result = response.response {
                if result.statusCode == 200 {
                    if let safeData = response.data {
                        if let favorite = parseJSON(safeData) {
                            delegate?.didUpdateFavorite(self, favorite)
                        }
                    }
                }
            }
        }
    }
    
    func parseJSON(_ data: Data) -> Detail? {
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode(Detail.self, from: data)
        } catch {
            delegate?.didFailWithError(error)
            return nil
        }
    }
    
}
