import Foundation

struct Detail: Codable {
    let id: String
    let created_at: String
    let urls: Urls
    let links: Links
    let user: User
    let downloads: Int
}

struct Links: Codable {
    let download: String
}
