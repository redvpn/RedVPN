// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Foundation

class KeyStore: NSObject {
    static let shared = KeyStore()
    private(set) var privateKey: PrivateKey?
    private(set) var publicKey: PublicKey?
    let privateKeyKey = "privateKey"
    let publicKeyKey = "publicKey"

    override init() {
        super.init()

        // Get private key...
        if let privateKeyBase64 = UserDefaults.standard.string(forKey: self.privateKeyKey) {
            if let data = Data(base64Encoded: privateKeyBase64) {
                self.privateKey = PrivateKey(rawValue: data)
            } else {
                self.generatePrivateKey()
            }
        } else {
            self.generatePrivateKey()
        }

        // Get public key...
        if let publicKeyBase64 = UserDefaults.standard.string(forKey: self.publicKeyKey) {
            if let data = Data(base64Encoded: publicKeyBase64) {
                self.publicKey = PublicKey(rawValue: data)
            } else {
                self.generatePublicKey()
            }
        } else {
            self.generatePublicKey()
        }
    }

    private func generatePrivateKey() {
        let data = Curve25519.generatePrivateKey()
        self.privateKey = PrivateKey(rawValue: data)
        let privateKeyBase64: String = self.privateKey!.base64Key
        UserDefaults.standard.set(privateKeyBase64, forKey: self.privateKeyKey)
    }

    private func generatePublicKey() {
        if let privateKey = self.privateKey {
            let data = Curve25519.generatePublicKey(fromPrivateKey: privateKey.rawValue)
            self.publicKey = PublicKey(rawValue: data)
            let publicKeyBase64: String = self.publicKey!.base64Key
            UserDefaults.standard.set(publicKeyBase64, forKey: self.publicKeyKey)
        }
    }
}
