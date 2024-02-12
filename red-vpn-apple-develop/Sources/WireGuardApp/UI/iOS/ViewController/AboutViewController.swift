// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import KYDrawerController

class AboutViewController: SubpageViewController {

    let backToHomeButton: UIButton = {
        let backToHomeButton = UIButton()
        backToHomeButton.setImage(UIImage(named: "backToHomeArrow"), for: .normal)
        backToHomeButton.tintColor = .white
        backToHomeButton.translatesAutoresizingMaskIntoConstraints = false
        backToHomeButton.addTarget(self, action: #selector(backToHomeButtonTapped), for: .touchUpInside)
        backToHomeButton.setImage(UIImage(named: "backToHomeArrow")?.withRenderingMode(.alwaysTemplate), for: .normal)

        let titleFont = UIFont(name: "SFProDisplay-Regular", size: 14.0) ?? UIFont.systemFont(ofSize: 14.0)
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
        let title = NSAttributedString(string: tr("backToHome"), attributes: titleAttributes)
        backToHomeButton.setAttributedTitle(title, for: .normal)

        backToHomeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        backToHomeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)

        return backToHomeButton
    }()

    let aboutUsTitleLabel: UILabel = {
        let aboutUsTitleLabel = UILabel()
        aboutUsTitleLabel.font = UIFont(name: "SFProDisplay-Regular", size: 20.0)
        aboutUsTitleLabel.textColor = .white
        aboutUsTitleLabel.textAlignment = .left
        aboutUsTitleLabel.text = tr("aboutUsTitle")
        aboutUsTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        return aboutUsTitleLabel
    }()

    let aboutUsTextView: UITextView = {
        let aboutUsTextView = UITextView()
        aboutUsTextView.font = UIFont(name: "SFProText-Regular", size: 16.0)
        aboutUsTextView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        aboutUsTextView.textColor = .white
        aboutUsTextView.textAlignment = .left
        aboutUsTextView.isEditable = false
        aboutUsTextView.isScrollEnabled = true
        aboutUsTextView.alwaysBounceVertical = false
        aboutUsTextView.backgroundColor = .backgroundDark
        aboutUsTextView.text = tr("aboutUsText")
        aboutUsTextView.dataDetectorTypes = UIDataDetectorTypes.link
        aboutUsTextView.translatesAutoresizingMaskIntoConstraints = false
        let linkTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.camel,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        aboutUsTextView.linkTextAttributes = linkTextAttributes
        aboutUsTextView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        return aboutUsTextView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .backgroundDark
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "iconMenuLines"), style: .plain, target: self, action: #selector(menuButtonTapped))

        view.addSubview(backToHomeButton)
        view.addSubview(aboutUsTitleLabel)
        view.addSubview(aboutUsTextView)

        NSLayoutConstraint.activate([
            backToHomeButton.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 20),
            backToHomeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backToHomeButton.heightAnchor.constraint(equalToConstant: 30),
            backToHomeButton.widthAnchor.constraint(equalToConstant: 150),

            aboutUsTitleLabel.topAnchor.constraint(equalTo: backToHomeButton.bottomAnchor, constant: 20),
            aboutUsTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            aboutUsTitleLabel.heightAnchor.constraint(equalToConstant: 30),

            aboutUsTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            aboutUsTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            aboutUsTextView.topAnchor.constraint(equalTo: aboutUsTitleLabel.bottomAnchor),
            aboutUsTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        restorationIdentifier = "AboutVC"
    }

    @objc func backToHomeButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc func menuButtonTapped() {
        let drawerController = navigationController?.parent as? KYDrawerController
        drawerController?.setDrawerState(.opened, animated: true)
    }
}
