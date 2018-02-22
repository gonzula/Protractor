//
//  ViewController.swift
//  ProtractorExperiments
//
//  Created by Gonzo Fialho on 22/02/18.
//  Copyright © 2018 Gonzo Fialho. All rights reserved.
//

import UIKit
import Protractor

class ViewController: UIViewController {

    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField?.inputView = protractor
        }
    }

    lazy var protractor: Protractor = {
        let protractor = Protractor(frame: CGRect(x: 0, y: 0,
                                                  width: UIScreen.main.bounds.width,
                                                  height: 220))

        protractor.addTarget(self, action: #selector(ViewController.protractorValueChanged(_:)), for: .valueChanged)
        return protractor
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        textField.becomeFirstResponder()
    }

    // MARK: - User Interaction

    @objc func protractorValueChanged(_ sender: Protractor) {
        textField.text = "\(sender.value)"
    }
}

