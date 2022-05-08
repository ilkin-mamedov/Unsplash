import UIKit
import SDWebImage

class PhotosViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var id = ""
    private let refreshControl = UIRefreshControl()
    private var photosManager = PhotosManager()
    private var photos: [Photo] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        photosManager.delegate = self
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 270
        
        tableView.register(UINib(nibName: "PhotoCell", bundle: nil), forCellReuseIdentifier: "photoCell")
        
        refreshControl.attributedTitle = NSAttributedString()
        refreshControl.addTarget(self, action: #selector(self.loadPhotos), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        loadPhotos()
    }
    
    @objc func loadPhotos() {
        photosManager.fetchPhotos()
        tableView.reloadData()
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

extension PhotosViewController: PhotosManagerDelegate {
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

extension PhotosViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "photoCell", for: indexPath) as! PhotoCell
        let photo = photos[indexPath.row]
        
        cell.photoImageView.sd_setImage(with: URL(string: photo.urls.full))
        cell.userImageView.sd_setImage(with: URL(string: photo.user.profile_image.large))
        cell.nameLabel.text = photo.user.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        id = photos[indexPath.row].id
        performSegue(withIdentifier: "showDetails", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension PhotosViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        photosManager.fetchPhotos(search: searchBar.text!)
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            searchBar.resignFirstResponder()
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            photosManager.fetchPhotos()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                searchBar.resignFirstResponder()
            }
        }
    }
}
