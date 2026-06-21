//
//  ContentView.swift
//  Dev
//
//  Two mini-apps presented as large iPhone-style squircle icons, centered
//  on a dark wallpaper. Layout is sized for the real content, not padded
//  to fit a 4-column grid.
//

import SwiftUI

private enum Theme {
    static let magenta = Color(red: 1.0,   green: 0.169, blue: 0.839)
    static let pink    = Color(red: 1.0,   green: 0.376, blue: 0.557)
    static let blue    = Color(red: 0.227, green: 0.627, blue: 1.0)
    static let violet  = Color(red: 0.498, green: 0.243, blue: 0.949)
}

private struct MiniApp: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let primary: Color
    let secondary: Color
}

struct ContentView: View {
    private let apps: [MiniApp] = [
        .init(name: "Character",
              icon: "person.crop.square.filled.and.at.rectangle",
              primary: Theme.magenta, secondary: Theme.pink),
        .init(name: "Lyrics",
              icon: "text.alignleft",
              primary: Theme.blue, secondary: Theme.violet),
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 28),
        GridItem(.flexible(), spacing: 28),
    ]

    var body: some View {
        ZStack {
            Wallpaper()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 36) {
                    ForEach(apps) { HomeIcon(app: $0) }
                }
                .padding(.horizontal, 28)
                .padding(.top, 88)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Wallpaper

private struct Wallpaper: View {
    var body: some View {
        ZStack {
            Color(red: 0.027, green: 0.027, blue: 0.055)
            RadialGradient(
                colors: [Color(red: 0.20, green: 0.10, blue: 0.36).opacity(0.90), .clear],
                center: .init(x: 0.30, y: 0.25),
                startRadius: 40, endRadius: 540
            )
            RadialGradient(
                colors: [Color(red: 0.05, green: 0.10, blue: 0.28).opacity(0.85), .clear],
                center: .init(x: 0.80, y: 0.78),
                startRadius: 40, endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Hero home icon

private struct HomeIcon: View {
    let app: MiniApp

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 14) {
                AppIcon(app: app)
                Text(app.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(HomeIconStyle())
    }
}

private struct HomeIconStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.86 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.7),
                       value: configuration.isPressed)
    }
}

// MARK: - Squircle app icon

private struct AppIcon: View {
    let app: MiniApp

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [app.primary, app.secondary],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.32), .clear],
                        startPoint: .top, endPoint: .center
                    )
                )
                .blendMode(.plusLighter)
            Image(systemName: app.icon)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.28), radius: 8, y: 3)
        }
        .frame(width: 124, height: 124)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.22), lineWidth: 0.7)
        )
        .shadow(color: app.primary.opacity(0.55), radius: 28, y: 14)
        .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
    }
}

#Preview {
    ContentView()
}
