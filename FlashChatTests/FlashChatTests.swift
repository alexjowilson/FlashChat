//
//  FlashChatTests.swift
//  FlashChatTests
//
//  Created by Alex Wilson on 3/16/26.
//  Copyright © 2026 Alex Wilson. All rights reserved.
//

import XCTest

@testable import FlashChat

final class FlashChatTests: XCTestCase {

	// MARK: - Message struct

	func test_message_properties_areStored() {
		let date = Date()
		let msg = Message(sender: "leo@barca.com",
						  senderName: "Leo",
						  body: "Visca Barça!",
						  timestamp: date)
		XCTAssertEqual(msg.sender, "leo@barca.com")
		XCTAssertEqual(msg.senderName, "Leo")
		XCTAssertEqual(msg.body, "Visca Barça!")
		XCTAssertEqual(msg.timestamp, date)
	}

	func test_message_sender_isNotSenderName() {
		let msg = Message(sender: "leo@barca.com",
						  senderName: "Leo Messi",
						  body: "⚽",
						  timestamp: Date())
		XCTAssertNotEqual(msg.sender, msg.senderName)
	}

	// MARK: - isMe logic

	func test_isMe_true_whenSenderMatchesCurrentUser() {
		let email = "alex@flashchat.com"
		let msg = Message(sender: email, senderName: "Alex", body: "Hey", timestamp: Date())
		XCTAssertTrue(msg.sender == email)
	}

	func test_isMe_false_whenSenderIsDifferentUser() {
		let msg = Message(sender: "other@flashchat.com", senderName: "Other", body: "Hey", timestamp: Date())
		XCTAssertFalse(msg.sender == "alex@flashchat.com")
	}

	func test_isMe_false_whenCurrentUserIsEmpty() {
		let msg = Message(sender: "alex@flashchat.com", senderName: "Alex", body: "Hey", timestamp: Date())
		XCTAssertFalse(msg.sender == "")
	}

	// MARK: - Display name trimming

	func test_displayName_validAfterTrimming() {
		let trimmed = "  Alex Wilson  ".trimmingCharacters(in: .whitespacesAndNewlines)
		XCTAssertFalse(trimmed.isEmpty)
		XCTAssertEqual(trimmed, "Alex Wilson")
	}

	func test_displayName_whitespaceOnly_shouldBeRejected() {
		let trimmed = "    ".trimmingCharacters(in: .whitespacesAndNewlines)
		XCTAssertTrue(trimmed.isEmpty)
	}

	func test_displayName_emptyString_shouldBeRejected() {
		let trimmed = "".trimmingCharacters(in: .whitespacesAndNewlines)
		XCTAssertTrue(trimmed.isEmpty)
	}

	// MARK: - Constants

	func test_constants_segueIdentifiers_areNotEmpty() {
		XCTAssertFalse(Constants.registerSegue.isEmpty)
		XCTAssertFalse(Constants.loginSegue.isEmpty)
		XCTAssertFalse(Constants.profileSetupSegue.isEmpty)
		XCTAssertFalse(Constants.loginToChatDirectSegue.isEmpty)
	}

	func test_constants_firestoreFields_areNotEmpty() {
		XCTAssertFalse(Constants.FStore.collectionName.isEmpty)
		XCTAssertFalse(Constants.FStore.senderField.isEmpty)
		XCTAssertFalse(Constants.FStore.senderNameField.isEmpty)
		XCTAssertFalse(Constants.FStore.bodyField.isEmpty)
		XCTAssertFalse(Constants.FStore.dateField.isEmpty)
		XCTAssertFalse(Constants.FStore.usersCollection.isEmpty)
		XCTAssertFalse(Constants.FStore.displayNameField.isEmpty)
	}

	func test_constants_segueIdentifiers_haveExpectedValues() {
		XCTAssertEqual(Constants.registerSegue, "RegisterToProfileSetup")
		XCTAssertEqual(Constants.loginSegue, "LoginToProfileSetup")
		XCTAssertEqual(Constants.profileSetupSegue, "ProfileSetupToChat")
		XCTAssertEqual(Constants.loginToChatDirectSegue, "LoginToChat")
	}

	// MARK: - Timestamp formatting

	func test_timestampFormatter_producesNonEmptyString() {
		let formatter = DateFormatter()
		formatter.timeStyle = .short
		XCTAssertFalse(formatter.string(from: Date()).isEmpty)
	}

	func test_timestampFormatter_sameDateProducesSameString() {
		let formatter = DateFormatter()
		formatter.timeStyle = .short
		let date = Date(timeIntervalSince1970: 1_700_000_000)
		XCTAssertEqual(formatter.string(from: date), formatter.string(from: date))
	}
}
