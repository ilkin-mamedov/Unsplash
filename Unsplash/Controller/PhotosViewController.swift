import UIKit
import Alamofire
import Contacts
import SDWebImage

class PhotosViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private var photos: [Photo] = []
    
    private var id = ""
    
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 270
        
        tableView.register(UINib(nibName: "PhotoCell", bundle: nil), forCellReuseIdentifier: "photoCell")
        
        refreshControl.attributedTitle = NSAttributedString()
        refreshControl.addTarget(self, action: #selector(self.loadPhotos), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        loadPhotos(isSearch: false)
    }
    
    @objc func loadPhotos(isSearch: Bool) {
        var url = ""
        
        for index in 1...10 {
            if isSearch {
                url = "https://api.unsplash.com/search/photos?per_page=30&page\(index)&query=\(searchBar.text!.replacingOccurrences(of: " ", with: "+"))&client_id=\(K.ACCESS_KEY)"
            } else {
                url = "https://api.unsplash.com/photos?per_page=30&page\(index)&client_id=\(K.ACCESS_KEY)"
            }
            
            AF.request(url).response { response in
                if let result = response.response {
                    if result.statusCode == 200 {
                        if let safeData = response.data {
                            self.parseJSON(safeData, isSearch)
                        }
                    }
                }
            }
        }
        refreshControl.endRefreshing()
    }
    
    private func parseJSON(_ data: Data, _ isSearch: Bool) {
        let decoder = JSONDecoder()
        
        do {
            if isSearch {
                let searchResults = try decoder.decode(Results.self, from: data)
                photos = searchResults.results
            } else {
                photos = try decoder.decode([Photo].self, from: data)
            }
            tableView.reloadData()
        } catch {
            print(error)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails" {
            let navigationContoller = segue.destination as! UINavigationController
            let detailsViewController = navigationContoller.topViewController as! DetailsViewController

            detailsViewController.id = id
        }
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
        loadPhotos(isSearch: true)
        
        tableView.reloadData()
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadPhotos(isSearch: false)
            
            tableView.reloadData()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}
