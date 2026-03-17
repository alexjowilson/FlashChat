//
//  RegisterViewController.swift
//  Flash Chat
//
//  Created by Alex Wilson 11/24/25
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {

	@IBOutlet weak var emailTextfield: UITextField!
	@IBOutlet weak var passwordTextfield: UITextField!

	// Bug fix #4 — errors were only debugLog'd, so the user saw nothing when
	// registration failed (e.g. weak password, email already in use).
	private func showAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default))
		present(alert, animated: true)
	}

	@IBAction func registerPressed(_ sender: UIButton) {
		guard
			let email    = emailTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines),
			let password = passwordTextfield.text,
			!email.isEmpty,
			!password.isEmpty
		else {
			showAlert(title: "Missing Info", message: "Please enter an email and password.")
			return
		}

		Auth.auth().createUser(withEmail: email, password: password) { [weak self] _, error in
			guard let self else { return }

			if let error = error as NSError? {
				debugLog("Registration error: \(error.localizedDescription)")

				// Surface a helpful message for the most common failures
				switch error.code {
				case AuthErrorCode.emailAlreadyInUse.rawValue:
					self.showAlert(
						title: "Email Already Registered",
						message: "An account with that email already exists. Please log in instead."
					)
				case AuthErrorCode.invalidEmail.rawValue:
					self.showAlert(
						title: "Invalid Email",
						message: "Please enter a valid email address."
					)
				case AuthErrorCode.weakPassword.rawValue:
					self.showAlert(
						title: "Weak Password",
						message: "Your password must be at least 6 characters."
					)
				case AuthErrorCode.networkError.rawValue:
					self.showAlert(
						title: "Network Error",
						message: "Check your internet connection and try again."
					)
				default:
					self.showAlert(title: "Registration Failed", message: error.localizedDescription)
				}
				return
			}

			debugLog("Registration successful: \(email)")
			self.performSegue(withIdentifier: Constants.registerSegue, sender: self)
		}
	}
}
