// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import UIKit
import Connectivity
import KYDrawerController
import SwiftMessages
import FittedSheets

class TunnelsListTableViewController: SubpageViewController {
    var tunnelsManager: TunnelsManager?
    var sheetVC: SheetViewController?
    let privateKey = KeyStore.shared.privateKey
    let publicKey = KeyStore.shared.publicKey

    let tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.register(TunnelListCell.self)
        tableView.isScrollEnabled = false
        tableView.alwaysBounceVertical = false
        tableView.isHidden = true
        tableView.allowsSelection = false
        return tableView
    }()

    let coverView: UIView = {
        let coverView = UIView(frame: UIScreen.main.bounds)
        coverView.isHidden = true
        coverView.backgroundColor = .backgroundDark
        return coverView
    }()

    let redVpnImageView: UIImageView = {
        let redVpnImageView = UIImageView()
        redVpnImageView.image = UIImage(named: "redVpnInactive")
        redVpnImageView.contentMode = .center
        return redVpnImageView
    }()

    let stateLabel: UILabel = {
        let stateLabel = UILabel()
        stateLabel.font = UIFont(name: "SFProDisplay-Regular", size: 20.0)
        stateLabel.numberOfLines = 0

        let text = tr("vpnStateOff")
        let textToColor = tr("off")
        let range = (text as NSString).range(of: textToColor)
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.light, range: range)
        stateLabel.attributedText = attributedText

        return stateLabel
    }()

    let infoLabel: UILabel = {
        let infoLabel = UILabel()
        infoLabel.font = UIFont(name: "SFProText-Regular", size: 18.0)
        infoLabel.numberOfLines = 0
        infoLabel.textColor = .white
        infoLabel.text = tr("tapToConnect")
        infoLabel.textAlignment = NSTextAlignment.center
        return infoLabel
    }()

    override func loadView() {
        view = UIView()
        view.backgroundColor = .backgroundDark

        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        view.addSubview(coverView)
        coverView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            coverView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            coverView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            coverView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            coverView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])

        coverView.addSubview(redVpnImageView)
        redVpnImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            redVpnImageView.centerXAnchor.constraint(equalTo: coverView.centerXAnchor),
            redVpnImageView.topAnchor.constraint(equalTo: coverView.safeTopAnchor, constant: 40),
            redVpnImageView.widthAnchor.constraint(equalToConstant: 295.0),
            redVpnImageView.heightAnchor.constraint(equalToConstant: 295.0)
        ])

        coverView.addSubview(stateLabel)
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stateLabel.topAnchor.constraint(equalTo: redVpnImageView.bottomAnchor, constant: 28),
            stateLabel.centerXAnchor.constraint(equalTo: coverView.centerXAnchor)
        ])

        coverView.addSubview(infoLabel)
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: stateLabel.bottomAnchor, constant: 16),
            infoLabel.centerXAnchor.constraint(equalTo: coverView.centerXAnchor),
            infoLabel.leftAnchor.constraint(equalTo: coverView.leftAnchor, constant: 20),
            infoLabel.rightAnchor.constraint(equalTo: coverView.rightAnchor, constant: -20)
        ])

        redVpnImageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        redVpnImageView.addGestureRecognizer(tapGestureRecognizer)

        #if !targetEnvironment(simulator)
        pulseAnimation(view: redVpnImageView)
        #endif
    }

    @objc func imageTapped() {
        guard let tunnelsManager = self.tunnelsManager else { return }

        #if !targetEnvironment(simulator)
        pulseAnimation(view: redVpnImageView)
        let tunnelNames = tunnelsManager.mapTunnels { $0.name }

        if tunnelNames.contains(AppDelegate.tunnelName) == false {
            ConfigBuilder.build(privateKey: self.privateKey!, publicKey: self.publicKey!, region: nil) { wgQuickConfig in
                if let wgQuickConfig = wgQuickConfig, let tunnelConfiguration = try? TunnelConfiguration(fromWgQuickConfig: wgQuickConfig, called: AppDelegate.tunnelName) {

                    tunnelsManager.add(tunnelConfiguration: tunnelConfiguration) { result in
                        switch result {
                        case .failure(let error):
                            debugPrint(error.alertText)
                        case .success(let tunnelContainer):
                            debugPrint("Tunnel \(tunnelContainer.name) created.")
                        }
                    }
                } else {
                    let urlPath = Bundle.main.path(forResource: "tunnel", ofType: "conf")
                    let url = URL(fileURLWithPath: urlPath!)
                    TunnelImporter.importTunnel(url: url, into: tunnelsManager) {
                        _ = FileManager.deleteFile(at: url)
                    }
                }
            }
        }
        #endif
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .backgroundDark

        setupNavigationBar()

        // Get regions and set up bottom sheet...
        var regions: [String]?
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()

        DispatchQueue.main.async {
            RegionManager.shared.loadRegions { data in
                regions = data
                dispatchGroup.leave()
            }
        }

        // TODO: Uncomment this code to enable the regions bottom sheet in the future
//        dispatchGroup.notify(queue: .main) {
//            self.setupBottomSheet(regions: regions!)
//        }

        restorationIdentifier = "TunnelsListVC"
    }

    override func viewWillAppear(_: Bool) {
        if let selectedRowIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRowIndexPath, animated: false)
        }

        // Deselect menu items...
        if let drawerController = parent?.parent as? KYDrawerController {
            guard let drawerVC = drawerController.drawerViewController as? DrawerViewController else { return }

            let menuTableView = drawerVC.menuTableView
            if let selectedMenuItem = menuTableView.indexPathForSelectedRow {
                menuTableView.deselectRow(at: selectedMenuItem, animated: false)
            }
        }

        // TODO: Uncomment this code to enable the regions bottom sheet in the future
//        self.displayBottomSheet()
    }

    override func viewWillDisappear(_: Bool) {
        self.sheetVC?.animateOut()
    }

//    func setupBottomSheet(regions: [String]) {
//        let bottomSheetContentVC = BottomSheetContentViewController(regions: regions)
//        if let tunnelsManager = self.tunnelsManager, let tunnel: TunnelContainer = tunnelsManager.tunnel(named: AppDelegate.tunnelName) {
//            bottomSheetContentVC.tunnel = tunnel
//        }
//        let options = SheetOptions(useInlineMode: true)
//        self.sheetVC = SheetViewController(controller: bottomSheetContentVC, sizes: [.fixed(100), .marginFromTop(40)], options: options)
//
//        let sheetVC = self.sheetVC!
//
//        sheetVC.cornerRadius = 35
//        sheetVC.gripColor = .clear
//        sheetVC.overlayColor = .clear
//        sheetVC.allowGestureThroughOverlay = true
//        sheetVC.dismissOnPull = false
//        sheetVC.dismissOnOverlayTap = false
//
//        sheetVC.sizeChanged = { sheet, sheetSize, size in
//            let newState: BottomSheetState = sheetSize == .fixed(100) ? .collapsed : .expanded
//            bottomSheetContentVC.onStateChange(newState: newState)
//        }
//
//        bottomSheetContentVC.regionSelected = { region in
//            self.handleRegionChange(region: region)
//        }
//
//        self.displayBottomSheet()
//    }
//
//    func displayBottomSheet() {
//        guard let sheetVC = self.sheetVC else { return }
//
//        sheetVC.willMove(toParent: self)
//        self.addChild(sheetVC)
//        view.addSubview(sheetVC.view)
//        sheetVC.didMove(toParent: self)
//
//        sheetVC.view.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            sheetVC.view.topAnchor.constraint(equalTo: view.topAnchor),
//            sheetVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            sheetVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            sheetVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
//        ])
//
//        sheetVC.animateIn()
//    }
//
//    func handleRegionChange(region: String) {
//        debugPrint("Region selected: \(region)")
//        RegionManager.shared.setSelectedRegion(region: region)
//        if let tunnelsManager = self.tunnelsManager, let tunnel: TunnelContainer = tunnelsManager.tunnel(named: AppDelegate.tunnelName) {
//            let endpointManager = EndpointManager(tunnel: tunnel, region: region)
//            if let endpoint: Endpoint = endpointManager.getNextEndpoint() {
//                if let mainVC = self.parent as? MainViewController {
//                    mainVC.changeTunnelEndpoint(tunnel: tunnel, endpoint: endpoint) { result in
//                        debugPrint("Result: \(result)")
//                    }
//                }
//            } else {
//                self.getNewEndpoints(tunnelsManager: tunnelsManager, tunnel: tunnel, region: region, checked: false)
//            }
//        }
//    }

    func setupNavigationBar() {
        let navigationBar = navigationController!.navigationBar
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = false

        if #available(iOS 13.0, *) {
            let standardAppearance = navigationBar.standardAppearance.copy()

            let titleTextAttributes = [
                NSAttributedString.Key.font: UIFont(name: "SFProDisplay-Regular", size: 20.0) ?? UIFont.systemFont(ofSize: 20.0),
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]

            standardAppearance.configureWithOpaqueBackground()
            standardAppearance.backgroundColor = .backgroundDark
            standardAppearance.shadowColor = nil
            standardAppearance.buttonAppearance.normal.titleTextAttributes = titleTextAttributes

            navigationBar.standardAppearance = standardAppearance
            navigationBar.scrollEdgeAppearance = standardAppearance
        }

        navigationItem.titleView = UIImageView(image: UIImage(named: "redVPN"))
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "iconMenuLines"), style: .plain, target: self, action: #selector(menuButtonTapped))
    }

    @objc func menuButtonTapped(_ sender: UIButton) {
        if let drawerController = parent?.parent as? KYDrawerController {
            drawerController.setDrawerState(.opened, animated: true)
        }
    }

    func pulseAnimation(view: UIView) {
        guard view.layer.animation(forKey: "pulse") == nil else {
            return
        }

        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 0.5
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.05
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        pulseAnimation.autoreverses = true

        let alphaAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        alphaAnimation.duration = 0.5
        alphaAnimation.fromValue = 1.0
        alphaAnimation.toValue = 0.7
        alphaAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        alphaAnimation.autoreverses = true

        let delayAnimation = CABasicAnimation(keyPath: "delay")
        delayAnimation.duration = 0.75
        delayAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        delayAnimation.autoreverses = true

        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [pulseAnimation, alphaAnimation, delayAnimation]
        animationGroup.duration = 1.25
        animationGroup.repeatCount = .infinity
        animationGroup.fillMode = .forwards
        animationGroup.isRemovedOnCompletion = false

        view.layer.add(animationGroup, forKey: "pulse")
    }

    func stopAnimation() {
        redVpnImageView.layer.removeAllAnimations()
    }

    func setTunnelsManager(tunnelsManager: TunnelsManager) {
        self.tunnelsManager = tunnelsManager
        tunnelsManager.tunnelsListDelegate = self

        #if !targetEnvironment(simulator)
        // Update the tunnel if its private key is not the same as the stored private key...
        if let tunnel: TunnelContainer = tunnelsManager.tunnel(named: AppDelegate.tunnelName),
           let privateKey = tunnel.tunnelConfiguration?.interface.privateKey, privateKey.rawValue != self.privateKey?.rawValue {
            let selectedRegion = RegionManager.shared.getSelectedRegion()
            ConfigBuilder.build(privateKey: self.privateKey!, publicKey: self.publicKey!, region: selectedRegion) { wgQuickConfig in
                if let wgQuickConfig = wgQuickConfig, let tunnelConfiguration = try? TunnelConfiguration(fromWgQuickConfig: wgQuickConfig, called: AppDelegate.tunnelName) {

                    tunnelsManager.modify(tunnel: tunnel, tunnelConfiguration: tunnelConfiguration) { modifyError in
                        let alertText = modifyError?.alertText
                        if let alertText = alertText {
                            debugPrint(alertText)
                        }

                        self.stopAnimation()
                        self.tableView.isHidden = false
                    }
                } else {
                    self.stopAnimation()
                    self.tableView.isHidden = false
                }
            }
        } else {
            stopAnimation()
            self.tableView.isHidden = false
        }
        #else
        self.tableView.isHidden = false
        self.stopAnimation()
        #endif
        tableView.reloadData()
        coverView.isHidden = tunnelsManager.numberOfTunnels() > 0
    }
}

extension TunnelsListTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (tunnelsManager?.numberOfTunnels() ?? 0)
    }

    func getNewEndpoints(tunnelsManager: TunnelsManager, tunnel: TunnelContainer, region: String, checked: Bool) {
        tunnel.isGettingNewEndpoints = true
        ConfigBuilder.build(privateKey: self.privateKey!, publicKey: self.publicKey!, region: region) { wgQuickConfig in
            if let wgQuickConfig = wgQuickConfig, let tunnelConfiguration = try? TunnelConfiguration(fromWgQuickConfig: wgQuickConfig, called: AppDelegate.tunnelName) {

                tunnelsManager.modify(tunnel: tunnel, tunnelConfiguration: tunnelConfiguration) { modifyError in
                    SwiftMessages.hideAll()
                    let alertText = modifyError?.alertText
                    if let alertText = alertText {
                        debugPrint(alertText)
                        SwiftMessages.show(type: .error, message: tr("vpnConnectionTryAgain"), duration: .short)
                    } else if checked {
                        tunnelsManager.startActivation(of: tunnel)
                    }
                    tunnel.isGettingNewEndpoints = false
                }
            } else {
                SwiftMessages.hideAll()
                SwiftMessages.show(type: .error, message: tr("vpnConnectionTryAgain"), duration: .short)
                tunnel.isGettingNewEndpoints = false
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: TunnelListCell = tableView.dequeueReusableCell(for: indexPath)
        if let tunnelsManager = tunnelsManager {
            let tunnel = tunnelsManager.tunnel(at: indexPath.row)
            cell.tunnel = tunnel
            cell.onImageTapped = { () in
                guard let tunnelsManager = self.tunnelsManager else { return }
                if tunnel.redVpnStatus == .inactive {
                    // If there are no stored endpoints get new ones, otherwise turn VPN on...
                    let selectedRegion = RegionManager.shared.getSelectedRegion()
                    let endpointManager = EndpointManager(tunnel: tunnel, region: selectedRegion)
                    if endpointManager.getNextEndpoint() == nil {
                        self.getNewEndpoints(tunnelsManager: tunnelsManager, tunnel: tunnel, region: selectedRegion, checked: true)
                    } else {
                        SwiftMessages.hideAll()
                        tunnelsManager.startActivation(of: tunnel)
                    }
                } else if tunnel.redVpnStatus == .active {
                    tunnelsManager.startDeactivation(of: tunnel)
                }
            }
        }

        // Add gradient background
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.white.cgColor, UIColor.lightGrayishOrange.cgColor]
        gradient.locations = [0.0, 1.0]
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: cell.frame.size.width, height: cell.frame.size.height)
        cell.layer.insertSublayer(gradient, at: 0)

        return cell
    }
}

extension TunnelsListTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.view.frame.height
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tunnelListCell = cell as? TunnelListCell else { return }
        ConnectivityManager.shared.addListener(listener: tunnelListCell)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let networkListenerCell = cell as? NetworkStatusListener else { return }
        ConnectivityManager.shared.removeListener(listener: networkListenerCell)
    }
}

extension TunnelsListTableViewController: TunnelsManagerListDelegate {
    func tunnelAdded(at index: Int) {
        tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        coverView.isHidden = (tunnelsManager?.numberOfTunnels() ?? 0 > 0)
    }

    func tunnelModified(at index: Int) {
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }

    func tunnelMoved(from oldIndex: Int, to newIndex: Int) {
        tableView.moveRow(at: IndexPath(row: oldIndex, section: 0), to: IndexPath(row: newIndex, section: 0))
    }

    func tunnelRemoved(at index: Int, tunnel: TunnelContainer) {
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        coverView.isHidden = (tunnelsManager?.numberOfTunnels() ?? 0 > 0)
    }
}
