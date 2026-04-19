//
//  sleepApp.swift
//  sleep
//
//  Created by lizhanbing12 on 17/11/25.
//

import SwiftUI

@main
struct sleepApp: App {
    @StateObject private var store = SleepStore()
    @StateObject private var soundscapeEngine = SoundscapeEngine()

    var body: some Scene {
        WindowGroup {
            Group {
                if let previewScreen = AppLaunchPreview.current {
                    AppLaunchPreviewRootView(screen: previewScreen)
                } else if store.hasCompletedOnboarding {
                    RootTabView()
                } else {
                    NavigationStack {
                        OnboardingView()
                    }
                }
            }
            .tint(SleepTheme.accent)
            .environmentObject(store)
            .environmentObject(soundscapeEngine)
            .preferredColorScheme(.dark)
        }
    }
}
