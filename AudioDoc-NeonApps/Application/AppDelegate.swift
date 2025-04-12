//
//  AppDelegate.swift
//  AudioDoc-NeonApps
//
//  Created by Kerem on 27.03.2025.
//

import UIKit
import NeonSDK
import Firebase
import FirebaseStorage

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Firebase konfigürasyonu
        print("Configuring Firebase...")
        FirebaseApp.configure()
        
        // Firebase Storage'a erişim testi
       
        
        Font.configureFonts(font: .Inter)
        
        Neon.configure(
            window: &window,
            onboardingVC: OnboardingViewController(),
            paywallVC: PaywallVC(),
            homeVC: TabBarController())

        return true
    }

   

}

