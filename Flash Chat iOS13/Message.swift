//
//  Message.swift
//  Flash Chat iOS13
//
//  Created by Alex Wilson on 12/1/25.
//  Copyright © 2025 Alex Wilson All rights reserved.
//

import Foundation

struct Message{
    let sender: String // email (for identifying current user)
	let senderName: String // display name (for showing in the UI)
	let senderProfilePicURL: String? // profile pic URL from Firebase Storage
	let body: String
    let timestamp: Date
}
