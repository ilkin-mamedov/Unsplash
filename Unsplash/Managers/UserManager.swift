import Foundation
import Alamofire

protocol UserManagerDelegate {
    func didUpdateUser(_ userManager: UserManager, _ user: User)
    func didFailWithError(_ error: Error)
}

struct UserManager {
    
    var delegate: UserManagerDelegate?
    
    func fetchUser(with username: String) {
        performRequest(with: "https://api.unsplash.com/users/\(username)?client_id=\(K.ACCESS_KEY)")
    }
    
    func performRequest(with url: String) {
        AF.request(url).response { response in
            if let result = response.response {
                if result.statusCode == 200 {
                    if let safeData = response.data {
                        if let user = parseJSON(safeData) {
                            delegate?.didUpdateUser(self, user)
                        }
                    }
                }
            }
        }
    }
    
    func parseJSON(_ data: Data) -> User? {
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode(User.self, from: data)
        } catch {
            delegate?.didFailWithError(error)
            return nil
        }
    }
}
