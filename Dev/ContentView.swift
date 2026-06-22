//
//  ContentView.swift
//  Dev
//
//  Editorial pattern ported from Keyboard scratchpad: dark background,
//  centered title block, scrollable list of surface cards with a gradient
//  numbered circle, title, subtitle, chevron.
//

import SwiftUI

private enum Theme {
    static let background = Color(red: 0.039, green: 0.039, blue: 0.071)
    static let surface    = Color(red: 0.090, green: 0.090, blue: 0.137)
    static let onSurface  = Color(red: 0.949, green: 0.949, blue: 0.969)
    static let muted      = Color.white.opacity(0.6)
    static let accentMagenta = Color(red: 1.0, green: 0.169, blue: 0.839)
    static let accentBlue    = Color(red: 0.227, green: 0.627, blue: 1.0)
    static let accent = LinearGradient(
        colors: [accentMagenta, accentBlue],
        startPoint: .leading, endPoint: .trailing
    )
}

private struct MiniApp: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
}

struct ContentView: View {
    private let apps: [MiniApp] = [
        MiniApp(title: "Character",
                subtitle: "Cast one face into every shot."),
        MiniApp(title: "Lyrics",
                subtitle: "Edit synced lyric lines."),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 6) {
                        Text("Mini-apps")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Theme.onSurface)
                        Text("Isolated tools.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 14) {
                        ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                            menuRow(index: index + 1,
                                    title: app.title,
                                    subtitle: app.subtitle) {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func menuRow(index: Int, title: String, subtitle: String,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 36, height: 36)
                    Text("\(index)")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.onSurface)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.muted)
            }
            .padding(16)
            .background(Theme.surface, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
