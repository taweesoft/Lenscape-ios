//
//  AppDelegate.swift
//  Lenscape
//
//  Created by TAWEERAT CHAIMAN on 4/3/2561 BE.
//  Copyright © 2561 Lenscape. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import os.log
import GoogleMaps
import GooglePlaces
import Firebase
import SwiftyJSON

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static let GOOGLE_API_KEY = "AIzaSyCCeMmQpPef8iidgKcLQ7rGmWHOZfXGtg4"
    
    var window: UIWindow?
    
    //added these 3 methods
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Use google api key for maps service
        GMSServices.provideAPIKey(AppDelegate.GOOGLE_API_KEY)
        GMSPlacesClient.provideAPIKey(AppDelegate.GOOGLE_API_KEY)
        
        // Firebase
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        let changeViewController = { (identifier: Identifier) -> Void in
            let storyBoard = UIStoryboard.init(name: "Main", bundle: nil)
            let navigationController = (self.window?.rootViewController as? UINavigationController)
            let vc = storyBoard.instantiateViewController(withIdentifier: identifier.rawValue)
            navigationController?.pushViewController(vc, animated: false)
        }
        if UserController.getCurrentUser() != nil {
            changeViewController(.MainTabBarController)
        }
        UserController.isLoggedIn().catch { error in
            changeViewController(.SigninViewController)
            os_log("User is not signed in", log: .default, type: .debug)
        }
        
        //Facebook
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    //https://stackoverflow.com/questions/49565775/facebook-sdk-access-token-issue-with-xcode-9-3
    // Fix crash in xcode 9.3 and iOS 11.3
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(app,
                                                                     open: url,
                                                                     sourceApplication: options[.sourceApplication] as! String,
                                                                     annotation: options[.annotation])
    }
    
    //----
    //Unlock rotation for specific View Controller
    //https://medium.com/@sunnyleeyun/swift-100-days-project-24-portrait-landscape-how-to-allow-rotate-in-one-vc-d717678301c1
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if let rootViewController = self.topViewControllerWithRootViewController(rootViewController: window?.rootViewController) {
            if (rootViewController.responds(to: Selector(("canRotate")))) {
                // Unlock landscape view orientations for this view controller
                return .allButUpsideDown;
            }
        }
        
        // Only allow portrait (standard behaviour)
        return .portrait;
    }
    
    private func topViewControllerWithRootViewController(rootViewController: UIViewController!) -> UIViewController? {
        if (rootViewController == nil) { return nil }
        if (rootViewController.isKind(of: UITabBarController.self)) {
            return topViewControllerWithRootViewController(rootViewController: (rootViewController as! UITabBarController).selectedViewController)
        } else if (rootViewController.isKind(of: UINavigationController.self)) {
            return topViewControllerWithRootViewController(rootViewController: (rootViewController as! UINavigationController).visibleViewController)
        } else if (rootViewController.presentedViewController != nil) {
            return topViewControllerWithRootViewController(rootViewController: rootViewController.presentedViewController)
        }
        return rootViewController
    }
    //-----
    
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        switch UIApplication.shared.applicationState {
        case .active:
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "ForegroundNotificationReceived"),
                object: nil,
                userInfo: userInfo
            )
        case .inactive:
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "BackgroundNotificationReceived"),
                object: nil,
                userInfo: userInfo
            )
        case .background:
            break

        }
        completionHandler(UIBackgroundFetchResult.newData)
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        // TODO: If necessary send token to application server.
        Messaging.messaging().subscribe(toTopic: "photoOfTheDay")
        Messaging.messaging().subscribe(toTopic: "weeklyInsights")
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
}

