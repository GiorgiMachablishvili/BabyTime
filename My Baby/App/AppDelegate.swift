//
//  AppDelegate.swift
//  My Baby
//
//  Created by Gio's Mac on 23.12.25.
//

import UIKit
import CoreData
import UserNotifications

private let feedingReminderOpenIdKey = "FeedingReminderOpenReminderId"

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Show the banner even while the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Sleep-in-progress notification: suppress sound/badge while foregrounded;
        // just keep the list entry so the lock-screen banner stays available.
        let id = notification.request.identifier
        if id == "sleepInProgressNotification" || id == "breastFeedingTimerNotification" {
            // Timer notifications: suppress banner while app is foreground (in-app UI shows instead)
            completionHandler([.list])
        } else {
            completionHandler([.banner, .sound, .list])
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let actionID  = response.actionIdentifier
        let userInfo  = response.notification.request.content.userInfo

        // ── Sleep timer actions ───────────────────────────────────────────
        switch actionID {
        case "PAUSE_SLEEP":
            NotificationCenter.default.post(name: .sleepTimerShouldPause, object: nil)
        case "RESUME_SLEEP":
            NotificationCenter.default.post(name: .sleepTimerShouldResume, object: nil)
        case "STOP_SLEEP":
            // Post so the VC handles it if alive; direct save as a fallback.
            NotificationCenter.default.post(name: .sleepTimerShouldStop, object: nil)
            SleepTimerNotificationHandler.stopAndSaveIfNeeded()
        case "STOP_BREAST":
            // Same dual-path pattern for the breastfeeding timer.
            NotificationCenter.default.post(name: .breastTimerShouldStop, object: nil)
            BreastTimerNotificationHandler.stopAndSaveIfNeeded()
        default:
            break
        }

        // ── Feeding reminder / other actions ─────────────────────────────
        if let idStr = userInfo["reminderId"] as? String {
            UserDefaults.standard.set(idStr, forKey: feedingReminderOpenIdKey)
        }

        // Navigate to the correct tab when the user taps the banner body
        let category = response.notification.request.content.categoryIdentifier
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            if category.hasPrefix("SLEEP_") {
                navigateToSleepTab()
            } else if category == "BREAST_RUNNING" {
                navigateToFeedingTab()
            } else if userInfo["reminderId"] != nil {
                navigateToFeedingTab()
            }
        } else if userInfo["reminderId"] != nil {
            navigateToFeedingTab()
        }

        completionHandler()
    }

    // MARK: - Navigation helpers

    private func navigateToSleepTab() {
        guard let tabBar = keyTabBar() else { return }
        tabBar.selectedIndex = 2   // adjust if Sleep is on a different index
    }

    private func navigateToFeedingTab() {
        guard let tabBar = keyTabBar() else { return }
        tabBar.selectedIndex = 1
    }

    private func keyTabBar() -> MainTabBarController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
            .flatMap { $0.rootViewController as? MainTabBarController }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "My_Baby")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

