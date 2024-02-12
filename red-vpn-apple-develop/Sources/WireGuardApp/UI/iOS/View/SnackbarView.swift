// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import SwiftMessages

class SnackbarView: UIView, Identifiable {
    var id: String

    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .background
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let label: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFProDisplay-Regular", size: 18.0)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(message: String, icon: String, id: String?, color: UIColor) {
        self.id = id ?? UUID().uuidString
        super.init(frame: CGRect.zero)

        backgroundColor = .clear

        containerView.layer.borderColor = color.cgColor

        self.label.textColor = color
        self.label.text = message

        if let image = UIImage(named: icon)?.withRenderingMode(.alwaysTemplate) {
            self.imageView.image = image
            self.imageView.tintColor = color
        }

        self.addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            containerView.topAnchor.constraint(equalTo: self.safeTopAnchor, constant: 69),
            containerView.heightAnchor.constraint(equalToConstant: 80)
        ])

        containerView.addSubview(imageView)
        containerView.addSubview(label)
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            imageView.heightAnchor.constraint(equalToConstant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 20),

            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
            label.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
