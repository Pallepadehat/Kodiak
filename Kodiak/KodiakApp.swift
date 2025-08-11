//
//  KodiakApp.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import SwiftUI
import SwiftData

@main
struct KodiakApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: Chat.self, ChatMessage.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
