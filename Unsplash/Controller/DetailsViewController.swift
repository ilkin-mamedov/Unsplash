import UIKit
import Alamofire
import Contacts
import SDWebImage
import RealmSwift

var documentInteractionController: UIDocumentInteractionController!

class DetailsViewController: UIViewController {
    
    @IBOutlet weak var favoriteBarItem: UIBarButtonItem!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var downloadsLabel: UILabel!
    
    public var id: String = ""
    private var downloadURL = ""
    private var isFavorite = false
    private let realm = try! Realm()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        userImageView.layer.cornerRadius = 25
        userImageView.clipsToBounds = true
        
        AF.request("https://api.unsplash.com/photos/\(id)?client_id=\(K.ACCESS_KEY)").response { response in
            if let result = response.response {
                if result.statusCode == 200 {
                    if let safeData = response.data {
                        self.parseJSON(safeData)
                    }
                }
            }
        }
        
        for i in realm.objects(Favorite.self) {
            if i.id == id {
                favoriteBarItem.image = UIImage(systemName: "heart.fill")
                isFavorite = true
            }
        }
    }
    
    private func parseJSON(_ data: Data) {
        let decoder = JSONDecoder()
        
        do {
            let detail = try decoder.decode(Detail.self, from: data)
            
            photoImageView.sd_setImage(with: URL(string: detail.urls.full))
            userImageView.sd_setImage(with: URL(string: detail.user.profile_image.large))
            nameLabel.text = detail.user.name
            if let location = detail.user.location {
                locationLabel.text = location
            } else {
                locationLabel.isHidden = true
            }
            createdLabel.text = "Created: \(getDate(detail.created_at))"
            downloadsLabel.text = "Downloads: \(detail.downloads)"
            downloadURL = detail.links.download
        } catch {
            print(error)
        }
    }
    
    private func getDate(_ string: String) -> String {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "dd MMM, yyyy"

        if let date = dateFormatterGet.date(from: string) {
            return dateFormatterPrint.string(from: date)
        } else {
            return "Error"
        }
    }
    
    @IBAction func favoritePressed(_ sender: UIBarButtonItem) {
        if isFavorite {
            for i in realm.objects(Favorite.self) {
                if i.id == id {
                    let alert = UIAlertController(title: "Are you sure you want to delete from favorites?", message: "", preferredStyle: .alert)
                    
                    alert.view.tintColor = UIColor(named: "AccentColor")
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in
                        alert.dismiss(animated: true)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: {(_: UIAlertAction!) in
                        do {
                            try self.realm.write {
                                self.realm.delete(i)
                            }
                            sender.image = UIImage(systemName: "heart")
                            self.isFavorite = false
                        } catch {
                            print(error)
                        }
                    }))
                    
                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            let favorite = Favorite()
            favorite.id = id
            
            do {
                try realm.write {
                    realm.add(favorite)
                }
                sender.image = UIImage(systemName: "heart.fill")
                isFavorite = true
            } catch {
                print(error)
            }
        }
    }
    
    @IBAction func closePressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func downloadPressed(_ sender: UIButton) {
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("\(self.id).png")
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        AF.download(downloadURL, to: destination).response { response in
            if response.error == nil, let imagePath = response.fileURL?.path {
                documentInteractionController = UIDocumentInteractionController()
                documentInteractionController.url = URL(fileURLWithPath: imagePath)
                documentInteractionController.presentOptionsMenu(from: sender.bounds, in: sender, animated: true)
            }
        }
    }
}
