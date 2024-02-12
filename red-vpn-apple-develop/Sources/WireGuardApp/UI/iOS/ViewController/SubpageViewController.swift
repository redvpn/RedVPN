// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class SubpageViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let navigationBar = navigationController!.navigationBar
        navigationBar.shadowImage = UIImage()
        navigationBar.barTintColor = .white
        navigationBar.isTranslucent = false
        navigationBar.tintColor = .white

        if #available(iOS 13.0, *) {
            let standardAppearance = navigationBar.standardAppearance.copy()

            let titleTextAttributes = [
                NSAttributedString.Key.font: UIFont(name: "SFProDisplay-Regular", size: 20.0) ?? UIFont.systemFont(ofSize: 20.0),
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]

            navigationItem.titleView = UIImageView(image: UIImage(named: "redVPN"))
            standardAppearance.configureWithOpaqueBackground()
            standardAppearance.backgroundColor = .backgroundDark
            standardAppearance.shadowColor = nil
            standardAppearance.buttonAppearance.normal.titleTextAttributes = titleTextAttributes

            navigationBar.standardAppearance = standardAppearance
            navigationBar.scrollEdgeAppearance = standardAppearance
        }
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)

        let navigationBar = navigationController!.navigationBar
        navigationBar.shadowImage = UIImage()
        navigationBar.barTintColor = .white
        navigationBar.isTranslucent = false
        navigationBar.tintColor = .white

        if #available(iOS 13.0, *) {
            let standardAppearance = navigationBar.standardAppearance.copy()

            standardAppearance.configureWithOpaqueBackground()
            standardAppearance.backgroundColor = .backgroundDark
            standardAppearance.shadowColor = nil

            navigationBar.standardAppearance = standardAppearance
            navigationBar.scrollEdgeAppearance = standardAppearance
        }
    }
}
