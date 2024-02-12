// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Foundation
import SwiftMessages

class TunnelImporter {
    static func importTunnel(url: URL, into tunnelsManager: TunnelsManager, completionHandler: (() -> Void)? = nil) {

        let dispatchGroup = DispatchGroup()
        var configs = [TunnelConfiguration?]()
        var lastFileImportErrorText: String?
        let fileName = url.lastPathComponent
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let fileContents: String
            do {
                fileContents = try String(contentsOf: url)
            } catch let error {
                DispatchQueue.main.async {
                    if let cocoaError = error as? CocoaError, cocoaError.isFileError {
                        lastFileImportErrorText = tr("alertCantOpenInputConfFileTitle")
                    } else {
                        lastFileImportErrorText = tr(format: "alertCantOpenInputConfFileMessage (%@)", fileName)
                    }
                    configs.append(nil)
                    dispatchGroup.leave()
                }
                return
            }
            let tunnelConfiguration = try? TunnelConfiguration(fromWgQuickConfig: fileContents, called: AppDelegate.tunnelName)

            DispatchQueue.main.async {
                if tunnelConfiguration == nil {
                    lastFileImportErrorText = tr(format: "alertBadConfigImportMessage (%@)", fileName)
                }
                configs.append(tunnelConfiguration)
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            tunnelsManager.addMultiple(tunnelConfigurations: configs.compactMap { $0 }) { numberSuccessful, lastAddError in
                if !configs.isEmpty && numberSuccessful == configs.count {
                    completionHandler?()
                    return
                }
                let alertText: String?
                alertText = lastFileImportErrorText ?? lastAddError?.alertText.message

                if let alertText = alertText {
                    debugPrint(alertText)
                } else {
                    completionHandler?()
                }
            }
        }
    }

    static func updateFromFile(url: URL, into tunnelsManager: TunnelsManager, completionHandler: (() -> Void)? = nil) {
        let privateKey = KeyStore.shared.privateKey
        let publicKey = KeyStore.shared.publicKey
        guard let tunnel: TunnelContainer = tunnelsManager.tunnel(named: AppDelegate.tunnelName) else { return }

        let dispatchGroup = DispatchGroup()
        var config: TunnelConfiguration?
        var lastFileImportErrorText: String?
        let fileName = url.lastPathComponent
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let fileContents: String
            do {
                fileContents = try String(contentsOf: url)
            } catch let error {
                DispatchQueue.main.async {
                    if let cocoaError = error as? CocoaError, cocoaError.isFileError {
                        lastFileImportErrorText = tr("alertCantOpenInputConfFileTitle")
                    } else {
                        lastFileImportErrorText = tr(format: "alertCantOpenInputConfFileMessage (%@)", fileName)
                    }
                    config = nil
                    dispatchGroup.leave()
                }
                return
            }

            let wgQuickConfig = ConfigBuilder.parse(privateKey: privateKey!, pubkey: publicKey!, fileContents: fileContents)
            let tunnelConfiguration = wgQuickConfig == nil ? nil : try? TunnelConfiguration(fromWgQuickConfig: wgQuickConfig!, called: AppDelegate.tunnelName)

            DispatchQueue.main.async {
                if tunnelConfiguration == nil {
                    lastFileImportErrorText = tr(format: "alertBadConfigImportMessage (%@)", fileName)
                }
                config = tunnelConfiguration
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: .main) {
            SwiftMessages.hideAll()
            if lastFileImportErrorText == nil {
                tunnelsManager.modify(tunnel: tunnel, tunnelConfiguration: config!, onDemandOption: ActivateOnDemandOption.nonWiFiInterfaceOnly) { modifyError in
                    let alertText: String?
                    alertText = modifyError?.alertText.message
                    if let alertText = alertText {
                        debugPrint(alertText)
                        SwiftMessages.show(type: MessageType.error, message: tr("configUpdateError"), duration: MessageDuration.short)
                    } else {
                        SwiftMessages.show(type: MessageType.success, message: tr("configUpdateSuccess"), duration: MessageDuration.short)
                        completionHandler?()
                    }
                }
            } else {
                debugPrint(lastFileImportErrorText!)
                SwiftMessages.show(type: MessageType.error, message: tr("badConfigFileError"), duration: MessageDuration.short)
            }
        }
    }
}
