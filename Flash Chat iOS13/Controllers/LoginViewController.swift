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
    

    @IBAction func loginPressed(_ sender: UIButton) {
        
        
        if let email = emailTextfield.text, let password = passwordTextfield.text{
            
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
              guard let strongSelf = self else { return }
              // ...
                // if there is an error, print the error
                if let e = error {
                    print("There is an error with signing in mate")
                    print(e.localizedDescription)
                }
                // else the user was able to log in
                else{
                    print("The user successfully registered")
                    print("email = " + email)
                    print("password = " + password)
                    
                    
                    //Navigate to ChatViewController
                    strongSelf.performSegue(withIdentifier: Constants.loginSegue, sender: self)
                    
                    
                }
            }
        }
    }
}
