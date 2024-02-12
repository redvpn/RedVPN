// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import AcknowList

class AcknowledgementViewController: UIViewController {
    var acknowledgement: Acknow?

    let textView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont(name: "SFProDisplay-Regular", size: 18.0)
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = false
        textView.textColor = UIColor.white
        textView.backgroundColor = .backgroundDark
        textView.dataDetectorTypes = UIDataDetectorTypes.link
        let linkTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.linkTextAttributes = linkTextAttributes
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        return textView
    }()

    init(acknowledgement: Acknow) {
        super.init(nibName: nil, bundle: nil)

        self.acknowledgement = acknowledgement
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        restorationIdentifier = "AcknowledgementVC"
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let acknowledgement = self.acknowledgement {
            textView.text = acknowledgement.text
        }
    }
}
