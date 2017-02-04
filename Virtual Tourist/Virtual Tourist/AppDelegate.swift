//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Paul ReFalo on 12/21/16.
//  Copyright © 2016 QSS. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let stack = CoreDataStack(modelName: "Model")!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Get sql db path
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        print("Path for sqlite db is:")
        print(urls[urls.count - 1] as URL)
        
        // autoSave each minute from CoreDataStack
        stack.autoSave(60)

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        stack.save()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        stack.save()
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


}

extension AppDelegate {
    
    // MARK: Clear Data
    
    func clearData() {
        do {
            try stack.dropAllData()
        } catch let error as NSError {
            print("Error dropping all objects in DB")
            print(error.localizedDescription)
        }
    }

}
