//
//  SceneDelegate.swift
//  BLRTransitApp
//
//  Scene lifecycle management
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("🚀 Scene willConnectTo called")
        
        guard let windowScene = (scene as? UIWindowScene) else {
            print("❌ Failed to get windowScene")
            return
        }
        
        print("✅ Got windowScene")
        
        // Create and configure the window
        let window = UIWindow(windowScene: windowScene)
        
        // Set the main view controller
        print("📱 Creating MainViewController...")
        let mainVC = MainViewController()
        print("✅ MainViewController created")
        
        window.rootViewController = mainVC
        
        self.window = window
        window.makeKeyAndVisible()
        print("✅ Window made key and visible")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
