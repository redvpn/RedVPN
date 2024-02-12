// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Foundation

extension TunnelConfiguration {
    enum ConfigError: Error {
        case noEndpoint
    }

    convenience init(fromEndpoint endpoint: Endpoint, basedOn base: TunnelConfiguration) throws {
        if var peer = base.peers.first {
            peer.endpoint = endpoint

            self.init(name: base.name, interface: base.interface, peers: [peer])
        } else {
            throw ConfigError.noEndpoint
        }
    }

    func getEndpoint() -> Endpoint? {
        if peers.isEmpty {
            return nil
        }

        let peer = peers[0]
        let endpoint = peer.endpoint
        return endpoint
    }
}

