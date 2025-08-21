//
//  FocusPlusApp.swift
//  FocusPlus
//
//  Created by Yasutaka Otsubo on 2025/08/22.
//

import SwiftUI

@main
struct FocusPlusApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
