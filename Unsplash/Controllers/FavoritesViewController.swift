import UIKit
import Alamofire
import SDWebImage
import RealmSwift
import SPAlert

class FavoritesViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nothingLabel: UILabel!
    
    private var id = ""
    private let realm = try! Realm()
    private var favorites: [Detail] = []
    private let refreshControl = UIRefreshControl()
    private var favoriteManager = FavoriteManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Favorites"
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        favoriteManager.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 250
        
        tableView.register(UINib(nibName: "PhotoCell", bundle: nil), forCellReuseIdentifier: "photoCell")
        
        refreshControl.attributedTitle = NSAttributedString()
        refreshControl.addTarget(self, action: #selector(self.loadFavorites), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadFavorites()
    }
    
    @objc func loadFavorites() {
        if NetworkReachabilityManager()!.isReachable {
            if realm.objects(Favorite.self).isEmpty {
                favorites.removeAll()
                nothingLabel.isHidden = false
                tableView.reloadData()
            } else {
                favorites.removeAll()
                for i in realm.objects(Favorite.self) {
                    favoriteManager.fetchFavorite(with: i.id!)
                }
                nothingLabel.isHidden = true
                tableView.reloadData()
            }
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

extension FavoritesViewController: FavoriteManagerDelegate {
    func didUpdateFavorite(_ favoriteManager: FavoriteManager, _ favorite: Detail) {
        favorites.append(favorite)
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func didFailWithError(_ error: Error) {
        print(error)
    }
}

extension FavoritesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favorites.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "photoCell", for: indexPath) as! PhotoCell
        let favorite = favorites[indexPath.row]
        
        cell.photoImageView.sd_setImage(with: URL(string: favorite.urls.full))
        cell.userImageView.sd_setImage(with: URL(string: favorite.user.profile_image.large))
        cell.nameLabel.text = favorite.user.name
        
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
            id = favorites[indexPath.row].id
            performSegue(withIdentifier: "showDetails", sender: self)
        } else {
            SPAlert.present(title: "You are offline!", message: "Please, check your internet connection and try again.", preset: .error)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
