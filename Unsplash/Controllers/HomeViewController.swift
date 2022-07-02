import UIKit
import Alamofire
import SDWebImage
import SPAlert

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var id = ""
    private let refreshControl = UIRefreshControl()
    private var photosManager = PhotosManager()
    private var photos: [Photo] = []
    
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Home"
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        searchController.searchBar.tintColor = .label
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        photosManager.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 250
        
        tableView.register(UINib(nibName: "PhotoCell", bundle: nil), forCellReuseIdentifier: "photoCell")
        
        refreshControl.attributedTitle = NSAttributedString()
        refreshControl.addTarget(self, action: #selector(self.loadPhotos), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        loadPhotos()
    }
    
    @objc func loadPhotos() {
        if NetworkReachabilityManager()!.isReachable {
            photosManager.fetchPhotos()
            tableView.reloadData()
        } else {
            SPAlert.present(title: "You are offline!", message: "Please, check your internet connection and try again.", preset: .error)
        }
        refreshControl.endRefreshing()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails" {
            let navigationContoller = segue.destination as! UINavigationController
            let detailViewController = navigationContoller.topViewController as! DetailViewController

            detailViewController.id = id
        }
    }
}

extension HomeViewController: PhotosManagerDelegate {
    func didUpdatePhotos(_ photosManager: PhotosManager, _ photos: [Photo]) {
        self.photos = photos
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func didFailWithError(_ error: Error) {
        print(error)
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "photoCell", for: indexPath) as! PhotoCell
        let photo = photos[indexPath.row]
        
        cell.photoImageView.sd_setImage(with: URL(string: photo.urls.full))
        cell.userImageView.sd_setImage(with: URL(string: photo.user.profile_image.large))
        cell.nameLabel.text = photo.user.name
        
        cell.photoImageView.layer.sublayers?.removeAll()
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width - 20, height: 250)
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.6, 1.0]
        cell.photoImageView.layer.insertSublayer(gradient, at: 0)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if NetworkReachabilityManager()!.isReachable {
            id = photos[indexPath.row].id
            performSegue(withIdentifier: "showDetails", sender: self)
        } else {
            SPAlert.present(title: "You are offline!", message: "Please, check your internet connection and try again.", preset: .error)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension HomeViewController: UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        
        if NetworkReachabilityManager()!.isReachable {
            photosManager.fetchPhotos(search: text)
            tableView.reloadData()
        } else {
            SPAlert.present(title: "You are offline!", message: "Please, check your internet connection and try again.", preset: .error)
        }
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        photosManager.fetchPhotos()
        tableView.reloadData()
    }
}
