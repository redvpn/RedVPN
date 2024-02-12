// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import Foundation

class EndpointManager {
    static let endpointsKeyPrefix = "redVpnEndpoints"
    private var endpoints: [Endpoint] = []
    private var stack: Stack<Endpoint>

    init(tunnel: TunnelContainer, region: String?) {
        stack = Stack<Endpoint>()
        loadEndpoints(region: region)
        endpoints.shuffle()
        let currentEndpoint = tunnel.tunnelConfiguration?.getEndpoint()

        for endpoint in endpoints where endpoint != currentEndpoint {
            stack.push(endpoint)
        }
    }

    public func getNextEndpoint() -> Endpoint? {
        return stack.pop()
    }

    private func loadEndpoints(region: String?) {
        let key = EndpointManager.getEndpointsKey(region: region)
        if let endpointsString = UserDefaults.standard.string(forKey: key) {
            let endpoints = endpointsString.splitToArray(separator: ",")
            for endpointString in endpoints {
                if let endpoint = Endpoint(from: endpointString) {
                    self.endpoints.append(endpoint)
                }
            }
        }
    }

    static func storeEndpoints(endpoints: [String], region: String?) {
        let key = getEndpointsKey(region: region)
        UserDefaults.standard.set(endpoints.joined(separator: ","), forKey: key)
    }

    static func removeEndpoints(region: String?) {
        let key = getEndpointsKey(region: region)
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func getEndpointsKey(region: String?) -> String {
        var key: String = endpointsKeyPrefix
        if let region = region {
            if region != RegionManager.latency {
                key += "_\(region)"
            }
        }

        return key
    }
}
