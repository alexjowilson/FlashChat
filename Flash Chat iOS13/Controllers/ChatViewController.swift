//
//  ChatViewController.swift
//  Flash Chat
//
//  Created by Alex Wilson on 11/25/25
//  Copyright © 2025 Alex Wilson. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    let db = Firestore.firestore() // initialize firebase firestore
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("inside viewDidLoad() of ChatViewController()")
        bottomConstraint.isActive = false


        bottomConstraint = messageTextfield.superview!.bottomAnchor.constraint(
            equalTo: view.keyboardLayoutGuide.topAnchor,
            constant: -12     // 👈 increase or decrease this value
        )
        bottomConstraint.isActive = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        view.addGestureRecognizer(tap)

        
        title = Constants.title
        navigationItem.hidesBackButton = true
        tableView.dataSource = self
        tableView.register(UINib(nibName: Constants.cellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        loadMessages()
        
    }
    
    @objc func endEditing() {
        view.endEditing(true)
    }
    
    // function to load messages from Firebase DB
    func loadMessages() {
        print("inside loadMessages")

        db.collection(Constants.FStore.collectionName)
            .order(by: Constants.FStore.dateField)            // make sure messages are ordered
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }

                // Clear the array *each time* we get a new snapshot
                self.messages.removeAll()

                if let error = error {
                    print("There was an issue retrieving data from Firestore: \(error)")
                } else {
                    if let snapshotDocuments = querySnapshot?.documents {
                        for doc in snapshotDocuments {
                            let data = doc.data()
                            if let sender = data[Constants.FStore.senderField] as? String,
                               let messageBody = data[Constants.FStore.bodyField] as? String {

                                let newMessage = Message(sender: sender, body: messageBody)
                                self.messages.append(newMessage)
                            }
                        }

                        // Reload table *once* after processing all documents
                        DispatchQueue.main.async {
                            self.tableView.reloadData()

                            // Optional: scroll to the latest message
                            if self.messages.count > 0 {
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                            }
                        }
                    }
                }
            }

        print("leaving loadMessages() mate")
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        
        print("inside sendPressed()")
        // once the user presses send, grab the message and the current user and store in firebase db
        if let messageBody = messageTextfield.text,
           let messageSender = Auth.auth().currentUser?.email {
            print("messageBody and messageSender exist")
            // add in firebase db
            db.collection(Constants.FStore.collectionName).addDocument(data: [
                Constants.FStore.senderField: messageSender,
                Constants.FStore.bodyField: messageBody,
                Constants.FStore.dateField: Timestamp(date: Date())   // for ordering
            ]) { error in
                if let error = error {
                    print("Error adding document: \(error.localizedDescription)")
                } else {
                    print("Document successfully added")
                    // clear the text field after sending
                    self.messageTextfield.text = ""
                    print("message was successfuly stored in firebase db")
                }
            }
        }
        print("leaving sendPressed()qq mate")
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
            print("The user was able to sign out successfully")
            
            
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

// Protocol that's responsible for populating the TableView
extension ChatViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("inside numberOfRowsInSection()")
        print("# of messages = " + "\(messages.count)")
        print("leaving numberOfRowsInSection()")
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("inside cellForRowAt()")
        print("row number = " + "\(indexPath.row)")
        let message = messages[indexPath.row]
        print("message = " + message.body)
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)
            as! MessageCell

        let currentUserEmail = Auth.auth().currentUser?.email ?? ""
        cell.configure(with: message, currentUserEmail: currentUserEmail)

        print("leaving cellForRowAt()")
        return cell
    }
}
