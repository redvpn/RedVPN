// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Foundation
import NetworkExtension

class RedVpnTunnel {
    static let address = "192.168.2.2/32"
    static let dnsServers = ["8.8.8.8"]
    static let endpoint = "lax23s10-in-f4.1e-100.net:443"
    static let allowedIPs = "0.0.0.0/0"

    static func createMockTunnels() -> [NETunnelProviderManager] {
        let privateKey = Data(base64Encoded: "4ORNd5KTkVdudly07E+IBABkmGxy22SK0btrTHU7GkY=")
        let publicKey = Data(base64Encoded: "pXu3oAATzE7TiWL5cGGYdUVDETmNSRKig8SsvNn7rSg=")

        var interface = InterfaceConfiguration(privateKey: PrivateKey(rawValue: privateKey!)!)
        interface.addresses = [IPAddressRange(from: address)!]
        interface.dns = dnsServers.map { DNSServer(from: $0)! }

        var peer = PeerConfiguration(publicKey: PublicKey(rawValue: publicKey!)!)
        peer.endpoint = Endpoint(from: endpoint)
        peer.allowedIPs = [IPAddressRange(from: allowedIPs)!]

        let tunnelConfiguration = TunnelConfiguration(name: AppDelegate.tunnelName, interface: interface, peers: [peer])

        let tunnelProviderManager = NETunnelProviderManager()
        tunnelProviderManager.protocolConfiguration = NETunnelProviderProtocol(tunnelConfiguration: tunnelConfiguration)
        tunnelProviderManager.localizedDescription = tunnelConfiguration.name
        tunnelProviderManager.isEnabled = true

        return [tunnelProviderManager]
    }
}
