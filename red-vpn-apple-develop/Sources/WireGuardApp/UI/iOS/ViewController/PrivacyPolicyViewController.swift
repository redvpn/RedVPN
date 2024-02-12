// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import PDFKit
import KYDrawerController

class PrivacyPolicyViewController: SubpageViewController {

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

    let privacyTitleLabel: UILabel = {
        let privacyTitleLabel = UILabel()
        privacyTitleLabel.font = UIFont(name: "NunitoSans-Bold", size: 24.0)
        privacyTitleLabel.textColor = .white
        privacyTitleLabel.textAlignment = .left
        privacyTitleLabel.text = tr("privacyPolicyTitle")
        privacyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        return privacyTitleLabel
    }()

    let pdfView: PDFView = {
        let pdfView = PDFView()
        let urlPath = Bundle.main.path(forResource: "privacyPolicy", ofType: "pdf")
        let url = URL(fileURLWithPath: urlPath!)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.pageShadowsEnabled = false
        pdfView.document = PDFDocument(url: url)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.backgroundColor = .backgroundDark
        pdfView.pageBreakMargins = .zero
        return pdfView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .backgroundDark
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "iconMenuLines"), style: .plain, target: self, action: #selector(menuButtonTapped))

        view.addSubview(backToHomeButton)
        view.addSubview(privacyTitleLabel)
        view.addSubview(pdfView)

        NSLayoutConstraint.activate([

            backToHomeButton.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 20),
            backToHomeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backToHomeButton.heightAnchor.constraint(equalToConstant: 30),
            backToHomeButton.widthAnchor.constraint(equalToConstant: 150),

            privacyTitleLabel.topAnchor.constraint(equalTo: backToHomeButton.bottomAnchor, constant: 20),
            privacyTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            privacyTitleLabel.heightAnchor.constraint(equalToConstant: 30),

            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20.0),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20.0),
            pdfView.topAnchor.constraint(equalTo: privacyTitleLabel.bottomAnchor, constant: 20.0),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20.0)
        ])

        restorationIdentifier = "PrivacyPolicyVC"
    }

    @objc func backToHomeButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc func menuButtonTapped() {
        let drawerController = navigationController?.parent as? KYDrawerController
        drawerController?.setDrawerState(.opened, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Scroll to the top...
        if let pdfDocument = self.pdfView.document {
            if let firstPage = pdfDocument.page(at: 0) {
                if let selection = pdfDocument.selection(from: firstPage, atCharacterIndex: 0, to: firstPage, atCharacterIndex: 10) {
                    self.pdfView.go(to: selection)
                }
            }
        }

        self.pdfView.minScaleFactor = self.pdfView.scaleFactor
        self.pdfView.maxScaleFactor = self.pdfView.scaleFactor
    }
}
