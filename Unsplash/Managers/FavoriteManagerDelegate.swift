import Foundation

protocol FavoriteManagerDelegate {
    func didUpdateFavorite(_ favoriteManager: FavoriteManager, _ favorite: Detail)
    func didFailWithError(_ error: Error)
}
