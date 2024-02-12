// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Foundation

class RegionManager: NSObject {
    static let shared = RegionManager()
    private let regionsApiUrl = "https://d2gs9rprpayrzi.cloudfront.net/api/2/regions/"
    private let selectedRegionKey = "redVpnSelectedRegion"
    static let latency = "latency"
    private var regions: [String]
    private var selectedRegion: String?

    override init() {
        self.regions = [RegionManager.latency]

        super.init()
    }

    func getSelectedRegion() -> String {
        if let selectedRegion = self.selectedRegion {
            return selectedRegion
        }

        if let selectedRegion = UserDefaults.standard.string(forKey: selectedRegionKey) {
            if regions.contains(selectedRegion) {
                self.selectedRegion = selectedRegion
            } else {
                setSelectedRegion(region: RegionManager.latency)
            }
        } else {
            self.selectedRegion = RegionManager.latency
        }

        return self.selectedRegion!
    }

    func setSelectedRegion(region: String) {
        UserDefaults.standard.setValue(region, forKeyPath: selectedRegionKey)
        self.selectedRegion = region
        debugPrint("Region selected: \(region)")
    }

    func loadRegions(completionHandler: @escaping ([String]) -> Void) {
        if self.regions.count > 1 {
            completionHandler(self.regions)
        }

        var request = URLRequest(url: URL(string: regionsApiUrl)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 5
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let urlSession = URLSession.shared
        let task = urlSession.dataTask(with: request) { data, response, error -> Void in
            if let error = error {
                debugPrint(error)
            } else if let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 {
                debugPrint(response)
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
                    debugPrint(json)

                    if let status = json["status"] as? String,
                        status == "ok",
                        let regions = json["regions"] as? [String] {
                        self.regions.append(contentsOf: regions)
                    } else if let message = json["message"] as? String {
                        debugPrint(message)
                    }
                } catch let error {
                    debugPrint(error)
                }
            }

            completionHandler(self.regions)
        }

        task.resume()
    }
}
