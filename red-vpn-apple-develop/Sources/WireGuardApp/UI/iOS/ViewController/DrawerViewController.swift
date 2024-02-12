// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import KYDrawerController
import AcknowList

struct MenuItem {
    var text: String
    var icon: String
    var viewController: UIViewController
}

class DrawerViewController: UIViewController {

    let menuItems = [
        MenuItem(text: tr("aboutUsTitle"), icon: "iconAbout", viewController: AboutViewController()),
        MenuItem(text: tr("privacyPolicyTitle"), icon: "iconPrivacyPolicy", viewController: PrivacyPolicyViewController())
    ]

    let headerView: UIView = {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.black
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()

    let redVpnLogoView: UIImageView = {
        let redVpnLogoView = UIImageView()
        redVpnLogoView.image = UIImage(named: "redVPN")
        redVpnLogoView.translatesAutoresizingMaskIntoConstraints = false
        return redVpnLogoView
    }()

    let menuTableView: UITableView = {
        let menuTableView = UITableView(frame: CGRect.zero, style: .plain)
        menuTableView.separatorStyle = .singleLine
        menuTableView.separatorColor = UIColor.darkGray
        menuTableView.register(NavigationMenuCell.self)
        menuTableView.isScrollEnabled = false
        menuTableView.alwaysBounceVertical = false
        menuTableView.tableFooterView = UIView()
        menuTableView.semanticContentAttribute = .forceLeftToRight
        menuTableView.backgroundColor = .black
        menuTableView.translatesAutoresizingMaskIntoConstraints = false
        return menuTableView
    }()

    let ossIcon: UIImageView = {
        let ossIcon = UIImageView()
        ossIcon.image = UIImage(named: "iconInfo")!.withRenderingMode(.alwaysTemplate)
        ossIcon.tintColor = UIColor.white
        ossIcon.isUserInteractionEnabled = true
        ossIcon.translatesAutoresizingMaskIntoConstraints = false
        return ossIcon
    }()

    let closeIcon: UIImageView = {
        let closeIcon = UIImageView()
        closeIcon.image = UIImage(named: "iconCloseX")!.withRenderingMode(.alwaysTemplate)
        closeIcon.tintColor = UIColor.white
        closeIcon.isUserInteractionEnabled = true
        closeIcon.translatesAutoresizingMaskIntoConstraints = false
        return closeIcon
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        menuTableView.dataSource = self
        menuTableView.delegate = self

        setupViews()

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ossIconTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        ossIcon.addGestureRecognizer(tapGestureRecognizer)

        let closeIconTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeIconTapped))
        closeIconTapGestureRecognizer.numberOfTapsRequired = 1
        closeIcon.addGestureRecognizer(closeIconTapGestureRecognizer)
    }

    @objc func closeIconTapped() {
        if let drawerController = parent as? KYDrawerController {
            drawerController.setDrawerState(.closed, animated: true)
        }
    }

    @objc func ossIconTapped() {
        if let drawerController = parent as? KYDrawerController {
            guard let mainVC = drawerController.mainViewController as? MainViewController else { return }

            let acknowledgementsViewController = AcknowledgementsViewController()
            if (mainVC.viewControllers.last as? AcknowledgementViewController) != nil {
                mainVC.popViewController(animated: false)
            }
            mainVC.popViewController(animated: false)
            mainVC.viewControllers.last?.navigationItem.title = tr("openSourceLibrariesTitle")
            mainVC.pushViewController(acknowledgementsViewController, animated: false)
            // Deselect menu items...
            if let selectedMenuItem = menuTableView.indexPathForSelectedRow {
                menuTableView.deselectRow(at: selectedMenuItem, animated: false)
            }

            drawerController.setDrawerState(.closed, animated: true)
        }
    }

    private func setupViews() {
        view.addSubview(headerView)
        headerView.addSubview(redVpnLogoView)
        headerView.addSubview(closeIcon)
        view.addSubview(menuTableView)
        view.addSubview(ossIcon)

        NSLayoutConstraint.activate([
            headerView.widthAnchor.constraint(equalTo: view.widthAnchor),
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 130),

            redVpnLogoView.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 20),
            redVpnLogoView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 17),

            closeIcon.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 20),
            closeIcon.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            closeIcon.widthAnchor.constraint(equalToConstant: 24),
            closeIcon.heightAnchor.constraint(equalToConstant: 24),

            menuTableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            menuTableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            menuTableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            menuTableView.heightAnchor.constraint(equalToConstant: 156),

            ossIcon.widthAnchor.constraint(equalToConstant: 24.0),
            ossIcon.heightAnchor.constraint(equalToConstant: 24.0),
            ossIcon.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10.0),
            ossIcon.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -10.0)
        ])
    }
}

extension DrawerViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: NavigationMenuCell = tableView.dequeueReusableCell(for: indexPath)
        cell.configureCell(menu: menuItems[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
}

extension DrawerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let drawerController = parent as? KYDrawerController {
            guard let mainVC = drawerController.mainViewController as? MainViewController else { return }
            if (mainVC.viewControllers.last as? AcknowledgementViewController) != nil {
                mainVC.popViewController(animated: false)
            }
            mainVC.popViewController(animated: false)
            mainVC.viewControllers.last?.navigationItem.title = menuItems[indexPath.row].text
            mainVC.pushViewController(self.menuItems[indexPath.row].viewController, animated: false)

            drawerController.setDrawerState(.closed, animated: true)
        }
    }
}
