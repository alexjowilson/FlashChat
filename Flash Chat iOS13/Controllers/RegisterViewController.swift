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
                    print("There's an error mate")
                    print(e)
                    print(e.localizedDescription)
                }
                // The user successfully registered
                else{
                    print("The user successfully registered")
                    print("email = " + email)
                    print("password = " + password)
                    
                    
                    //Navigate to ChatViewController
                    self.performSegue(withIdentifier: Constants.registerSegue, sender: self)
                    
                }
            }
        }
        

    }
    
    
}
