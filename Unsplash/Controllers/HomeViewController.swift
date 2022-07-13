import UIKit
import Alamofire
import SDWebImage
import SPAlert

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var id = ""
    private var page = 1
    private let refreshControl = UIRefreshControl()
    private var photosManager = PhotosManager()
    private var photos: [Photo] = []
    
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Home"
        
        searchController.searchBar.tintColor = .label
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        photosManager.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "PhotoTableViewCell", bundle: nil), forCellReuseIdentifier: "PhotoTableViewCell")
        tableView.register(UINib(nibName: "MoreTableViewCell", bundle: nil), forCellReuseIdentifier: "MoreTableViewCell")
        
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
        self.photos.append(contentsOf: photos)
        tableView.reloadData()
    }
    
    func didFailWithError(_ error: Error) {
        print(error)
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if photos.isEmpty {
            return 0
        } else {
            return section == 0 ? photos.count : 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoTableViewCell", for: indexPath) as! PhotoTableViewCell
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
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MoreTableViewCell", for: indexPath) as! MoreTableViewCell
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if NetworkReachabilityManager()!.isReachable {
                id = photos[indexPath.row].id
                performSegue(withIdentifier: "showDetails", sender: self)
            } else {
                SPAlert.present(title: "You are offline!", message: "Please, check your internet connection and try again.", preset: .error)
            }
        } else {            
            if searchController.isActive {
                photosManager.fetchPhotos(search: searchController.searchBar.text!, page: page)
            } else {
                photosManager.fetchPhotos(page: page)
            }
            tableView.reloadData()
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 250
        } else {
            return 44
        }
    }
}

extension HomeViewController: UISearchControllerDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        
        photos.removeAll()
        photosManager.fetchPhotos(search: text)
        tableView.reloadData()
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        photosManager.fetchPhotos()
        tableView.reloadData()
    }
}
