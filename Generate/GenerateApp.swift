//
//  GenerateApp.swift
//  Generate
//
//  Created by u on 31/05/2026.
//

import SwiftUI
import Api

@main
struct GenerateApp: App {
    init() {
        // TODO: replace with real Sign in with Apple flow.
        // Token expires ~2026-06-01.
        let bearer = "eyJraWQiOiIxRTZWaW9JYU5JIiwiYWxnIjoiUlMyNTYifQ.eyJpc3MiOiJodHRwczovL2FwcGxlaWQuYXBwbGUuY29tIiwiYXVkIjoibWFya2V0LmZlbWkiLCJleHAiOjE3ODA3NDIwMTcsImlhdCI6MTc4MDY1NTYxNywic3ViIjoiMDAwNTM5LjFjMGFhZmZlY2NjNTQwNjI5ODc1OTliMDEwM2U2ZWNkLjExMTEiLCJjX2hhc2giOiJLX3kwVXVqWTVsNVpkWVJkNlFpV1NBIiwiZW1haWwiOiJidXNpbmVzc0BmZW1pLm1hcmtldCIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJhdXRoX3RpbWUiOjE3ODA2NTU2MTcsIm5vbmNlX3N1cHBvcnRlZCI6dHJ1ZX0.NzqTgfP5Wgl7RlneH_K3H3bp7DQGEIoADc_ArKrPOfiMByV77ZydUju4zh-FIXJYDfYof7O-j1VCaK9l53oTLiuAalJ59PFM3pVbVFjn7_Y9B8BPfC5Gy1qQDUK59Rmab6rjDQw9G-T-TCYM6b7hZRzM1lVuKZUuqXm3mQbGRNIH4HxHRNqJnMKe7dv1Z2IKgFY_GUnp73GU6LNqVQiGboiCAVGnOkqKd-t-SYkgjpTx0FpV7nCOQFvwsVkF8IH6uBYo8TxdQrHwKpeJlBeCYXEFo7UHw22s_akeyQ7SG9wY5FRs43D5o_9Xi04C0uSpC_wXGimc1x474CZYaGLX6g"
        ApiAPIConfiguration.shared.customHeaders["Authorization"] = "Bearer \(bearer)"
        AppAuth.bearer = bearer
        // Apple `sub` from the JWT — server user id.
        AppAuth.userId = "000539.1c0aaffeccc54062987599b0103e6ecd.1111"
        // Prime the onboarding WAV off-main, right now at app launch. By
        // the time the user picks a song + taps "Use this song", the
        // AVAudioPlayer is sitting ready — the splash's `start()` call is
        // instant.
        OnboardingAudio.shared.prepare(resource: "onboarding", ext: "wav")
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

/// Coordinates the first-run flow: pick a song, then enter the Generate screen.
/// The picked song is held in memory only for now — the Generate flow doesn't
/// yet consume it; that wiring comes when the real `/audio` upload lands.
struct RootView: View {
    @State private var pickedSong: SongView.PickedSong?

    var body: some View {
        Group {
            if pickedSong == nil {
                SongView { song in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        pickedSong = song
                    }
                }
                .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
    }
}


