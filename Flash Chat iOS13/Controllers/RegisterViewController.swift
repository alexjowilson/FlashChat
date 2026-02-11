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
    
    @IBAction func registerPressed(_ sender: UIButton) {
        
        if let email = emailTextfield.text, let password = passwordTextfield.text{
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
              // ...
                // if there is an error
                if let e = error{
                    debugLog("There's an error mate")
                    debugLog("Registration error: \(e.localizedDescription)")
                }
                // The user successfully registered
                else{
                    debugLog("The user successfully registered")
                    debugLog("email = " + email)
                    debugLog("password = " + password)
                    
                    
                    //Navigate to ChatViewController
                    self.performSegue(withIdentifier: Constants.registerSegue, sender: self)
                    
                }
            }
        }
        

    }
    
    
}
