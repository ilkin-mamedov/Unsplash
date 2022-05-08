import UIKit
import Alamofire
import SDWebImage

var documentInteractionController: UIDocumentInteractionController!

class DetailViewController: UIViewController {
    
    @IBOutlet weak var favoriteBarItem: UIBarButtonItem!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var downloadsLabel: UILabel!
    
    public var id = ""
    private var downloadURL = ""
    private var detailManager = DetailManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        userImageView.layer.cornerRadius = 25
        userImageView.clipsToBounds = true
        
        detailManager.delegate = self
        
        detailManager.fetchDetail(with: id)
        
        if detailManager.isFavorited(with: id) {
            favoriteBarItem.image = UIImage(systemName: "heart.fill")
        }
    }
    
    @IBAction func favoritePressed(_ sender: UIBarButtonItem) {
        if detailManager.isFavorited(with: id) {
            let alert = UIAlertController(title: "Are you sure you want to delete from favorites?", message: "", preferredStyle: .alert)
            
            alert.view.tintColor = UIColor(named: "AccentColor")
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in
                alert.dismiss(animated: true)
            }))
            
            alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: {(_: UIAlertAction!) in
                self.detailManager.deleteFromFavorites(with: self.id)
                sender.image = UIImage(systemName: "heart")
            }))
            
            self.present(alert, animated: true, completion: nil)
        } else {
            detailManager.addToFavorites(with: id)
            sender.image = UIImage(systemName: "heart.fill")
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

extension DetailViewController: DetailManagerDelegate {
    func didUpdateDetail(_ detailManager: DetailManager, _ detail: Detail) {
        DispatchQueue.main.async {
            self.photoImageView.sd_setImage(with: URL(string: detail.urls.full))
            self.userImageView.sd_setImage(with: URL(string: detail.user.profile_image.large))
            self.nameLabel.text = detail.user.name
            if let location = detail.user.location {
                self.locationLabel.text = location
            } else {
                self.locationLabel.isHidden = true
            }
            self.createdLabel.text = "Created at \(detailManager.getDate(detail.created_at))"
            self.downloadsLabel.text = "Downloads: \(detail.downloads)"
            self.downloadURL = detail.links.download
        }
    }
    
    func didFailWithError(_ error: Error) {
        print(error)
    }
}
