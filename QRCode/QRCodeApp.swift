//
//  QRCodeApp.swift
//  QRCode
//
//  Created by 邵文萱(ShaoWenxuan)-顺丰科技技术集团 on 2024/12/23.
//

import SwiftUI
import SwiftData

@main
struct QRCodeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
