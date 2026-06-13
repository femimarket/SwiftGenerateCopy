//
//  Generate2App.swift
//  Generate2
//
//  Created by u on 13/06/2026.
//

import SwiftUI

@main
struct Generate2App: App {
    var body: some Scene {
        WindowGroup {
            AppRoot()
        }
    }
}

/// Standalone host for Generate2. Owns the NavigationStack the way the real
/// parent app will, bridges Generate2's `onTopupNeeded` async closure to a
/// dummy sheet, and provides a dummy "team derive view" so the full Normal →
/// Team → Derive flow is exercisable without the team's actual package.
private struct AppRoot: View {
    @State private var bridge = TopupBridge()
    @State private var path: [Route] = []
    @State private var presentingSongPicker = false

    private let tokenid = "019ec07a-c943-7275-b758-2315b8c9fa6f"

    var body: some View {
        NavigationStack(path: $path) {
            ContentView(
                tokenid: tokenid,
                onTopupNeeded: { await bridge.request() },
                onImageTapped: { imagePath in
                    path.append(.teamDerive(imagePath: imagePath))
                },
                onUploadSong: { presentingSongPicker = true }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .teamDerive(let imagePath):
                    DummyTeamDeriveView(imagePath: imagePath) { tweak in
                        // Submit: pop the team view, push Generate2 in derive mode.
                        let filename = URL(fileURLWithPath: imagePath).lastPathComponent
                        path.removeLast()
                        path.append(.generate2Derive(filename: filename, tweak: tweak))
                    }
                case .generate2Derive(let filename, let tweak):
                    ContentView(
                        tokenid: tokenid,
                        onTopupNeeded: { await bridge.request() },
                        onImageTapped: { imagePath in
                            path.append(.teamDerive(imagePath: imagePath))
                        },
                        onUploadSong: { presentingSongPicker = true },
                        filename: filename,
                        tweak: tweak
                    )
                }
            }
        }
        .sheet(isPresented: $bridge.showSheet, onDismiss: bridge.resolveAsFailureIfPending) {
            DummyParentTopupSheet(
                onSuccess: { bridge.resolve(true) },
                onCancel: { bridge.resolve(false) }
            )
        }
        .sheet(isPresented: $presentingSongPicker) {
            DummySongPickerSheet(onClose: { presentingSongPicker = false })
        }
    }
}

/// Pretend version of the parent's song-picker. Real parent app presents its
/// own audio-import sheet here.
private struct DummySongPickerSheet: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            Image(systemName: "music.note")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.purple)
            Text("Parent song picker (dummy)")
                .font(.title2.bold())
            Text("Real parent app shows its audio-import sheet here.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("Done", action: onClose)
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 16)
        .presentationDetents([.medium])
    }
}

/// Parent-side routing vocabulary. Lives entirely in the parent — Generate2
/// has no awareness of these cases.
private enum Route: Hashable {
    case teamDerive(imagePath: String)
    case generate2Derive(filename: String, tweak: String)
}

/// Pretend version of the team's "Change it" screen. Real parent app pushes
/// the team's package view here instead.
private struct DummyTeamDeriveView: View {
    let imagePath: String
    let onSubmit: (String) -> Void
    @State private var tweak: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Source path: \(imagePath)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            TextField("Tell me what to change", text: $tweak, axis: .vertical)
                .focused($focused)
                .font(.body)
                .lineLimit(3...8)
                .padding(16)
                .background(.gray.opacity(0.15), in: .rect(cornerRadius: 16))
                .padding(.horizontal, 16)
            Spacer()
        }
        .navigationTitle("Team derive view (dummy)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = true }
        .safeAreaInset(edge: .bottom) {
            Button("Submit (dummy)") {
                onSubmit(tweak.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .buttonStyle(.borderedProminent)
            .disabled(tweak.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding()
        }
    }
}

/// Async-to-sheet bridge for the dummy topup. Same shape the real parent
/// app's StoreKit flow will use.
@MainActor @Observable
private final class TopupBridge {
    var showSheet = false
    private var continuation: CheckedContinuation<Bool, Never>?

    func request() async -> Bool {
        await withCheckedContinuation { cont in
            Task { @MainActor in
                self.continuation = cont
                self.showSheet = true
            }
        }
    }

    func resolve(_ success: Bool) {
        guard let cont = continuation else { return }
        continuation = nil
        cont.resume(returning: success)
        showSheet = false
    }

    func resolveAsFailureIfPending() {
        guard let cont = continuation else { return }
        continuation = nil
        cont.resume(returning: false)
    }
}

private struct DummyParentTopupSheet: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Capsule().fill(.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            Image(systemName: "creditcard.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.blue)
            Text("Parent topup (dummy)")
                .font(.title2.bold())
            Text("Pretend the parent app is showing its own purchase flow here.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("Pretend purchase succeeded") {
                onSuccess()
            }
            .buttonStyle(.borderedProminent)
            Button("Cancel", role: .cancel) {
                onCancel()
            }
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 16)
        .presentationDetents([.medium])
    }
}
