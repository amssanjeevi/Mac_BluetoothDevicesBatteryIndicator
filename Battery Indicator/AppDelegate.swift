//
//  AppDelegate.swift
//  Battery Indicator
//
//  Created by Mohanasundaram on 30/07/19.
//  Copyright © 2019 BitsByBits Inc. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    var statusBarButton: NSStatusItem?
    var dropDownMenu: NSMenu?
    var finalArray:[String] = []
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarButton = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
        guard let button = statusBarButton?.button else {
            alertDialogBox(alertTitle: "Oh no! No Space for me in Status Bar 😕", buttonTitle: "Okay", description: "Try clearing buttons already present in status bar.")
            return
        }
        button.image = NSImage(named: "StatusBarIcon")
        button.target = self
        button.action = #selector(listDropDown)
        button.acceptsFirstMouse(for: NSEvent())
    }
    
    @objc func listDropDown() {
        guard let _ = statusBarButton?.button else { return }
        setBlueToothDevicesBatteryStatus()
        dropDownMenu = NSMenu()
        dropDownMenu?.delegate = self
        if !finalArray.isEmpty {
            for eachDetail in finalArray where eachDetail.count > 0 {
                dropDownMenu!.addItem(withTitle: eachDetail, action: nil, keyEquivalent: "")
            }
        } else {
            dropDownMenu!.addItem(withTitle: "No Bluetooth Devices Found", action: nil, keyEquivalent: "")
        }
        dropDownMenu!.addItem(NSMenuItem.separator())
        dropDownMenu!.addItem(withTitle: "Quit", action: #selector(quitPressed), keyEquivalent: "")
        statusBarButton?.menu = dropDownMenu
    }
    
    func setBlueToothDevicesBatteryStatus() {
        let argument = String(format: "ioreg -k %@ |egrep -w \"%@\"", "BatteryPercent", "BatteryPercent|Product")
        shell("-c", argument)
    }
    
    @objc func quitPressed() {
        NSApp.terminate(self)
    }
    @discardableResult
    func shell(_ args: String...) -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()
        task.terminate()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        var output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        output = output.replacingOccurrences(of: "|", with: "")
        let outputAsArray = output.components(separatedBy: "\n")
        for eachOutput in outputAsArray {
            finalArray.append(eachOutput.trimmingCharacters(in: CharacterSet.whitespaces))
        }
        finalArray.removeLast()
        return output
    }
    
    func menuDidClose(_ menu: NSMenu) {
        statusBarButton?.menu = nil
        finalArray = []
    }
    
    func alertDialogBox(alertTitle: String, buttonTitle: String, description: String) {
        let alert: NSAlert = NSAlert()
        alert.messageText = alertTitle
        alert.informativeText = description
        alert.alertStyle = .informational
        alert.addButton(withTitle: buttonTitle)
        let runAlert = alert.runModal()
        if runAlert == NSApplication.ModalResponse.alertFirstButtonReturn {
            NSApp.terminate(nil)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Battery_Indicator")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
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
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}

