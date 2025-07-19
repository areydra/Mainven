//
//  MainvenApp.swift
//  Mainven
//
//  Created by Areydra Desfikriandre on 7/19/25.
//

import SwiftUI

@main
struct MainvenApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
