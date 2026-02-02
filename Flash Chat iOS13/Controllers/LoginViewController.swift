//
//  LoginViewController.swift
//  Flash Chat
//
//  Created by Alex Wilson on 11/25/25.
//  Copyright © 2025 Alex Wilson. All rights reserved.
//

import UIKit
import FirebaseAuth

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
                print("🔥 domain:", err.domain)
                print("🔥 code:", err.code)
                print("🔥 message:", err.localizedDescription)

                switch err.code {
                case AuthErrorCode.userNotFound.rawValue:
                    print("Account doesn't exist")
                    showAlert(title: "Account Not Found",
                              message: "No user exists with that email. Please register first.")

                case AuthErrorCode.wrongPassword.rawValue:
                    print("Incorrect Password")
                    showAlert(title: "Incorrect Password",
                              message: "That password is incorrect. Please try again.")

                case AuthErrorCode.invalidCredential.rawValue:   // ✅ this is 17004
                    // Common for both “no user” and “wrong password”
                    print("Invalid Credentials (no user and wrong password")
                    showAlert(title: "Login Failed",
                              message: "Invalid email or password.")

                case AuthErrorCode.invalidEmail.rawValue:
                    print("Invalid email")
                    showAlert(title: "Invalid Email",
                              message: "Please enter a valid email address.")

                case AuthErrorCode.networkError.rawValue:
                    print("There was a network error")
                    showAlert(title: "Network Error",
                              message: "Please check your internet connection and try again.")

                case AuthErrorCode.tooManyRequests.rawValue:
                    print("Too many attempts have been made")
                    showAlert(title: "Too Many Attempts",
                              message: "Too many failed attempts. Try again later.")

                case AuthErrorCode.userDisabled.rawValue:
                    print("The account has been disabled")
                    showAlert(title: "Account Disabled",
                              message: "This account has been disabled.")

                default:
                    print("Login failed (default switch statement)")
                    showAlert(title: "Login Failed", message: err.localizedDescription)
                }

                return
            }

            // ✅ success
            self.performSegue(withIdentifier: Constants.loginSegue, sender: self)
        }
    }
    
}

