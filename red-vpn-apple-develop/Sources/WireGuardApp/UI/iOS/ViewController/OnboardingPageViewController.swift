// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class OnboardingPageViewController: UIViewController {

    let redVpn: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "redVPN")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let slideImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    let label: UILabel = {
        let label = UILabel()
        let screenSize = UIScreen.main.bounds
        label.font = UIFont(name: "SFProText-Regular", size: 18)
        label.numberOfLines = 2
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(image: String, title: String) {
        slideImageView.image = UIImage(named: image)
        label.text = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

     override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(redVpn)
        view.addSubview(slideImageView)
        view.addSubview(label)

        NSLayoutConstraint.activate([
            redVpn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            redVpn.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: view.frame.height < 600 ? 60.0 : 80.0),

            slideImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            slideImageView.topAnchor.constraint(equalTo: redVpn.bottomAnchor, constant: 40.0),

            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: slideImageView.bottomAnchor, constant: view.frame.height < 600 ? 35.0 : 55.0),
            label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 40.0),
            label.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -40.0)
        ])
    }
}
