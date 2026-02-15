//
//  Constants.swift
//  Flash Chat 
//
//  Created by Alex Wilson on 11/25/25.
//  Copyright © 2025 Alex Wilson. All rights reserved.
//

struct Constants {
    static let cellIdentifier = "ReusableCell"
    static let cellNibName = "MessageCell"
    static let title = "FlashChat⚡️"
    static let registerSegue = "RegisterToProfileSetup"
    static let loginSegue = "LoginToProfileSetup"
    static let profileSetupSegue = "ProfileSetupToChat"
    
    struct BrandColors {
        static let purple = "BrandPurple"
        static let lightPurple = "BrandLightPurple"
        static let blue = "BrandBlue"
        static let lighBlue = "BrandLightBlue"
    }
    
    struct FStore {
        static let collectionName = "messages"
        static let senderField = "sender"
        static let bodyField = "body"
        static let dateField = "date"
        
        static let usersCollection = "users"
        static let displayNameField = "displayName"
        static let profilePicField = "profilePicURL"
        static let emailField = "email"
        static let createdAtField = "createdAt"
    }
}
     
