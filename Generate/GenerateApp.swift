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
        let bearer = "eyJraWQiOiI1UkZPU2lOSVVtIiwiYWxnIjoiUlMyNTYifQ.eyJpc3MiOiJodHRwczovL2FwcGxlaWQuYXBwbGUuY29tIiwiYXVkIjoibWFya2V0LmZlbWkiLCJleHAiOjE3ODAzMzcwMjYsImlhdCI6MTc4MDI1MDYyNiwic3ViIjoiMDAwNTM5LjFjMGFhZmZlY2NjNTQwNjI5ODc1OTliMDEwM2U2ZWNkLjExMTEiLCJjX2hhc2giOiJfN1Y3ZVFJQjl1Ym56aHlMMWhWd2lnIiwiZW1haWwiOiJidXNpbmVzc0BmZW1pLm1hcmtldCIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJhdXRoX3RpbWUiOjE3ODAyNTA2MjYsIm5vbmNlX3N1cHBvcnRlZCI6dHJ1ZX0.JmZ60GAxdjHNQDtesKZ0kIxwF5hRu-Y6cwAIX8SRhXx8HaC6ZY0Pcezwaeffz-39o4K9JN6J-wWYAgGeT5klBc8eKOBVtRFTrXnzBu9udi5QXYaXYP0SMo-gTZ3SE83IhVux8XCcpxSUQpSO4Ar8BYeABYSIohi1cxBwK4a4bzWwUpEhB9wRTQIDxjjj1YTeL9Sif1eTi4S8jJSzI1nUxh5IvMJmKY4E10ItPCHBbkxhu4aS9KCVx8H3G5R8GbFnCF9lnuahKCWpuoHViZgKwyVe2IyhtSjIRI_Ps8e44S89SulP0uanTeM0Z9GrI-50sqSyxAqenWyWvl16mUKddg"
        ApiAPIConfiguration.shared.customHeaders["Authorization"] = "Bearer \(bearer)"
        AppAuth.bearer = bearer
        // Apple `sub` from the JWT — server user id.
        AppAuth.userId = "000539.1c0aaffeccc54062987599b0103e6ecd.1111"
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


