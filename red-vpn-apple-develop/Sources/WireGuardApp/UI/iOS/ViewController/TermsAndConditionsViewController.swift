// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import PDFKit

class TermsAndConditionsViewController: UIViewController {
    let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont(name: "SFProDisplay-Regular", size: 24.0)
        titleLabel.numberOfLines = 0
        titleLabel.textColor = UIColor.white
        titleLabel.text = tr("termsAndConditionsTitle")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()

    let pdfView: PDFView = {
        let pdfView = PDFView()
        let urlPath = Bundle.main.path(forResource: "termsAndConditions", ofType: "pdf")
        let url = URL(fileURLWithPath: urlPath!)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.pageShadowsEnabled = false
        pdfView.document = PDFDocument(url: url)
        pdfView.backgroundColor = .backgroundDark
        pdfView.pageBreakMargins = .zero
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        return pdfView
    }()

    let acceptButton: UIButton = {
        let acceptButton = UIButton()
        acceptButton.layer.cornerRadius = 54 / 2
        acceptButton.clipsToBounds = true
        acceptButton.backgroundColor = UIColor.blueBright
        acceptButton.tintColor = UIColor.white
        acceptButton.titleLabel?.font = UIFont(name: "SFProDisplay-Regular", size: 18.0)
        acceptButton.setTitle(tr("termsAndConditionsAccept"), for: .normal)
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        acceptButton.addTarget(self, action: #selector(acceptButtonTouched), for: .touchUpInside)
        return acceptButton
    }()

    var onAcceptButtonTouched: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .backgroundDark

        view.addSubview(titleLabel)
        view.addSubview(pdfView)
        view.addSubview(acceptButton)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 30.0),

            acceptButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            acceptButton.heightAnchor.constraint(equalToConstant: 54.0),
            acceptButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: view.frame.height < 600 ? -20.0 : -40.0),
            acceptButton.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 20.0),
            acceptButton.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -20.0),

            pdfView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor, constant: -20.0),
            pdfView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor, constant: 20.0),
            pdfView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50.0),
            pdfView.bottomAnchor.constraint(equalTo: acceptButton.topAnchor, constant: -50.0)
        ])
    }

    @objc func acceptButtonTouched(_ sender: UIButton) {
        onAcceptButtonTouched?()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

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
