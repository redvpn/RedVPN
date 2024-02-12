// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Connectivity
import Foundation

public protocol NetworkStatusListener: class {
    func networkStatusDidChange(status: ConnectivityStatus)
}

class ConnectivityManager: NSObject {
    static let shared = ConnectivityManager()
    var isNetworkAvailable: Bool {
        return connectivityStatus != .notConnected
    }
    var connectivityStatus: ConnectivityStatus = .notConnected
    let connectivity = Connectivity()
    var listeners = [NetworkStatusListener]()

    override init() {
        super.init()
        connectivity.framework = .network

        let connectivityChanged: (Connectivity) -> Void = { [weak self] connectivity in
            self?.updateConnectionStatus(status: connectivity.status)
        }
        connectivity.whenConnected = connectivityChanged
        connectivity.whenDisconnected = connectivityChanged
    }

    func updateConnectionStatus(status: ConnectivityStatus) {

        switch status {
        case .connected:
            debugPrint("Connectivity - Connected")
        case .connectedViaWiFi:
            debugPrint("Connectivity - Connected through WiFi")
        case .connectedViaWiFiWithoutInternet:
            debugPrint("Connectivity - Connected to WiFi, but no internet")
        case .connectedViaCellular:
            debugPrint("Connectivity - Connected through Cellular Data")
        case .connectedViaCellularWithoutInternet:
            debugPrint("Connectivity - Connected to Cellular Data, but no internet")
        case .notConnected:
            debugPrint("Connectivity - No connectivity")
        case .connectedViaEthernet:
            debugPrint("Connectivity Ethernet - Connected")
        case .connectedViaEthernetWithoutInternet:
            debugPrint("Connectivity - Connected to Ethernet, but no internet")
        case .determining:
            debugPrint("Connectivity - Determining")
        }

        self.connectivityStatus = status
        // Sending message to each of the delegates
        for listener in listeners {
            listener.networkStatusDidChange(status: status)
        }
    }

    /// Starts monitoring network connection changes
    func startMonitoring() {
        connectivity.startNotifier()
    }

    /// Stops monitoring network connection changes
    func stopMonitoring() {
        connectivity.stopNotifier()
    }

    // Adds a new listener to the listeners array
    func addListener(listener: NetworkStatusListener) {
        listeners.append(listener)
    }

    // Removes a listener from listeners array
    func removeListener(listener: NetworkStatusListener) {
        listeners = listeners.filter { $0 !== listener }
    }
}
