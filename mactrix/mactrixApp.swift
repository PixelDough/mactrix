//
//  mactrixApp.swift
//  mactrix
//
//  Created by Annie Worrell on 8/6/25.
//

import SwiftUI

@main
struct mactrixApp: App {
    @State private var scrollToBottomTrigger: UUID = UUID()
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandMenu("Chat") {
                Button("Scroll to Bottom") {
                    NotificationCenter.default.post(name: .scrollToBottomTriggered, object: nil)
                }
                .keyboardShortcut(.downArrow, modifiers: .command)
            }
        }
    }
}


extension Notification.Name {
  static let scrollToBottomTriggered = Notification.Name("scrollToBottomTriggered")
}
