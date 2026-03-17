import UIKit

class MessageCell: UITableViewCell {

    @IBOutlet weak var messageBubble: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var rightAvatar: UIImageView!
    @IBOutlet weak var leftAvatar: UIImageView!
    @IBOutlet weak var rightTimestampLabel: UILabel!
    @IBOutlet weak var leftTimestampLabel: UILabel!

	// DateFormatter is expensive to create; making it static means it's built
	// once and shared by every MessageCell instance.
	private static let timeFormatter: DateFormatter = {
			let f = DateFormatter()
			f.timeStyle = .short   // e.g. "4:20 PM"
			return f
		}()
	
	// Track which URL this cell last requested so we can discard
	// stale callbacks after the cell is reused.
	private var currentAvatarURL: String?
	
	// Add this
	private var bubbleMaxWidthConstraint: NSLayoutConstraint?

	
	
	
    override func awakeFromNib() {
		super.awakeFromNib()
		label.numberOfLines = 0
		label.lineBreakMode = .byWordWrapping
		messageBubble.clipsToBounds = true
		leftAvatar.clipsToBounds = true
		rightAvatar.clipsToBounds = true

		// Set up the max width constraint once
		bubbleMaxWidthConstraint = messageBubble.widthAnchor.constraint(lessThanOrEqualToConstant: 0)
		bubbleMaxWidthConstraint?.isActive = true

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Proper bubble rounding now that frame is known
        messageBubble.layer.cornerRadius = 18
        
        // Make avatars circular
        leftAvatar.layer.cornerRadius = leftAvatar.frame.height / 2
        rightAvatar.layer.cornerRadius = rightAvatar.frame.height / 2
		
		// Update max width now that we know the cell's actual width
		bubbleMaxWidthConstraint?.constant = bounds.width * 0.70
		
	}
   
	
	override func prepareForReuse() {
		super.prepareForReuse()
		// Reset avatar images so a recycled cell never briefly shows the wrong photo
		currentAvatarURL = nil
		leftAvatar.image  = UIImage(systemName: "person.circle.fill")
		rightAvatar.image = UIImage(systemName: "person.circle.fill")
		leftAvatar.tintColor  = .systemGray3
		rightAvatar.tintColor = .systemGray3
	}
	
	
	
	func configure(with message: Message, currentUserEmail: String) {
		let isMe = message.sender == currentUserEmail
		debugLog("sender: \(message.sender) | currentUser: \(currentUserEmail) | isMe: \(isMe)")
 
		label.text = message.body
 
		let timeString = MessageCell.timeFormatter.string(from: message.timestamp)
 
		leftAvatar.isHidden  = isMe
		rightAvatar.isHidden = !isMe
		leftTimestampLabel.isHidden  = isMe
		rightTimestampLabel.isHidden = !isMe
 
		if isMe {
			messageBubble.backgroundColor = UIColor.systemPurple
			label.textColor = .white
			rightTimestampLabel.text = timeString
		} else {
			messageBubble.backgroundColor = UIColor.systemGray5
			label.textColor = .black
			leftTimestampLabel.text = timeString
		}
 
		// Load profile photo asynchronously
		let avatarView = isMe ? rightAvatar : leftAvatar
		loadAvatar(urlString: message.senderProfilePicURL, into: avatarView!)
	}
	// MARK: - Private helpers
 
	private func loadAvatar(urlString: String?, into imageView: UIImageView) {
		guard let urlString, !urlString.isEmpty else {
			setPlaceholder(on: imageView)
			return
		}
 
		currentAvatarURL = urlString
 
		ImageCache.shared.loadImage(from: urlString) { [weak self, weak imageView] image in
			guard let self, let imageView else { return }
 
			// Discard if the cell was reused for a different message while loading
			guard self.currentAvatarURL == urlString else { return }
 
			if let image {
				imageView.image = image
				imageView.tintColor = nil
			} else {
				self.setPlaceholder(on: imageView)
			}
		}
	}
 
	private func setPlaceholder(on imageView: UIImageView) {
		imageView.image = UIImage(systemName: "person.circle.fill")
		imageView.tintColor = .systemGray3
	}
}
