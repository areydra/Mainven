//
//  MainvenApp.swift
//  Mainven
//
//  Created by Areydra Desfikriandre on 7/19/25.
//

import SwiftUI
import CoreData // Import CoreData for NSManagedObjectID

struct ManagedObjectIDWrapper: Identifiable {
    let id: NSManagedObjectID
}

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
