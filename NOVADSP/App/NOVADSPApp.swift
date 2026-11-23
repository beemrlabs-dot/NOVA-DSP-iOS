import SwiftUI
import UIKit
import CarPlay

@main
struct NOVADSPApp: App {
    @UIApplicationDelegateAdaptor(NovaAppDelegate.self) private var appDelegate
    var body: some Scene { WindowGroup { ContentView() } }
}

final class NovaAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if connectingSceneSession.role == CPTemplateApplicationSceneSessionRoleApplication {
            let configuration = UISceneConfiguration(name: "CarPlay", sessionRole: connectingSceneSession.role)
            configuration.delegateClass = NovaCarPlaySceneDelegate.self
            return configuration
        }
        return UISceneConfiguration(name: "iPhone", sessionRole: connectingSceneSession.role)
    }
}
