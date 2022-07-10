import UIKit
import Alamofire
import SDWebImage
import SPAlert

var documentInteractionController: UIDocumentInteractionController!

class DetailViewController: UIViewController {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var topIndicator: UIView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var downloadsLabel: UILabel!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var favoriteButton: UIButton!
    
    public var id = ""
    private var username = ""
    private var downloadURL = ""
    private var detailManager = DetailManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        detailManager.delegate = self
        detailManager.fetchDetail(with: id)
        
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.6, 1.0]
        photoImageView.layer.insertSublayer(gradient, at: 0)
        
        topIndicator.layer.cornerRadius = 2
        
        userImageView.layer.cornerRadius = 25
        userImageView.clipsToBounds = true
        userImageView.isUserInteractionEnabled = true
        userImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showUser)))
        
        downloadButton.layer.cornerRadius = 5
        downloadButton.layer.borderWidth = 1.0
        downloadButton.layer.borderColor = UIColor.white.cgColor
        indicatorView.isHidden = true
        favoriteButton.layer.cornerRadius = 5
        favoriteButton.layer.borderWidth = 1.0
        favoriteButton.layer.borderColor = UIColor.white.cgColor
        
        if detailManager.isFavorited(with: id) {
            favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            favoriteButton.tintColor = UIColor.systemRed
            favoriteButton.backgroundColor = UIColor.white
        } else {
            favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
            favoriteButton.tintColor = UIColor.white
            favoriteButton.backgroundColor = UIColor.clear
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showUser" {
            let userViewController = segue.destination as! UserViewController

            userViewController.username = username
        }
    }
    
    @objc func showUser() {
        if NetworkReachabilityManager()!.isReachable {
            performSegue(withIdentifier: "showUser", sender: self)
        } else {
            SPAlert.present(title: "You are offline!", message: "Please, check your internet connection and try again.", preset: .error)
        }
    }
    
    @IBAction func downloadPressed(_ sender: UIButton) {
        if NetworkReachabilityManager()!.isReachable {
            sender.setTitle("", for: .normal)
            indicatorView.isHidden = false
            indicatorView.startAnimating()
            let destination: DownloadRequest.Destination = { _, _ in
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsURL.appendingPathComponent("\(self.id).png")
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }

            AF.download(downloadURL, to: destination).response { response in
                if response.error == nil, let imagePath = response.fileURL?.path {
                    sender.setTitle("Download", for: .normal)
                    self.indicatorView.isHidden = true
                    self.indicatorView.stopAnimating()
                    documentInteractionController = UIDocumentInteractionController()
                    documentInteractionController.url = URL(fileURLWithPath: imagePath)
                    documentInteractionController.presentOptionsMenu(from: sender.bounds, in: sender, animated: true)
                }
            }
        } else {
            SPAlert.present(title: "You are offline!", message: "Please, check your internet connection and try again.", preset: .error)
        }
    }
    
    @IBAction func favoritePressed(_ sender: UIButton) {
        favoritePressed()
    }
    
    @objc func favoritePressed() {
        if detailManager.isFavorited(with: id) {
            let alert = UIAlertController(title: "Are you sure you want to delete from favorites?", message: "", preferredStyle: .alert)
            
            alert.view.tintColor = UIColor(named: "AccentColor")
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { _ in
                alert.dismiss(animated: true)
            }))
            
            alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: {(_: UIAlertAction!) in
                self.detailManager.deleteFromFavorites(with: self.id)
                self.favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
                self.favoriteButton.tintColor = UIColor.white
                self.favoriteButton.backgroundColor = UIColor.clear
            }))
            
            self.present(alert, animated: true, completion: nil)
        } else {
            favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            favoriteButton.tintColor = UIColor.systemRed
            favoriteButton.backgroundColor = UIColor.white
            detailManager.addToFavorites(with: id)
            SPAlert.present(title: "Added to Favorites", preset: .heart)
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
            self.username = detail.user.username
        }
    }
    
    func didFailWithError(_ error: Error) {
        print(error)
    }
}
