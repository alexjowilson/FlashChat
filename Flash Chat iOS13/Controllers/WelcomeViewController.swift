//
//  WelcomeViewController.swift
//  Flash Chat
//
//  Created by Alex Wilson on 11/25/25.
//  Copyright © 2025 Alex Wilson. All rights reserved.
//

import UIKit
import GhostTypewriter


class WelcomeViewController: UIViewController {

    //@IBOutlet weak var titleLabel: CLTypingLabel!
    @IBOutlet weak var titleLabel: TypewriterLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Optional: control typing speed (default is fine too)
        // If your version exposes `charInterval`, use it:
        titleLabel.text = Constants.title
        titleLabel.typingTimeInterval = 0.08


    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        titleLabel.startTypewritingAnimation()
    }

}
