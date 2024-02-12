// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Foundation
import UIKit
import SwiftMessages

enum MessageDuration: Int {
    case indefinite = -1
    case short = 3
    case medium = 5
    case long = 8
}

enum MessageType {
    case success, error, info
}

extension SwiftMessages {
    static let noInternetConnetionMessageId = "NO_INTERNET_CONNECTION"

    static func show(type: MessageType, message: String, duration: MessageDuration, id: String? = nil) {
        var config = SwiftMessages.Config()
        config.presentationStyle = .top
        config.interactiveHide = true
        config.duration = duration == MessageDuration.indefinite ? .forever : .seconds(seconds: TimeInterval(duration.rawValue))

        let color = getColor(type: type)

        let view = SnackbarView(message: message, icon: getIcon(type: type), id: id, color: color)
        SwiftMessages.show(config: config, view: view)
    }

    private static func getIcon(type: MessageType) -> String {
        switch type {
        case MessageType.success:
            return "iconSuccess"
        case MessageType.error:
            return "iconError"
        case MessageType.info:
            return "iconInfo"
        }
    }

    private static func getBackgroundColor(type: MessageType) -> UIColor {
        switch type {
        case MessageType.success:
            return UIColor.snackbarSuccess
        case MessageType.error:
            return UIColor.snackbarError
        case MessageType.info:
            return UIColor.snackbarInfo
        }
    }

    private static func getColor(type: MessageType) -> UIColor {
        switch type {
        case MessageType.success:
            return UIColor.greenBright
        case MessageType.error:
            return UIColor.red2
        case MessageType.info:
            return UIColor.white
        }
    }
}

extension BaseView {
    func setTopMargin(_ margin: CGFloat) {
        layoutMarginAdditions.top = margin
    }
}
