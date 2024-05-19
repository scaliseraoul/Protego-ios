//
//  AppDelegate.swift
//  Protego-Test
//
//  Created by Raoul Scalise on 19/05/24.
//

import Foundation
import UIKit
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    func applicationWillTerminate(_ application: UIApplication) {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
