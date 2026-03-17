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

// MARK: - PaddingLabel (unchanged)

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

// MARK: - ChatViewController

class ChatViewController: UIViewController {

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var messageTextfield: UITextField!
	@IBOutlet weak var bottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var sendButton: UIButton!

	let db = Firestore.firestore()
	var messages: [Message] = []

	// Bug fix #2 — both of these are set together inside fetchCurrentUserProfile
	// so there's no window where displayName is ready but profilePicURL isn't,
	// or vice-versa.  The send button stays disabled until the fetch completes,
	// which eliminates the race where a fast user sends before the name arrives.
	private var currentUserDisplayName: String = ""
	private var currentUserProfilePicURL: String? = nil

	private let spinner = UIActivityIndicatorView(style: .large)

	// MARK: - Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()

		setupKeyboard()
		setupTableView()
		setupSpinner()

		title = Constants.title
		navigationItem.hidesBackButton = true

		// Disable send until profile is loaded to prevent the race condition
		sendButton.isEnabled = false

		// Fetch profile first, then start listening for messages
		fetchCurrentUserProfile { [weak self] in
			self?.sendButton.isEnabled = true
			self?.loadMessages()
		}
	}

	// MARK: - Setup helpers

	private func setupKeyboard() {
		bottomConstraint.isActive = false
		bottomConstraint = messageTextfield.superview!.bottomAnchor.constraint(
			equalTo: view.keyboardLayoutGuide.topAnchor,
			constant: -12
		)
		bottomConstraint.isActive = true

		let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
		view.addGestureRecognizer(tap)
	}

	private func setupTableView() {
		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 80
		tableView.dataSource = self
		tableView.register(
			UINib(nibName: Constants.cellNibName, bundle: nil),
			forCellReuseIdentifier: Constants.cellIdentifier
		)
	}

	private func setupSpinner() {
		spinner.translatesAutoresizingMaskIntoConstraints = false
		spinner.hidesWhenStopped = true
		view.addSubview(spinner)
		NSLayoutConstraint.activate([
			spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])
		spinner.startAnimating()
	}

	// MARK: - Profile fetch

	/// Fetches display name and profile pic URL for the logged-in user, then
	/// calls `completion` on the main thread.  The send button is disabled
	/// until this returns, which closes the race condition from Bug #2.
	private func fetchCurrentUserProfile(completion: @escaping () -> Void) {
		guard let uid = Auth.auth().currentUser?.uid else {
			completion()
			return
		}

		db.collection(Constants.FStore.usersCollection).document(uid).getDocument { [weak self] document, _ in
			guard let self else { return }

			if let data = document?.data() {
				self.currentUserDisplayName  = data[Constants.FStore.displayNameField] as? String ?? ""
				self.currentUserProfilePicURL = data[Constants.FStore.profilePicField]  as? String
			}

			DispatchQueue.main.async { completion() }
		}
	}

	// MARK: - Firestore listener

	func loadMessages() {
		debugLog("loadMessages: starting snapshot listener")

		db.collection(Constants.FStore.collectionName)
			.order(by: Constants.FStore.dateField)
			.addSnapshotListener { [weak self] querySnapshot, error in
				guard let self else { return }

				self.messages.removeAll()

				if let error {
					debugLog("Firestore error: \(error.localizedDescription)")
				} else if let docs = querySnapshot?.documents {
					for doc in docs {
						let data = doc.data()
						guard
							let sender      = data[Constants.FStore.senderField]    as? String,
							let messageBody = data[Constants.FStore.bodyField]       as? String,
							let timestamp   = data[Constants.FStore.dateField]       as? Timestamp
						else { continue }

						let senderName       = data[Constants.FStore.senderNameField]          as? String ?? sender
						let senderPicURL     = data[Constants.FStore.senderProfilePicURLField] as? String

						self.messages.append(Message(
							sender: sender,
							senderName: senderName,
							senderProfilePicURL: senderPicURL,
							body: messageBody,
							timestamp: timestamp.dateValue()
						))
					}

					DispatchQueue.main.async {
						self.spinner.stopAnimating()
						self.tableView.reloadData()

						if self.messages.count > 0 {
							let last = IndexPath(row: self.messages.count - 1, section: 0)
							self.tableView.scrollToRow(at: last, at: .bottom, animated: true)
						}
					}
				}
			}
	}

	// MARK: - Actions

	@objc func endEditing() {
		view.endEditing(true)
	}

	@IBAction func sendPressed(_ sender: UIButton) {
		guard
			let messageBody = messageTextfield.text?.trimmingCharacters(in: .whitespacesAndNewlines),
			!messageBody.isEmpty,
			let messageSender = Auth.auth().currentUser?.email
		else {
			showToast("Enter a message first")
			return
		}

		sendButton.isEnabled = false

		var docData: [String: Any] = [
			Constants.FStore.senderField:    messageSender,
			Constants.FStore.senderNameField: currentUserDisplayName,
			Constants.FStore.bodyField:      messageBody,
			Constants.FStore.dateField:      Timestamp(date: Date())
		]

		// Include the profile pic URL so existing messages can show the avatar
		// without a separate Firestore read per cell
		if let picURL = currentUserProfilePicURL {
			docData[Constants.FStore.senderProfilePicURLField] = picURL
		}

		db.collection(Constants.FStore.collectionName).addDocument(data: docData) { [weak self] error in
			guard let self else { return }
			self.sendButton.isEnabled = true

			if let error {
				debugLog("Send error: \(error.localizedDescription)")
				self.showToast("Failed to send message")
			} else {
				self.messageTextfield.text = ""
				self.messageTextfield.resignFirstResponder()
				debugLog("Message stored successfully")
			}
		}
	}

	@IBAction func logOutPressed(_ sender: UIBarButtonItem) {
		do {
			try Auth.auth().signOut()
			navigationController?.popToRootViewController(animated: true)
			debugLog("Signed out successfully")
		} catch let error as NSError {
			debugLog("Sign-out error: \(error)")
			showToast("Failed to sign out")
		}
	}

	// MARK: - Toast

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

		UIView.animate(withDuration: 0.2) { label.alpha = 1 }
		UIView.animate(withDuration: 0.25, delay: 1.0, options: .curveEaseInOut) {
			label.alpha = 0
		} completion: { _ in
			label.removeFromSuperview()
		}
	}
}

// MARK: - UITableViewDataSource

extension ChatViewController: UITableViewDataSource {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		messages.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let message = messages[indexPath.row]
		let cell = tableView.dequeueReusableCell(
			withIdentifier: Constants.cellIdentifier,
			for: indexPath
		) as! MessageCell

		cell.configure(with: message, currentUserEmail: Auth.auth().currentUser?.email ?? "")
		return cell
	}
}
