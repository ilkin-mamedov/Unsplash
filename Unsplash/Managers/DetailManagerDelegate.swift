import Foundation

protocol DetailManagerDelegate {
    func didUpdateDetail(_ detailManager: DetailManager, _ detail: Detail)
    func didFailWithError(_ error: Error)
}
