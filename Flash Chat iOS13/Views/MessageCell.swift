import UIKit

class MessageCell: UITableViewCell {

    @IBOutlet weak var messageBubble: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var rightAvatar: UIImageView!
    @IBOutlet weak var leftAvatar: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Avoid rounding here; views aren't sized yet
        label.numberOfLines = 0
        messageBubble.clipsToBounds = true

        leftAvatar.clipsToBounds = true
        rightAvatar.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Proper bubble rounding now that frame is known
        messageBubble.layer.cornerRadius = 18
        
        // Make avatars circular
        leftAvatar.layer.cornerRadius = leftAvatar.frame.height / 2
        rightAvatar.layer.cornerRadius = rightAvatar.frame.height / 2
    }
    
    func configure(with message: Message, currentUserEmail: String) {
        let isMe = message.sender == currentUserEmail
        print("sender:", message.sender, "| currentUser:", currentUserEmail, "| isMe:", isMe)
        
        label.text = message.body

        // Hide or show correct avatars
        leftAvatar.isHidden = isMe
        rightAvatar.isHidden = !isMe

        // Bubble colors based on sender
        if isMe {
            messageBubble.backgroundColor = UIColor.systemPurple
            label.textColor = .white
        } else {
            messageBubble.backgroundColor = UIColor.systemGray5
            label.textColor = .black
        }
    }
}
