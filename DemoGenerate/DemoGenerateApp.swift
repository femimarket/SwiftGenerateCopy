//
//  DemoGenerateApp.swift
//  DemoGenerate
//
//  Created by u on 06/06/2026.
//

import SwiftUI

@main
struct DemoGenerateApp: App {
    init() {
        OnboardingAudio.shared.prepare(resource: "onboarding", ext: "wav")
    }

    var body: some Scene {
        WindowGroup {
            // Standalone build owns the NavigationStack; when imported, the
            // parent app's NavigationStack hosts ContentView instead.
            NavigationStack {
                ContentView()
            }
            .preferredColorScheme(.dark)
        }
    }
}
