import Foundation

struct Photo: Codable {
    let id: String
    let urls: Urls
    let user: User
}

struct Urls: Codable {
    let full: String
}

struct User: Codable {
    let name: String
    let location: String?
    let profile_image: ProfileImage
}

struct ProfileImage: Codable {
    let large: String
}
