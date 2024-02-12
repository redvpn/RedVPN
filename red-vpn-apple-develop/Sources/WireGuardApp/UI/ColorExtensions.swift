// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

extension UIColor {
    static var accent: UIColor {
        return UIColor(rgb: 0xd2b361)
    }
    static var backgroundDark: UIColor {
        return UIColor(rgb: 0x181818)
    }
    static var background: UIColor {
        return UIColor(rgb: 0x232323)
    }
    static var blackDrawer: UIColor {
        return UIColor(rgb: 0x272727)
    }
    static var blueBright: UIColor {
        return UIColor(rgb: 0x2d7ff9)
    }
    static var camel: UIColor {
        return UIColor(rgb: 0xc8a54a)
    }
    static var cameoSilk: UIColor {
        return UIColor(rgb: 0xe2dbcc)
    }
    static var charcoalGrey: UIColor {
        return UIColor(rgb: 0x515253)
    }
    static var greenBright: UIColor {
        return UIColor(rgb: 0x20C933)
    }
    static var jadeGreen: UIColor {
        return UIColor(rgb: 0x26ae46)
    }
    static var light: UIColor {
        return UIColor(rgb: 0x757575)
    }
    static var lightAzure: UIColor {
        return UIColor(rgb: 0xe9f0f1)
    }
    static var lightGray: UIColor {
        return UIColor(rgb: 0xd4d4d4)
    }
    static var lightBlue: UIColor {
        return UIColor(rgb: 0x9cc7ff)
    }
    static var lightGrayishOrange: UIColor {
        return UIColor(rgb: 0xf3ead4)
    }
    static var primaryDark: UIColor {
        return UIColor(rgb: 0x343434)
    }
    static var red2: UIColor {
        return UIColor(rgb: 0xbb0008)
    }
    static var snackbarError: UIColor {
        return UIColor(rgb: 0xb14343)
    }
    static var snackbarInfo: UIColor {
        return UIColor(rgb: 0x2b78af)
    }
    static var snackbarSuccess: UIColor {
        return UIColor(rgb: 0x5b9b5a)
    }
    static var brownGrey: UIColor {
        return UIColor(rgb: 0x858585)
    }

    private convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    private convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}
