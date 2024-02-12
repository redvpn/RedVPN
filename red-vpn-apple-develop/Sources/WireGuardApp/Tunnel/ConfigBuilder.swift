// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import Foundation

class ConfigBuilder {
    private static let profileApiUrl = "https://partners.1e-100.net/api/profile/"
    private static let profileApiUsername = "redvpn"
    private static let profileApiPassword = "6ymP7coq2zXYdOpoXuUF993g"

    static func build(privateKey: PrivateKey, publicKey: PublicKey, region: String?, completionHandler: @escaping ((String?) -> Void)) {
            getProfileData(publicKey: publicKey, region: region) { apiResponse, errorMessage in
            if let apiResponse = apiResponse {
                let endpoint: String = apiResponse.endpoints[0]
                let wgQuickConfig = createWqQuickConfig(privateKey: privateKey.base64Key, publicKey: apiResponse.publicKey, address: apiResponse.address, endpoint: endpoint)

                completionHandler(wgQuickConfig)
            } else {
                completionHandler(nil)
            }
        }
    }

    static func parse(privateKey: PrivateKey, pubkey: PublicKey, fileContents: String) -> String? {
        let jsonString = "\(fileContents.replacingOccurrences(of: "'", with: "\""))"
        let data = jsonString.data(using: .utf8)!
        guard let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return nil }
        debugPrint(json)

        if let address = json["address"] as? String,
           let endpoints = json["endpoint"] as? [String],
           let clientPublicKey = json["client_pubkey"] as? String,
           let serverPublicKey = json["pubkey"] as? String {
            if clientPublicKey == pubkey.base64Key {
                EndpointManager.storeEndpoints(endpoints: endpoints, region: nil)

                let endpoint: String = endpoints[0]
                let wgQuickConfig = createWqQuickConfig(privateKey: privateKey.base64Key, publicKey: serverPublicKey, address: address, endpoint: endpoint)

                return wgQuickConfig
            }
        }

        return nil
    }

    private static func getProfileData(publicKey: PublicKey, region: String?, completionHandler: @escaping (ApiResponse?, String?) -> Void) {
        var request = URLRequest(url: URL(string: profileApiUrl)!)
        request.httpMethod = "POST"
        let loginString = "\(profileApiUsername):\(profileApiPassword)"
        guard let loginData = loginString.data(using: String.Encoding.utf8) else {
            return
        }
        let base64LoginString = loginData.base64EncodedString()
        request.addValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        var parameterDictionary = ["pubkey": publicKey.base64Key]
        if let region = region {
            parameterDictionary["region"] = region
        }
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
            completionHandler(nil, "JSON serialization error")
            return
        }
        request.httpBody = httpBody

        let urlSession = URLSession.shared
        let task = urlSession.dataTask(with: request) { data, response, error -> Void in
            var errorMessage = ""
            if let error = error {
                debugPrint(error)
                errorMessage = error.localizedDescription
            } else if let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 {
                debugPrint(response)
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
                    debugPrint(json)

                    if let status = json["status"] as? String,
                        status == "ok",
                        let message = json["message"] as? String,
                        let address = json["address"] as? String,
                        let endpoint = json["endpoint"] as? String, let serverPublicKey = json["pubkey"] as? String {

                        let endpoints = [endpoint]
                        EndpointManager.storeEndpoints(endpoints: endpoints, region: region)
                        let apiResponse = ApiResponse(status: status, message: message, address: address, endpoints: endpoints, publicKey: serverPublicKey)
                        completionHandler(apiResponse, nil)
                        return
                    } else if let message = json["message"] as? String {
                        debugPrint(message)
                        errorMessage = message
                    }
                } catch let error {
                    debugPrint(error)
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = "Invalid URL"
            }

            completionHandler(nil, errorMessage)
        }

        task.resume()
    }

    private static func createWqQuickConfig(privateKey: String, publicKey: String, address: String, endpoint: String) -> String {
        var wgQuickConfig = "[Interface]\n"
        wgQuickConfig.append("PrivateKey = \(privateKey)\n")
        wgQuickConfig.append("Address = \(address)\n")
        wgQuickConfig.append("DNS = 8.8.8.8\n")
        wgQuickConfig.append("\n[Peer]\n")
        wgQuickConfig.append("PublicKey = \(publicKey)\n")
        wgQuickConfig.append("AllowedIPs = 0.0.0.0/0\n")
        wgQuickConfig.append("Endpoint = \(endpoint)\n")
        wgQuickConfig.append("PersistentKeepalive = 25")

        return wgQuickConfig
    }

}

struct ApiResponse {
    private(set) var status: String
    private(set) var message: String
    private(set) var address: String
    private(set) var endpoints: [String]
    private(set) var publicKey: String

    init(status: String, message: String, address: String, endpoints: [String], publicKey: String) {
        self.status = status
        self.message = message
        self.address = address
        self.endpoints = endpoints
        self.publicKey = publicKey
    }
}
