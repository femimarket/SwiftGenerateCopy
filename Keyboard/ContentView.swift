//
//  ContentView.swift
//  Keyboard
//
//  Scratchpad for isolated UI demos. Menu of demos:
//    1. Lyric paste sheet — keyboard handling iteration
//    2. Project switcher — Generate-tab "switch song" pattern, with the
//       REAL Song.swift code as the new-song flow (no mock).
//
//  The strip imagery in SongView uses bundled PNGs that ship in the Generate
//  target only. In this Keyboard target the `bundleImage` helper falls back
//  to a procedural gradient placeholder so the strips still look like strips.
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Theme (for menu + lyric harness)

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

private struct AccentButtonStyle: ButtonStyle {
    var fullWidth: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 0 : 28)
            .background(Theme.accent, in: .capsule)
            .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
            .shadow(color: Theme.accentMagenta.opacity(0.35), radius: 18, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7),
                       value: configuration.isPressed)
    }
}

// MARK: - Root menu

struct ContentView: View {
    enum Demo: String, Identifiable {
        case lyricSheet, projectSwitcher
        var id: String { rawValue }
    }

    @State private var presenting: Demo?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                VStack(spacing: 6) {
                    Text("Scratchpad")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Theme.onSurface)
                    Text("Isolated UI demos.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }
                VStack(spacing: 14) {
                    menuRow(
                        index: 1,
                        title: "Lyric paste sheet",
                        subtitle: "Keyboard handling iteration."
                    ) { presenting = .lyricSheet }

                    menuRow(
                        index: 2,
                        title: "Project switcher",
                        subtitle: "Generate-tab \u{201C}switch song\u{201D} pattern. Uses real Song.swift."
                    ) { presenting = .projectSwitcher }
                }
                .padding(.horizontal, 24)
                Spacer()
            }
        }
        .fullScreenCover(item: $presenting) { demo in
            switch demo {
            case .lyricSheet:
                LyricSheetDemo(onClose: { presenting = nil })
            case .projectSwitcher:
                ProjectSwitcherDemo(onClose: { presenting = nil })
            }
        }
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

// MARK: - Demo 1: Lyric paste sheet harness

private struct LyricSheetDemo: View {
    let onClose: () -> Void
    @State private var presentingSheet = false
    @State private var lastSaved: String = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Text("Lyric Paste Sheet")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.onSurface)
                Button("Open sheet") { presentingSheet = true }
                    .buttonStyle(AccentButtonStyle(fullWidth: false))
                if !lastSaved.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Last saved:")
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                        ScrollView {
                            Text(lastSaved)
                                .font(.footnote)
                                .foregroundStyle(Theme.onSurface)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(16)
                    .background(Theme.surface, in: .rect(cornerRadius: 12))
                    .padding(.horizontal, 24)
                }
                Spacer()
            }
            VStack {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.onSurface)
                            .padding(12)
                            .background(Theme.surface, in: .circle)
                    }
                    .padding(16)
                }
                Spacer()
            }
        }
        .sheet(isPresented: $presentingSheet) {
            LyricPasteSheet(
                save: { text in lastSaved = text },
                onClose: { presentingSheet = false }
            )
            .presentationDetents([.large])
            .presentationBackground(.regularMaterial)
        }
    }
}

private struct LyricPasteSheet: View {
    let save: (String) -> Void
    let onClose: () -> Void

    @State private var text: String = ""
    @FocusState private var focused: Bool

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Theme.background.ignoresSafeArea()

                TextEditor(text: $text)
                    .focused($focused)
                    .font(.body)
                    .foregroundStyle(Theme.onSurface)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .tint(Theme.accentMagenta)

                if text.isEmpty {
                    Text("Drop your lyrics here. One line at a time \u{2014} the way your song breathes.")
                        .font(.body.italic())
                        .foregroundStyle(Theme.muted)
                        .padding(.horizontal, 17)
                        .padding(.top, 16)
                        .padding(.trailing, 24)
                        .allowsHitTesting(false)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.justify.left")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                        Text("Your lyrics")
                            .font(.headline)
                            .foregroundStyle(Theme.onSurface)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        focused = false
                        onClose()
                    }
                    .foregroundStyle(Theme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        focused = false
                        save(trimmed)
                        onClose()
                    } label: {
                        Text("Save")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                trimmed.isEmpty
                                    ? AnyShapeStyle(Color.white.opacity(0.18))
                                    : AnyShapeStyle(Theme.accent)
                            )
                            .clipShape(.capsule)
                    }
                    .disabled(trimmed.isEmpty)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear { focused = true }
    }
}

// MARK: - Demo 2: Project switcher

private struct DemoProject: Identifiable, Hashable {
    let id: UUID
    let songName: String
    let imageCount: Int
    let videoCount: Int
    let colorSeed: Int
}

@MainActor @Observable
private final class DemoState {
    var projects: [DemoProject]
    var currentProjectId: UUID
    var presentingProjects = false
    var presentingNewSong = false

    init() {
        let initial = [
            DemoProject(id: UUID(), songName: "Midnight Bloom",
                        imageCount: 12, videoCount: 2, colorSeed: 0),
            DemoProject(id: UUID(), songName: "Cold Water (demo)",
                        imageCount: 6,  videoCount: 1, colorSeed: 1),
            DemoProject(id: UUID(), songName: "I Tried",
                        imageCount: 24, videoCount: 5, colorSeed: 2),
        ]
        self.projects = initial
        self.currentProjectId = initial[0].id
    }

    var currentProject: DemoProject {
        projects.first(where: { $0.id == currentProjectId }) ?? projects[0]
    }

    func switchTo(_ id: UUID) { currentProjectId = id }

    func addProject(_ name: String) {
        let new = DemoProject(
            id: UUID(),
            songName: name,
            imageCount: 0,
            videoCount: 0,
            colorSeed: projects.count
        )
        projects.append(new)
        currentProjectId = new.id
    }
}

private func gradient(forSeed seed: Int, offset: Int = 0) -> LinearGradient {
    let hue1 = Double(((seed * 47 + offset * 23) % 360 + 360) % 360) / 360
    let hue2 = Double(((seed * 47 + offset * 23 + 60) % 360 + 360) % 360) / 360
    return LinearGradient(
        colors: [
            Color(hue: hue1, saturation: 0.7, brightness: 0.55),
            Color(hue: hue2, saturation: 0.8, brightness: 0.4),
        ],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

private struct ProjectSwitcherDemo: View {
    let onClose: () -> Void
    @State private var state = DemoState()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                fakeGrid
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                        .foregroundStyle(Theme.muted)
                }
                ToolbarItem(placement: .principal) {
                    Button {
                        state.presentingProjects = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(state.currentProject.songName)
                                .font(.headline)
                                .foregroundStyle(Theme.onSurface)
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.muted)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $state.presentingProjects) {
                ProjectsSheet(state: state)
            }
            // Real Song.swift, full-screen as it appears in production.
            .fullScreenCover(isPresented: $state.presentingNewSong) {
                SongView { picked in
                    state.addProject(picked.displayName)
                    state.presentingNewSong = false
                }
            }
        }
    }

    private var fakeGrid: some View {
        let project = state.currentProject
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
        return ScrollView {
            if project.imageCount == 0 {
                VStack(spacing: 14) {
                    Spacer().frame(height: 80)
                    Image(systemName: "sparkles")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(Theme.muted)
                    Text("Nothing here yet.")
                        .font(.headline)
                        .foregroundStyle(Theme.onSurface)
                    Text("This is where the generate flow would land for a new song.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(0..<project.imageCount, id: \.self) { i in
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay { gradient(forSeed: project.colorSeed, offset: i) }
                    }
                }
                .padding(2)
            }
        }
    }
}

private struct ProjectsSheet: View {
    @Bindable var state: DemoState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    ForEach(state.projects) { project in
                        Button {
                            state.switchTo(project.id)
                            dismiss()
                        } label: {
                            row(project)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.surface)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Your songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.muted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            state.presentingNewSong = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Theme.accentMagenta)
                    }
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    @ViewBuilder
    private func row(_ project: DemoProject) -> some View {
        HStack(spacing: 14) {
            gradient(forSeed: project.colorSeed)
                .frame(width: 56, height: 56)
                .clipShape(.rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(project.songName)
                    .font(.headline)
                    .foregroundStyle(Theme.onSurface)
                Text("\(project.imageCount) pictures \u{00B7} \(project.videoCount) videos")
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
            if project.id == state.currentProjectId {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.accentMagenta)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: ============================================================
// MARK: - SongView (verbatim copy of the real Song.swift, just renamed
// MARK: - bundleImage fallback for the Keyboard target which doesn't
// MARK: - ship the loose-PNG strip imagery)
// MARK: ============================================================

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

// Keyboard target doesn't bundle the loose PNGs that Generate ships. Fall
// back to a deterministic gradient placeholder by hashing the name — the
// strip layout, motion, and vignette still demo correctly.
fileprivate struct StripPlaceholder: View {
    let name: String
    var body: some View {
        let h = abs(name.hashValue)
        let hue1 = Double(h % 360) / 360
        let hue2 = Double((h / 360) % 360) / 360
        LinearGradient(
            colors: [
                Color(hue: hue1, saturation: 0.75, brightness: 0.55),
                Color(hue: hue2, saturation: 0.85, brightness: 0.35),
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
}

struct SongView: View {

    struct PickedSong: Equatable {
        let displayName: String
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

    private func handlePickResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            if url.startAccessingSecurityScopedResource() {
                scopedURL = url
            }
            let name = url.deletingPathExtension().lastPathComponent
            phase = .uploading(name: name)

            Task { @MainActor in
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
        let simulatedFilename = "audio/\(UUID().uuidString).m4a"
        onComplete(PickedSong(displayName: name, serverFile: simulatedFilename))
    }

    private func releaseScope() {
        scopedURL?.stopAccessingSecurityScopedResource()
        scopedURL = nil
    }

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

private struct AlbumStrip: View {
    enum Direction { case up, down }
    let images: [String]
    let direction: Direction
    let animating: Bool

    private let cellHeight: CGFloat = 240
    private let spacing: CGFloat = 14
    private let period: Double = 34

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
                    ForEach(0..<3, id: \.self) { _ in
                        ForEach(Array(images.enumerated()), id: \.offset) { _, name in
                            StripPlaceholder(name: name)
                                .frame(width: geo.size.width, height: cellHeight)
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

private struct VinylSlot: View {
    let spinning: Bool
    private let size: CGFloat = 220

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let rotationDegrees = spinning
                ? (t.truncatingRemainder(dividingBy: 6.0) / 6.0) * 360.0
                : 0
            let pulseScale = 1.0 + 0.06 * sin(t * 2 * .pi / 1.6)

            ZStack {
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

#Preview { ContentView().preferredColorScheme(.dark) }
