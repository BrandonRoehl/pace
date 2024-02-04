//
//  PaceApp.swift
//  Pace
//
//  Created by Brandon Roehl on 1/26/23.
//

import SwiftUI
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        GADMobileAds.sharedInstance().start()

        return true
    }
}

@main
struct PaceApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

extension UIApplication {
    var rootViewController: UIViewController? {
        return self.connectedScenes
            // Get all windows that are open
            .compactMap { w in w as? UIWindowScene }
            .flatMap(\.windows)
            // If there is a key window they sort to the start of the array
            .sorted { l, _ in l.isKeyWindow }
            // Convert all to root view controllers and grab the first
            .compactMap(\.rootViewController)
            .first
    }
}
