import UIKit
import Alamofire
import SPAlert

class UserViewController: UIViewController {

    private var id = ""
    public var username = ""
    private var user: User?
    private var photos: [Photo] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    private var userManager = UserManager()
    private var photosManager = PhotosManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "@\(username)"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "UserTableViewCell", bundle: nil), forCellReuseIdentifier: "UserTableViewCell")
        tableView.register(UINib(nibName: "PhotoTableViewCell", bundle: nil), forCellReuseIdentifier: "PhotoTableViewCell")
        
        userManager.delegate = self
        userManager.fetchUser(with: username)
        photosManager.delegate = self
        photosManager.fetchPhotos(with: username)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails" {
            let navigationContoller = segue.destination as! UINavigationController
            let detailViewController = navigationContoller.topViewController as! DetailViewController

            detailViewController.id = id
        }
    }
    
    func didFailWithError(_ error: Error) {
        print(error)
    }
}

extension UserViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return photos.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserTableViewCell", for: indexPath) as! UserTableViewCell
            
            if let safeUser = user {
                cell.userImageView.sd_setImage(with: URL(string: safeUser.profile_image.large))
                cell.nameLabel.text = safeUser.name
                if safeUser.bio != nil {
                    cell.bioLabel.text = safeUser.bio
                } else {
                    if safeUser.location != nil {
                        cell.bioLabel.text = safeUser.location
                    } else {
                        cell.bioLabel.isHidden = true
                    }
                    
                }
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoTableViewCell", for: indexPath) as! PhotoTableViewCell
            
            let photo = photos[indexPath.row]
            
            cell.photoImageView.sd_setImage(with: URL(string: photo.urls.full))
            cell.userImageView.isHidden = true
            cell.nameLabel.isHidden = true
            
            cell.photoImageView.layer.sublayers?.removeAll()
            let gradient = CAGradientLayer()
            gradient.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width - 20, height: 250)
            gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor]
            gradient.locations = [0.6, 1.0]
            cell.photoImageView.layer.insertSublayer(gradient, at: 0)
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 100
        } else {
            return 250
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section != 0 {
            if NetworkReachabilityManager()!.isReachable {
                id = photos[indexPath.row].id
                performSegue(withIdentifier: "showDetails", sender: self)
            } else {
                SPAlert.present(title: "You are offline!", message: "Please, check your internet connection and try again.", preset: .error)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension UserViewController: UserManagerDelegate {
    func didUpdateUser(_ userManager: UserManager, _ user: User) {
        self.user = user
        tableView.reloadData()
    }
}

extension UserViewController: PhotosManagerDelegate {
    func didUpdatePhotos(_ photosManager: PhotosManager, _ photos: [Photo]) {
        self.photos.append(contentsOf: photos)
        tableView.reloadData()
    }
}
