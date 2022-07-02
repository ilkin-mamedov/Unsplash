import UIKit

class PhotoCell: UITableViewCell {

    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        bgView.layer.cornerRadius = 15
        photoImageView.layer.cornerRadius = 15
        userImageView.layer.cornerRadius = 25
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
