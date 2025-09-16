//
//  QRCodeApp.swift
//  QRCode
//
//  Created by 邵文萱(ShaoWenxuan)-顺丰科技技术集团 on 2024/12/23.
//

import SwiftUI
import CoreData

@main
struct QRCodeApp: App {
    let persistentContainer = CoreDataStack.shared.persistentContainer

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistentContainer.viewContext)
                .environmentObject(CoreDataStack.shared)
        }
    }
}
