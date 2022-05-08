import Foundation
import Alamofire
import RealmSwift

struct DetailManager {
    
    var delegate: DetailManagerDelegate?
    let realm = try! Realm()
    
    func fetchDetail(with id: String) {
        performRequest(with: "https://api.unsplash.com/photos/\(id)?client_id=\(K.ACCESS_KEY)")
    }
    
    func performRequest(with url: String) {
        AF.request(url).response { response in
            if let result = response.response {
                if result.statusCode == 200 {
                    if let safeData = response.data {
                        if let detail = parseJSON(safeData) {
                            delegate?.didUpdateDetail(self, detail)
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
    
    func getDate(_ string: String) -> String {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "HH:mm dd MMM, yyyy"

        if let date = dateFormatterGet.date(from: string) {
            return dateFormatterPrint.string(from: date)
        } else {
            return "Error"
        }
    }
    
    func isFavorited(with id: String) -> Bool {
        var isFavorited = false
        for i in realm.objects(Favorite.self) {
            if i.id == id {
                isFavorited = true
            }
        }
        return isFavorited
    }
    
    func addToFavorites(with id: String) {
        let favorite = Favorite()
        favorite.id = id
        
        do {
            try realm.write {
                realm.add(favorite)
            }
        } catch {
            delegate?.didFailWithError(error)
        }
    }
    
    func deleteFromFavorites(with id: String) {
        for i in realm.objects(Favorite.self) {
            if i.id == id {
                do {
                    try self.realm.write {
                        self.realm.delete(i)
                    }
                } catch {
                    delegate?.didFailWithError(error)
                }
            }
        }
    }
}
