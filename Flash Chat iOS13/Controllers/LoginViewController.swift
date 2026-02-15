//
//  LoginViewController.swift
//  Flash Chat
//
//  Created by Alex Wilson on 11/25/25.
//  Copyright © 2025 Alex Wilson. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {

	@IBOutlet weak var emailTextfield: UITextField!
	@IBOutlet weak var passwordTextfield: UITextField!
	

	private func showAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		present(alert, animated: true)
	}
	
	@IBAction func loginPressed(_ sender: UIButton) {

		guard let email = emailTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines),
			  let password = passwordTextfield.text,
			  !email.isEmpty,
			  !password.isEmpty else {
			showAlert(title: "Missing Info", message: "Please enter your email and password.")
			return
		}

		Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
			guard let self else { return }

			if let err = error as NSError? {
				debugLog("🔥 domain: \(err.domain)")
				debugLog("🔥 code: \(err.code)")
				debugLog("🔥 message: \(err.localizedDescription)")
				
				switch err.code {
				case AuthErrorCode.userNotFound.rawValue:
					debugLog("Account doesn't exist")
					showAlert(title: "Account Not Found",
							  message: "No user exists with that email. Please register first.")

				case AuthErrorCode.wrongPassword.rawValue:
					debugLog("Incorrect Password")
					showAlert(title: "Incorrect Password",
							  message: "That password is incorrect. Please try again.")

				case AuthErrorCode.invalidCredential.rawValue:
					debugLog("Invalid Credentials (no user and wrong password")
					showAlert(title: "Login Failed",
							  message: "Invalid email or password.")

				case AuthErrorCode.invalidEmail.rawValue:
					debugLog("Invalid email")
					showAlert(title: "Invalid Email",
							  message: "Please enter a valid email address.")

				case AuthErrorCode.networkError.rawValue:
					debugLog("There was a network error")
					showAlert(title: "Network Error",
							  message: "Please check your internet connection and try again.")

				case AuthErrorCode.tooManyRequests.rawValue:
					debugLog("Too many attempts have been made")
					showAlert(title: "Too Many Attempts",
							  message: "Too many failed attempts. Try again later.")

				case AuthErrorCode.userDisabled.rawValue:
					debugLog("The account has been disabled")
					showAlert(title: "Account Disabled",
							  message: "This account has been disabled.")

				default:
					debugLog("Login failed (default switch statement)")
					showAlert(title: "Login Failed", message: err.localizedDescription)
				}

				return
			}

			// ✅ Success - check if profile exists
			self.checkProfileAndNavigate()
		}
	}
	
	private func checkProfileAndNavigate() {
		guard let uid = Auth.auth().currentUser?.uid else { return }
		
		let db = Firestore.firestore()
		db.collection(Constants.FStore.usersCollection).document(uid).getDocument { [weak self] document, error in
			guard let self = self else { return }
			
			if let document = document, document.exists,
			   let displayName = document.data()?[Constants.FStore.displayNameField] as? String,
			   !displayName.isEmpty {
				// Profile exists → go directly to Chat
				self.performSegue(withIdentifier: "LoginToChat", sender: self)
			} else {
				// No profile → go to ProfileSetup
				self.performSegue(withIdentifier: Constants.loginSegue, sender: self)
			}
		}
	}
}
