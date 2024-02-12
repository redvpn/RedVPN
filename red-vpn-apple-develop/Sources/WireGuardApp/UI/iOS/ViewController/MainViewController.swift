// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import SwiftMessages

class MainViewController: UINavigationController {
    var tunnelsManager: TunnelsManager?
    var onTunnelsManagerReady: ((TunnelsManager) -> Void)?
    var tunnelsListVC: TunnelsListTableViewController?

    init() {
        let tunnelsListVC = TunnelsListTableViewController()
        self.tunnelsListVC = tunnelsListVC

        super.init(nibName: nil, bundle: nil)

        viewControllers = [ tunnelsListVC ]

        let titleTextAttributes = [
            NSAttributedString.Key.font: UIFont(name: "SFProDisplay-Regular", size: 20.0)!,
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]

        UIBarButtonItem.appearance().setTitleTextAttributes(titleTextAttributes, for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes(titleTextAttributes, for: .highlighted)

        restorationIdentifier = "MainVC"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        // Create the tunnels manager, and when it's ready, inform tunnelsListVC
        TunnelsManager.create { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                debugPrint(error.alertText)
            case .success(let tunnelsManager):
                self.tunnelsManager = tunnelsManager
                self.tunnelsListVC?.setTunnelsManager(tunnelsManager: tunnelsManager)

                tunnelsManager.activationDelegate = self

                self.onTunnelsManagerReady?(tunnelsManager)
                self.onTunnelsManagerReady = nil
            }
        }
    }

    func allTunnelNames() -> [String]? {
        guard let tunnelsManager = self.tunnelsManager else { return nil }
        return tunnelsManager.mapTunnels { $0.name }
    }
}

extension MainViewController: TunnelsManagerActivationDelegate {
    func tunnelActivationAttemptFailed(tunnel: TunnelContainer, error: TunnelsManagerActivationAttemptError) {
        debugPrint(error.alertText)
    }

    func tunnelActivationAttemptSucceeded(tunnel: TunnelContainer) {
        // Nothing to do
    }

    func tunnelActivationFailed(tunnel: TunnelContainer, error: TunnelsManagerActivationError) {
        debugPrint(error.alertText)

        let selectedRegion = RegionManager.shared.getSelectedRegion()
        let endpoint = tunnel.tunnelConfiguration?.getEndpoint()?.stringRepresentation
        let eventProperties = ["endpoint": endpoint as Any, "region": selectedRegion as Any]

        let endpointManager = tunnelsManager?.endpointManager ?? EndpointManager(tunnel: tunnel, region: selectedRegion)

        if let nextEndpoint = endpointManager.getNextEndpoint() {
            debugPrint("Trying endpoint \(nextEndpoint.stringRepresentation)")
            changeTunnelEndpoint(tunnel: tunnel, endpoint: nextEndpoint) { result in
                debugPrint("Result: \(result)")
            }
        } else {
            tunnelsManager?.startDeactivation(of: tunnel)
            SwiftMessages.hideAll()
            SwiftMessages.show(type: .error, message: tr("vpnConnectionTryAgain"), duration: .short)
            EndpointManager.removeEndpoints(region: selectedRegion)
        }
    }

    func tunnelActivationSucceeded(tunnel: TunnelContainer, ip: String?) {
        SwiftMessages.hideAll()
        tunnel.isCheckingConnectivity = false

        let selectedRegion = RegionManager.shared.getSelectedRegion()
        let endpoint = tunnel.tunnelConfiguration?.getEndpoint()?.stringRepresentation
        let eventProperties = ["endpoint": endpoint as Any, "region": selectedRegion as Any]

    }

    func changeTunnelEndpoint(tunnel: TunnelContainer, endpoint: Endpoint, completionHandler: @escaping ((Bool) -> Void)) {
        debugPrint("Attempting to change the tunnel endpoint to \(endpoint.stringRepresentation)")
        if let tunnelsManager = self.tunnelsManager, let tunnelConfiguration = tunnel.tunnelConfiguration {
            let newConfig = try? TunnelConfiguration(fromEndpoint: endpoint, basedOn: tunnelConfiguration)
            tunnelsManager.modify(tunnel: tunnel, tunnelConfiguration: newConfig!) { modifyError in
                let alertText = modifyError?.alertText
                if let alertText = alertText {
                    wg_log(.error, message: alertText.message)
                    completionHandler(false)
                } else {
                    completionHandler(true)
                }
            }
        } else {
            completionHandler(false)
        }
    }
}

extension MainViewController {
    func refreshTunnelConnectionStatuses() {
        if let tunnelsManager = tunnelsManager {
            tunnelsManager.refreshStatuses()
        }
    }
}
