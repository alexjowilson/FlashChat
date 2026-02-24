import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage  // ← add this

class ProfileSetupViewController: UIViewController {

	@IBOutlet weak var profileImageView: UIImageView!
	@IBOutlet weak var displayNameTextField: UITextField!

	let db = Firestore.firestore()
	private var selectedImage: UIImage?  // ← add this

	override func viewDidLoad() {
		super.viewDidLoad()
		setupUI()
		checkExistingProfile()
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
	}

	private func setupUI() {
		profileImageView.clipsToBounds = true
		profileImageView.layer.borderWidth = 2
		profileImageView.layer.borderColor = UIColor.systemGray4.cgColor
		profileImageView.image = UIImage(systemName: "person.circle.fill")
		profileImageView.tintColor = .systemGray3
		profileImageView.contentMode = .scaleAspectFill
		navigationItem.hidesBackButton = true
	}

	private func checkExistingProfile() {
		guard let uid = Auth.auth().currentUser?.uid else { return }

		db.collection(Constants.FStore.usersCollection).document(uid).getDocument { [weak self] document, error in
			guard let self else { return }

			if let document = document, document.exists,
			   let displayName = document.data()?[Constants.FStore.displayNameField] as? String,
			   !displayName.isEmpty {
				DispatchQueue.main.async {
					self.performSegue(withIdentifier: Constants.profileSetupSegue, sender: self)
				}
			}
		}
	}

	private func showAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		present(alert, animated: true)
	}

	@IBAction func addPhotoPressed(_ sender: UIButton) {
		let picker = UIImagePickerController()
		picker.delegate = self
		picker.allowsEditing = true

		let alert = UIAlertController(title: "Profile Photo", message: nil, preferredStyle: .actionSheet)

		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
				picker.sourceType = .camera
				self.present(picker, animated: true)
			})
		}

		alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { _ in
			picker.sourceType = .photoLibrary
			self.present(picker, animated: true)
		})

		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		present(alert, animated: true)
	}

	@IBAction func continuePressed(_ sender: UIButton) {
		guard let displayName = displayNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
			  !displayName.isEmpty else {
			showAlert(title: "Display Name Required", message: "Please enter a display name to continue.")
			return
		}

		guard let uid = Auth.auth().currentUser?.uid,
			  let email = Auth.auth().currentUser?.email else {
			showAlert(title: "Error", message: "No user logged in.")
			return
		}

		// ← updated: upload photo first if one was selected, then save
		if let image = selectedImage {
			uploadPhoto(image, uid: uid) { [weak self] photoURL in
				self?.saveProfile(uid: uid, email: email, displayName: displayName, photoURL: photoURL)
			}
		} else {
			saveProfile(uid: uid, email: email, displayName: displayName, photoURL: nil)
		}
	}

	// ← add this
	private func uploadPhoto(_ image: UIImage, uid: String, completion: @escaping (String?) -> Void) {
		guard let imageData = image.jpegData(compressionQuality: 0.5) else {
			completion(nil)
			return
		}

		let storageRef = Storage.storage().reference()
			.child("profile_pictures")
			.child("\(uid).jpg")

		let metadata = StorageMetadata()
		metadata.contentType = "image/jpeg"

		storageRef.putData(imageData, metadata: metadata) { [weak self] _, error in
			if let error = error {
				debugLog("Photo upload failed: \(error.localizedDescription)")
				DispatchQueue.main.async {
					self?.showAlert(title: "Upload Failed", message: "Could not upload photo. You can add one later.")
				}
				completion(nil)
				return
			}

			storageRef.downloadURL { url, error in
				if let error = error {
					debugLog("Failed to get download URL: \(error.localizedDescription)")
					completion(nil)
					return
				}
				debugLog("Photo uploaded: \(url?.absoluteString ?? "")")
				completion(url?.absoluteString)
			}
		}
	}

	// ← add this
	private func saveProfile(uid: String, email: String, displayName: String, photoURL: String?) {
		var data: [String: Any] = [
			Constants.FStore.displayNameField: displayName,
			Constants.FStore.emailField: email,
			Constants.FStore.createdAtField: Timestamp(date: Date())
		]

		if let photoURL = photoURL {
			data[Constants.FStore.profilePicField] = photoURL
		}

		db.collection(Constants.FStore.usersCollection).document(uid).setData(data) { [weak self] error in
			guard let self else { return }

			if let error = error {
				debugLog("Error saving profile: \(error)")
				self.showAlert(title: "Error", message: "Could not save profile. Please try again.")
			} else {
				debugLog("Profile saved successfully")
				self.performSegue(withIdentifier: Constants.profileSetupSegue, sender: self)
			}
		}
	}
}

// ← add this extension
extension ProfileSetupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	func imagePickerController(_ picker: UIImagePickerController,
							   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
		let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
		selectedImage = image
		profileImageView.image = image
		picker.dismiss(animated: true)
	}

	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		picker.dismiss(animated: true)
	}
}
