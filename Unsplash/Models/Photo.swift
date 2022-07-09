import Foundation

struct Photo: Codable {
    let id: String
    let urls: Urls
    let user: User
}
