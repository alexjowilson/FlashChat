//
//  ProfileSetupViewController.swift
//  FlashChat
//
//  Created by Alex Wilson on 2/13/26.
//  Copyright © 2026 Alex Wilson All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileSetupViewController: UIViewController {

	
	@IBOutlet weak var profileImageView: UIImageView!
	@IBOutlet weak var displayNameTextField: UITextField!
	
	let db = Firestore.firestore()
	private var shouldSkipToChat = false  // Add this flag
	
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		setupUI()
		checkExistingProfile()
    }
	override func viewDidAppear(_ animated: Bool) {
		
		super.viewDidAppear(animated)
			
		// Perform segue here when view is fully ready
		if shouldSkipToChat {
			performSegue(withIdentifier: Constants.profileSetupSegue, sender: self)
		}
	}
	
	private func setupUI() {
		// Make profile image circular
		profileImageView.layer.cornerRadius = 60  // Half of 120
		profileImageView.clipsToBounds = true
		profileImageView.layer.borderWidth = 2
		profileImageView.layer.borderColor = UIColor.systemGray4.cgColor
		
		// Set placeholder image
		profileImageView.image = UIImage(systemName: "person.circle.fill")
		profileImageView.tintColor = .systemGray3
		profileImageView.contentMode = .scaleAspectFill
		
		// Hide back button (user must complete profile)
		navigationItem.hidesBackButton = true
	}
	
	private func checkExistingProfile() {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		db.collection(Constants.FStore.usersCollection).document(uid).getDocument { [weak self] document, error in
			guard let self = self else { return }
			
			if let document = document, document.exists,
			   let displayName = document.data()?[Constants.FStore.displayNameField] as? String,
			   !displayName.isEmpty {
				
				// Use a small delay to ensure view is ready
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
		
		showAlert(title: "Coming Soon!", message: "Photo upload will be available in a future update!")
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
		
		// Save profile to Firestore
		db.collection(Constants.FStore.usersCollection).document(uid).setData([
			Constants.FStore.displayNameField: displayName,
			Constants.FStore.emailField: email,
			Constants.FStore.createdAtField: Timestamp(date: Date())
		]) { [weak self] error in
			guard let self = self else { return }
			
			if let error = error {
				print("Error saving profile: \(error)")
				self.showAlert(title: "Error", message: "Could not save profile. Please try again.")
			} else {
				print("Profile saved successfully")
				self.performSegue(withIdentifier: Constants.profileSetupSegue, sender: self)
			}
		}
	}
	
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
