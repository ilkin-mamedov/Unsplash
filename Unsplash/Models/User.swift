import Foundation

struct User: Codable {
    let profile_image: ProfileImage
    let name: String
    let username: String
    let bio: String?
    let location: String?
}

struct ProfileImage: Codable {
    let large: String
}
