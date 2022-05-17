import Foundation

protocol PhotosManagerDelegate {
    func didUpdatePhotos(_ photosManager: PhotosManager, _ photos: [Photo])
    func didFailWithError(_ error: Error)
}
