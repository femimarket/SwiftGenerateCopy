//
//  Song.swift
//  Generate
//
//  Song-pick screen. Two autoscrolling album strips run along the edges of
//  the phone; the gap between them frames a centerpiece "vinyl" slot. The
//  empty slot reads as "your song goes here" without needing instructions.
//
//  Flow: tap vinyl -> system file importer -> simulated upload (1.5s) ->
//  preview state (vinyl spins, song loops, name shown) -> "Use this song"
//  hands a PickedSong to the parent.
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Local theme (kept file-local so Song.swift stands on its own)

fileprivate enum SongTheme {
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

fileprivate struct SongAccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 32)
            .background(SongTheme.accent, in: .capsule)
            .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
            .shadow(color: SongTheme.accentMagenta.opacity(0.35), radius: 18, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7),
                       value: configuration.isPressed)
    }
}

// MARK: - Bundle image helper
// The strip imagery lives as loose PNGs in the bundle (img1.png, etc.) as
// well as a few uuid-named files. UIImage(named:) finds both asset-catalog
// and loose bundle resources.

fileprivate func bundleImage(_ name: String) -> Image {
    if let ui = UIImage(named: name) {
        return Image(uiImage: ui)
    }
    if let path = Bundle.main.path(forResource: name, ofType: "png"),
       let ui = UIImage(contentsOfFile: path) {
        return Image(uiImage: ui)
    }
    return Image(systemName: "music.note")
}

// MARK: - SongView

struct SongView: View {

    struct PickedSong: Equatable {
        let displayName: String
        /// Simulated server filename. Real upload comes later — for now we
        /// pretend `/audio` accepted the bytes and gave us this back.
        let serverFile: String
    }

    let onComplete: (PickedSong) -> Void

    enum Phase: Equatable {
        case initial
        case uploading(name: String)
        case preview(name: String, url: URL)
    }

    @State private var phase: Phase = .initial
    @State private var isPresentingPicker = false
    @State private var player: AVAudioPlayer?
    @State private var scopedURL: URL?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let stripImages = [
        "img1", "img2", "img3", "img4",
        "019e7f3d-7bff-7901-ac73-8c7372b56330",
        "019e7f3d-a3c0-7e63-a239-d84846529654",
        "019e7f3d-aa21-7173-86ae-fbe8d61d0a84",
        "90", "91", "93",
    ]

    var body: some View {
        ZStack {
            SongTheme.background.ignoresSafeArea()

            // Two autoscrolling album strips with a focal gap in the middle.
            HStack(spacing: 0) {
                AlbumStrip(images: stripImages,
                           direction: .up,
                           animating: !reduceMotion)
                    .frame(maxWidth: .infinity)
                Color.clear.frame(width: centerGap)
                AlbumStrip(images: Array(stripImages.reversed()),
                           direction: .down,
                           animating: !reduceMotion)
                    .frame(maxWidth: .infinity)
            }
            .ignoresSafeArea()

            // Edge + top/bottom vignettes pull the eye into the middle.
            LinearGradient(
                colors: [.black.opacity(0.75), .clear, .clear, .black.opacity(0.75)],
                startPoint: .leading, endPoint: .trailing
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            LinearGradient(
                colors: [.black.opacity(0.8), .clear, .clear, .black.opacity(0.8)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 28) {
                Text("Your song")
                    .font(.system(.title2, design: .serif).weight(.semibold))
                    .foregroundStyle(SongTheme.onSurface)
                    .shadow(color: .black.opacity(0.5), radius: 8, y: 2)

                centerSlot
            }
            .padding(.horizontal, 24)
        }
        .fileImporter(
            isPresented: $isPresentingPicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            handlePickResult(result)
        }
        .onDisappear {
            stopPreview()
            releaseScope()
        }
    }

    private var centerGap: CGFloat { 260 }

    // MARK: Center slot

    @ViewBuilder
    private var centerSlot: some View {
        ZStack {
            if case .initial = phase {
                initialView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            if case .uploading(let name) = phase {
                uploadingView(name: name)
                    .transition(.opacity)
            }
            if case .preview(let name, _) = phase {
                previewView(name: name)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: phase)
    }

    private var initialView: some View {
        VStack(spacing: 18) {
            vinylButton(spinning: false, busy: false)
            Text("Tap to add your song")
                .font(.subheadline)
                .foregroundStyle(SongTheme.muted)
        }
    }

    private func uploadingView(name: String) -> some View {
        VStack(spacing: 18) {
            vinylButton(spinning: false, busy: true)
            Text(name)
                .font(.subheadline)
                .foregroundStyle(SongTheme.muted)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func previewView(name: String) -> some View {
        VStack(spacing: 20) {
            vinylButton(spinning: !reduceMotion, busy: false)
            Text(name)
                .font(.headline)
                .foregroundStyle(SongTheme.onSurface)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Use this song") { confirm(name: name) }
                .buttonStyle(SongAccentButtonStyle())
            Button("Pick a different one") {
                stopPreview()
                releaseScope()
                phase = .initial
                isPresentingPicker = true
            }
            .font(.footnote)
            .foregroundStyle(SongTheme.muted)
        }
    }

    private func vinylButton(spinning: Bool, busy: Bool) -> some View {
        Button {
            if case .initial = phase { isPresentingPicker = true }
        } label: {
            VinylSlot(spinning: spinning)
                .overlay {
                    if busy {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled({
            if case .initial = phase { return false } else { return true }
        }())
    }

    // MARK: Pick handling

    private func handlePickResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            // Hold the security scope until we either confirm or pick again.
            if url.startAccessingSecurityScopedResource() {
                scopedURL = url
            }
            let name = url.deletingPathExtension().lastPathComponent
            phase = .uploading(name: name)

            Task { @MainActor in
                // Simulated server upload latency.
                try? await Task.sleep(for: .milliseconds(1500))
                phase = .preview(name: name, url: url)
                startPreview(url: url)
            }
        case .failure:
            phase = .initial
        }
    }

    private func confirm(name: String) {
        stopPreview()
        releaseScope()
        // Pretend the server gave us this back from /audio upload.
        let simulatedFilename = "audio/\(UUID().uuidString).m4a"
        onComplete(PickedSong(displayName: name, serverFile: simulatedFilename))
    }

    private func releaseScope() {
        scopedURL?.stopAccessingSecurityScopedResource()
        scopedURL = nil
    }

    // MARK: Audio preview

    private func startPreview(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient, mode: .default, options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.volume = 0
            p.prepareToPlay()
            p.play()
            p.setVolume(0.7, fadeDuration: 0.5)
            player = p
        } catch {
            // Preview is nice-to-have. Don't block the flow if it fails.
        }
    }

    private func stopPreview() {
        guard let p = player else { return }
        p.setVolume(0, fadeDuration: 0.3)
        let captured = p
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            captured.stop()
            try? AVAudioSession.sharedInstance().setActive(
                false, options: [.notifyOthersOnDeactivation]
            )
        }
        player = nil
    }
}

// MARK: - Album strip (autoscrolling column)

private struct AlbumStrip: View {
    enum Direction { case up, down }
    let images: [String]
    let direction: Direction
    let animating: Bool

    private let cellHeight: CGFloat = 240
    private let spacing: CGFloat = 14
    private let period: Double = 34   // seconds per full loop

    var body: some View {
        GeometryReader { geo in
            let totalHeight = CGFloat(images.count) * (cellHeight + spacing)
            TimelineView(.animation(minimumInterval: 1.0 / 60)) { context in
                let t = animating
                    ? context.date.timeIntervalSinceReferenceDate
                    : 0
                let phase = (t.truncatingRemainder(dividingBy: period)) / period
                let signed = direction == .up ? -phase : phase
                let baseOffset = CGFloat(signed) * totalHeight

                VStack(spacing: spacing) {
                    // Triple the strip so the loop seam is always off-screen.
                    ForEach(0..<3, id: \.self) { _ in
                        ForEach(Array(images.enumerated()), id: \.offset) { _, name in
                            bundleImage(name)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: cellHeight)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .opacity(0.78)
                        }
                    }
                }
                .offset(y: baseOffset - totalHeight)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Vinyl slot (the focal centerpiece)

private struct VinylSlot: View {
    let spinning: Bool
    private let size: CGFloat = 220

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let rotationDegrees = spinning
                ? (t.truncatingRemainder(dividingBy: 6.0) / 6.0) * 360.0
                : 0
            // Subtle breathing pulse on the halo, derived from time so it
            // doesn't fight other state animations.
            let pulseScale = 1.0 + 0.06 * sin(t * 2 * .pi / 1.6)

            ZStack {
                // Halo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                SongTheme.accentMagenta.opacity(0.55),
                                SongTheme.accentBlue.opacity(0.25),
                                .clear,
                            ],
                            center: .center,
                            startRadius: 40, endRadius: 180
                        )
                    )
                    .blur(radius: 22)
                    .scaleEffect(pulseScale)

                // Vinyl body + grooves
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.04, green: 0.04, blue: 0.06),
                                    Color(red: 0.10, green: 0.10, blue: 0.14),
                                ],
                                center: .center,
                                startRadius: 2, endRadius: size / 2
                            )
                        )
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .stroke(.white.opacity(0.04), lineWidth: 1)
                            .padding(CGFloat(i) * 12 + 12)
                    }
                    Circle()
                        .stroke(SongTheme.accent, lineWidth: 1.5)
                }
                .rotationEffect(.degrees(rotationDegrees))

                // Center label
                Circle()
                    .fill(SongTheme.accent)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .fill(SongTheme.background)
                            .frame(width: 12, height: 12)
                    )
                    .rotationEffect(.degrees(rotationDegrees))
            }
            .frame(width: size, height: size)
        }
    }
}
