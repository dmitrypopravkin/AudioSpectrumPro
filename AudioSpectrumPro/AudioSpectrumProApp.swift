//
//  AudioSpectrumProApp.swift
//  AudioSpectrumPro
//
//  Created by Dmitry Popravkin on 11.04.2026.
//

import SwiftUI

@main
struct AudioSpectrumProApp: App {
    @StateObject private var langManager = LanguageManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(langManager)
        }
    }
}
