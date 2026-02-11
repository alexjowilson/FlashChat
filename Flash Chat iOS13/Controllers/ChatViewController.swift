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


final class PaddingLabel: UILabel {
    var insets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right,
                      height: s.height + insets.top + insets.bottom)
    }
}

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
    
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
    
    private func showToast(_ text: String) {
        let label = PaddingLabel()
        label.text = text
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.alpha = 0

        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: messageTextfield.superview!.topAnchor, constant: -12),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])

        UIView.animate(withDuration: 0.2) {
            label.alpha = 1
        }

        UIView.animate(withDuration: 0.25, delay: 1.0, options: [.curveEaseInOut]) {
            label.alpha = 0
        } completion: { _ in
            label.removeFromSuperview()
        }
    }
    
    // function to load messages from Firebase DB
    func loadMessages() {
        
        debugLog("inside loadMessages")
        
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
                               let messageBody = data[Constants.FStore.bodyField] as? String,
                               let timestamp = data[Constants.FStore.dateField] as? Timestamp{

                                let newMessage = Message(sender: sender, body: messageBody, timestamp: timestamp.dateValue())
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
        
        debugLog("leaving loadMessages() mate")
        
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        
        print("inside sendPressed()")
        
        // Validate message isn't empty and user is logged in
        guard let messageBody = messageTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !messageBody.isEmpty,
              let messageSender = Auth.auth().currentUser?.email else {
            showToast("Enter a message first")
            return
        }
        
        // Disable button to prevent double taps
        sendButton.isEnabled = false
        
        
        debugLog("messageBody and messageSender exist")
        
        
        // add in firebase db
        db.collection(Constants.FStore.collectionName).addDocument(data: [
            Constants.FStore.senderField: messageSender,
            Constants.FStore.bodyField: messageBody,
            Constants.FStore.dateField: Timestamp(date: Date())
        ]) { [weak self] error in
            guard let self else { return }
            
            // Re-enable button
            self.sendButton.isEnabled = true
            
            if let error = error {
                debugLog("Error adding document: \(error.localizedDescription)")
                self.showToast("Failed to send message")
            } else {
                
                debugLog("Document successfully added")
                
                self.messageTextfield.text = ""
                self.messageTextfield.resignFirstResponder()
                self.showToast("Message sent!")
                
                debugLog("message was successfuly stored in firebase db")
                
            }
        }
        
        debugLog("leaving sendPressed() mate")
        
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
            
            debugLog("The user was able to sign out successfully")
            
            
            
        } catch let signOutError as NSError {
            
            debugLog("Error signing out: \(signOutError)")
            
            showToast("Failed to sign out")
        }
    }
}

// Protocol that's responsible for populating the TableView
extension ChatViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        debugLog("inside numberOfRowsInSection()")
        debugLog("# of messages = " + "\(messages.count)")
        debugLog("leaving numberOfRowsInSection()")
        
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        debugLog("inside cellForRowAt()")
        debugLog("row number = " + "\(indexPath.row)")
        
        let message = messages[indexPath.row]
        
        debugLog("message = " + message.body)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)
            as! MessageCell

        let currentUserEmail = Auth.auth().currentUser?.email ?? ""
        cell.configure(with: message, currentUserEmail: currentUserEmail)
        
        
        debugLog("leaving cellForRowAt()")
        
        return cell
    }
}
