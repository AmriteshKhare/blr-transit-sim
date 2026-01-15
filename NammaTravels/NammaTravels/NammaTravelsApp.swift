//
//  NammaTravelsApp.swift
//  NammaTravels
//
//  Main app entry point
//

import SwiftUI

@main
struct NammaTravelsApp: App {
    var body: some Scene {
        WindowGroup {
            MainViewControllerRepresentable()
                .ignoresSafeArea()
        }
    }
}

// UIKit wrapper for SwiftUI
struct MainViewControllerRepresentable: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> MainViewController {
        return MainViewController()
    }
    
    func updateUIViewController(_ uiViewController: MainViewController, context: Context) {
        // No updates needed
    }
}
