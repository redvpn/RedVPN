// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import UIKit
import os.log
import KYDrawerController
import Sentry

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var mainVC: MainViewController?
    var isLaunchedForSpecificAction = false
    static let tunnelName = "RedVPN"
    let onboardingKey = "onboardingCompleted"

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Force dark mode
        UIView.appearance().overrideUserInterfaceStyle = .dark

        Logger.configureGlobal(tagged: "APP", withFilePath: FileManager.logFileURL?.path)

        if let launchOptions = launchOptions {
            if launchOptions[.url] != nil || launchOptions[.shortcutItem] != nil {
                isLaunchedForSpecificAction = true
            }
        }

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .backgroundDark
        self.window = window

        let mainVC = MainViewController()
        let drawerVC = DrawerViewController()
        let drawerController = KYDrawerController(drawerDirection: .left, drawerWidth: 292)
        drawerController.mainViewController = mainVC
        drawerController.drawerViewController = drawerVC

        if UserDefaults.standard.bool(forKey: onboardingKey) {
            window.rootViewController = drawerController
        } else {
            let onboardingVC = OnboardingViewController()
            onboardingVC.onNextButtonTouched = {
                if onboardingVC.pageControl.currentPage == onboardingVC.pageCount - 1 {
                    let termsAndConditionsVC = TermsAndConditionsViewController()
                    termsAndConditionsVC.onAcceptButtonTouched = {
                        window.rootViewController = drawerController
                        UserDefaults.standard.set(true, forKey: self.onboardingKey)
                        onboardingVC.nextButton.setTitle(tr("onboardingComplete"), for: .normal)
                    }
                    window.rootViewController = termsAndConditionsVC
                } else {
                    onboardingVC.goToNextPage()
                    if onboardingVC.pageControl.currentPage == onboardingVC.pageCount - 1 {
                        onboardingVC.nextButton.setTitle(tr("onboardingComplete"), for: .normal)
                    }
                }
            }
            window.rootViewController = onboardingVC
        }
        window.makeKeyAndVisible()

        self.mainVC = mainVC

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        SentrySDK.start { options in
            options.dsn = "https://218d631878ce4858b899b9975f288efa@o1353527.ingest.sentry.io/4505071315976192"
            options.debug = true // Enabled debug when first installing is always helpful
            options.enableTracing = false
            // Example uniform sample rate: capture 100% of transactions for performance monitoring
            options.tracesSampleRate = 0.0
        }
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

        // If the tunnels manager is ready use it. If not, wait for it to be created...
        guard let tunnelsManager = mainVC?.tunnelsManager else {
            mainVC?.onTunnelsManagerReady = { tunnelsManager in
                TunnelImporter.updateFromFile(url: url, into: tunnelsManager) {
                    _ = FileManager.deleteFile(at: url)
                }
            }

            return true
        }

        TunnelImporter.updateFromFile(url: url, into: tunnelsManager) {
            _ = FileManager.deleteFile(at: url)
        }

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        mainVC?.refreshTunnelConnectionStatuses()

        // Starts monitoring network connectivity status changes
        ConnectivityManager.shared.startMonitoring()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        guard let allTunnelNames = mainVC?.allTunnelNames() else { return }
        application.shortcutItems = QuickActionItem.createItems(allTunnelNames: allTunnelNames)

        // Stops monitoring network connectivity status changes
        ConnectivityManager.shared.stopMonitoring()
    }

    func setMainVC() {
        guard let window = self.window else { return }

        let mainVC = MainViewController()
        let drawerVC = DrawerViewController()
        let drawerController = KYDrawerController(drawerDirection: .right, drawerWidth: 292)
        drawerController.mainViewController = mainVC
        drawerController.drawerViewController = drawerVC

        window.rootViewController = drawerController
        window.makeKeyAndVisible()

        self.mainVC = mainVC
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }

    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return !self.isLaunchedForSpecificAction
    }
}
