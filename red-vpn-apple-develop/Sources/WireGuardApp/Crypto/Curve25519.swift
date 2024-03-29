// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Foundation

struct Curve25519 {

    static let keyLength: Int = 32

    static func generatePrivateKey() -> Data {
        var privateKey = Data(repeating: 0, count: TunnelConfiguration.keyLength)
        privateKey.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) -> Void in
            curve25519_generate_private_key(pointer)
        }
        assert(privateKey.count == TunnelConfiguration.keyLength)
        return privateKey
    }

    static func generatePublicKey(fromPrivateKey privateKey: Data) -> Data {
        assert(privateKey.count == TunnelConfiguration.keyLength)
        var publicKey = Data(repeating: 0, count: TunnelConfiguration.keyLength)
        privateKey.withUnsafeBytes { privateKeyBytes in
            publicKey.withUnsafeMutableBytes { (pointer: UnsafeMutablePointer<UInt8>) in
                curve25519_derive_public_key(pointer, privateKeyBytes)
            }
        }
        assert(publicKey.count == TunnelConfiguration.keyLength)
        return publicKey
    }
}

extension InterfaceConfiguration {
    var publicKey: Data {
        return Curve25519.generatePublicKey(fromPrivateKey: privateKey.rawValue)
    }
}

