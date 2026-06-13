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

/// Standalone host for Generate2. Bridges Generate2's `onTopupNeeded` async
/// closure to a SwiftUI sheet using a CheckedContinuation — the same shape
/// the real parent app will use, just with a dummy sheet so we can see the
/// integration in action without StoreKit / parent infra.
private struct AppRoot: View {
    @State private var bridge = TopupBridge()

    var body: some View {
        ContentView(
            tokenid: "019ec07a-c943-7275-b758-2315b8c9fa6f",
            onTopupNeeded: { await bridge.request() }
        )
        .sheet(isPresented: $bridge.showSheet, onDismiss: bridge.resolveAsFailureIfPending) {
            DummyParentTopupSheet(
                onSuccess: { bridge.resolve(true) },
                onCancel: { bridge.resolve(false) }
            )
        }
    }
}

/// Async-to-sheet bridge. Stores the continuation while the sheet is up,
/// resolves it once when either branch (success / cancel / swipe-down) fires.
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

    /// onDismiss fallback — if the user swipes the sheet down without tapping
    /// either explicit button, resolve as failure so the caller can move on.
    func resolveAsFailureIfPending() {
        guard let cont = continuation else { return }
        continuation = nil
        cont.resume(returning: false)
    }
}

/// Pretend parent topup UI. In prod this is the real purchase flow.
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
