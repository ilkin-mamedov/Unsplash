import UIKit
import Alamofire
import Contacts
import SDWebImage
import RealmSwift

class FavoritesViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private let realm = try! Realm()
    private var details: [Detail] = []
    private var id = ""
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 270
        
        tableView.register(UINib(nibName: "PhotoCell", bundle: nil), forCellReuseIdentifier: "photoCell")
        
        refreshControl.attributedTitle = NSAttributedString()
        refreshControl.addTarget(self, action: #selector(self.loadFavorites), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadFavorites()
    }
    
    @objc func loadFavorites() {
        details.removeAll()
        for i in realm.objects(Favorite.self) {
            AF.request("https://api.unsplash.com/photos/\(i.id!)?client_id=\(K.ACCESS_KEY)").response { response in
                if let result = response.response {
                    if result.statusCode == 200 {
                        if let safeData = response.data {
                            self.parseJSON(safeData)
                        }
                    }
                }
            }
        }
        tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    private func parseJSON(_ data: Data) {
        let decoder = JSONDecoder()
        
        do {
            let detail = try decoder.decode(Detail.self, from: data)
            details.append(detail)
        } catch {
            print(error)
        }
        
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails" {
            let navigationContoller = segue.destination as! UINavigationController
            let detailsViewController = navigationContoller.topViewController as! DetailsViewController

            detailsViewController.id = id
        }
    }
    
    
}

extension FavoritesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return details.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "photoCell", for: indexPath) as! PhotoCell
        let detail = details[indexPath.row]
        
        cell.photoImageView.sd_setImage(with: URL(string: detail.urls.full))
        cell.userImageView.sd_setImage(with: URL(string: detail.user.profile_image.large))
        cell.nameLabel.text = detail.user.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        id = details[indexPath.row].id
        performSegue(withIdentifier: "showDetails", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
