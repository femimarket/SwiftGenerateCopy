//
//  ContentView.swift
//  DemoGenerate
//
//  Single-file demo Generate journey.
//  The production view hierarchy + view model, bound to a demo
//  GenerateService that returns bundled assets after dwells matching
//  real generation timing. See DemoGenerate.md for the seam contract.
//

import SwiftUI
import AVKit
import AVFoundation
import PhotosUI
import Observation

// MARK: - Resource bundle

/// Bridges two build contexts: when compiled as a Swift Package, SwiftPM
/// auto-generates `Bundle.module` for declared resources; when compiled in
/// the standalone Xcode app target, `Bundle.main` holds the same files.
/// All resource lookups in this file go through this property so the code
/// works in both contexts without conditional call-sites.
extension Bundle {
    nonisolated static var demoResources: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return .main
        #endif
    }
}

// MARK: - Auth context (vestigial in demo build)

enum AppAuth {
    nonisolated(unsafe) static var bearer: String = ""
    nonisolated(unsafe) static var userId: String = "demo-user"
}

// MARK: - Dev seed flag

let devSeedEnabled = UserDefaults.standard.bool(forKey: "devSeedGrid")

// MARK: - Theme

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
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Media URL helper (bundle-resolved in demo build)

private enum Media {
    /// In the real build this constructs a femi.market URL; in the demo build
    /// it resolves bundled assets so the journey runs without a network.
    /// Looks in `Bundle.module` (the SPM-generated package bundle) so the
    /// library carries its own resources when imported by a host app.
    /// Tries the subdirectory first, falls back to the flattened root.
    static func url(_ filename: String) -> URL? {
        guard !filename.isEmpty else { return nil }
        let ns = filename as NSString
        let dir = ns.deletingLastPathComponent
        let base = ns.lastPathComponent as NSString
        let name = base.deletingPathExtension
        let ext = base.pathExtension.isEmpty ? "png" : base.pathExtension
        guard !name.isEmpty else { return nil }
        if !dir.isEmpty,
           let nested = Bundle.demoResources.url(
               forResource: name,
               withExtension: ext,
               subdirectory: dir
           ) {
            return nested
        }
        return Bundle.demoResources.url(forResource: name, withExtension: ext)
    }

    static var authHeaders: [String: String] { [:] }

    static let session: URLSession = .shared
}

// MARK: - Local models (client-side state)

struct GeneratedImage: Identifiable, Hashable, Sendable {
    enum Source: String, Sendable { case lyra, vega, luna, upload }
    let id: UUID
    let file: String
    let prompt: String
    let source: Source
    var lineIndex: Int? = nil
}

struct SongLine: Identifiable, Hashable, Sendable {
    let id: UUID
    let index: Int
    let text: String
    let startMs: Int
    let durationMs: Int
}

struct GeneratedVideo: Identifiable, Hashable, Sendable {
    let id: UUID
    let file: String
    let posterFile: String
    let sourceImageIds: [UUID]
    /// The lyric line this video starts at. A video can play through later
    /// lines, but in the grid it appears under the line it begins at — same
    /// pattern every timeline editor uses to anchor clips.
    var lineIndex: Int? = nil
}

struct PendingVideo: Identifiable, Hashable, Sendable {
    enum State: Hashable, Sendable { case working, failed }
    let id: UUID
    let sourceImageIds: [UUID]
    let posterFile: String
    var lineIndex: Int? = nil
    var state: State = .working
}

struct PendingImage: Identifiable, Hashable, Sendable {
    enum State: Hashable, Sendable { case working, failed }
    let id: UUID
    var state: State = .working
}

struct PendingGeneration: Identifiable, Hashable, Sendable {
    enum State: Hashable, Sendable { case working, failed }
    let id: UUID
    let lineIndex: Int?
    var state: State = .working
}

// MARK: - Cost / project models (mirror production-shape, demo-only fields)

struct Credit: Sendable, Hashable {
    let credits: Int64
}

struct Pricing: Sendable, Hashable {
    let chat: Int64
    let microPixLyra: Int64
    let microPixVega: Int64
    let nanoPixLuna: Int64
    let image: Int64
    let nanoRenSpica: Int64
    let gb: Int64
}

struct ProjectAudioLine: Hashable, Sendable {
    let line: String
}

struct Project: Identifiable, Hashable, Sendable {
    let id: UUID
    let audio: String
    let summary: String
    let audioLines: [ProjectAudioLine]

    init(
        id: UUID = UUID(),
        audio: String,
        summary: String,
        audioLines: [ProjectAudioLine] = []
    ) {
        self.id = id
        self.audio = audio
        self.summary = summary
        self.audioLines = audioLines
    }
}

// MARK: - Service contract

/// The single seam between demo and real. The view model talks to this and
/// nothing else for credit, pricing, projects, prompts, image gen, video gen,
/// and uploads.
protocol GenerateService: Sendable {
    func currentCredit() async throws -> Credit
    func currentPricing() async throws -> Pricing
    func allProjects() async throws -> [Project]
    func chatPrompt(_ seed: String) async throws -> String
    func chatDerive(priorPrompt: String, userTweak: String) async throws -> String
    func generateImageBatch(prompt: String) async -> [GeneratedImage]
    func registerImageForVideo(filename: String) async throws -> String
    func trimAndUploadAudioClip(
        sourceAudioFile: String,
        startMs: Int,
        durationMs: Int
    ) async throws -> String
    func generateVideo(
        imageFile: String,
        audioFile: String,
        prompt: String
    ) async throws -> String
    func uploadImageBinary(data: Data, suggestedName: String) async throws -> String
}

// MARK: - Demo upload cache

/// Bytes from the user's `PhotosPicker` upload live here keyed by the demo
/// filename so `AuthorizedImage` can render them. Tutorial/demo only — the
/// real path stores via the image upload endpoint.
@MainActor
enum DemoUploadCache {
    static var images: [String: UIImage] = [:]
}

// MARK: - Demo lyrics bundle (one source of truth)

/// Loads `line2.json`, `line3.json`, `line4.json` once at startup, dedups
/// shared boundary lines, filters bracketed language markers, and exposes
/// both the combined lyric text (for `pasteLyrics`) and the per-scene
/// starting line index (for tagging emitted images so videos land under the
/// line their scene starts at).
private enum DemoLyricsBundle {
    static var combinedText: String { computed.text }
    static var sceneStartLines: [String: Int] { computed.starts }

    private static let computed: (text: String, starts: [String: Int]) = compute()

    private static func compute() -> (text: String, starts: [String: Int]) {
        struct LyricEntry: Decodable { let text: String }
        let pairs: [(scene: String, file: String)] = [
            ("scene2", "line2"),
            ("scene3", "line3"),
            ("scene4", "line4"),
        ]
        var lines: [String] = []
        var starts: [String: Int] = [:]
        for (sceneFolder, fileName) in pairs {
            let resolved = Bundle.demoResources.url(
                forResource: fileName,
                withExtension: "json",
                subdirectory: sceneFolder
            ) ?? Bundle.demoResources.url(forResource: fileName, withExtension: "json")
            guard let url = resolved,
                  let data = try? Data(contentsOf: url),
                  let parsed = try? JSONDecoder().decode([LyricEntry].self, from: data)
            else { continue }
            var firstIndex: Int? = nil
            for entry in parsed {
                let trimmed = entry.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { continue }
                if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") { continue }
                let idx: Int
                if let existing = lines.firstIndex(of: trimmed) {
                    idx = existing
                } else {
                    lines.append(trimmed)
                    idx = lines.count - 1
                }
                if firstIndex == nil { firstIndex = idx }
            }
            if let firstIndex { starts[sceneFolder] = firstIndex }
        }
        return (lines.joined(separator: "\n"), starts)
    }
}

// MARK: - Demo service

/// Returns bundled assets after dwells that match the production p50 of each
/// call — image gen ~6s, video gen ~60s, credit fetch ~150ms. Credit drops
/// after one full cycle so the topup beat fires; `topUp()` short-circuits to a
/// completed purchase.
final class DemoGenerateService: GenerateService, @unchecked Sendable {

    /// A scene = a real generation run the developer captured: the three (or
    /// fewer) images the model produced, plus the video they ultimately made
    /// from those images. Each batch in the demo journey corresponds to one
    /// scene; any image the user picks for video resolves back to the scene's
    /// actual MP4. The ordering puts the richest scenes first so the opening
    /// batches always show three distinct pictures.
    private struct Scene {
        let folder: String
        let images: [String]
        let videos: [String]
    }

    private static let scenes: [Scene] = [
        Scene(
            folder: "scene2",
            images: [
                "3-Reve-oBS5B4Wg4ubzsday_1BZ6.png",
                "l2-v02-l2-v2-Yj9_2CjLrICLhL6uJ79M4.png",
                "l3-v06-z00yDt6six8eLU1NUPFUM.png",
            ],
            videos: ["scene2.mp4"]
        ),
        Scene(
            folder: "scene3",
            images: [
                "44-bJnsQqlVG-fwjWpK3thJR.png",
                "68-Ksc77hq3L1icbVwX1vCGV.png",
                "77-FalReve-lbN8SgdcInnOMnHWWtBHP.png",
            ],
            videos: ["90ae9086e053751d.mp4", "a40ae17b148485fd.mp4"]
        ),
        Scene(
            folder: "scene4",
            images: [
                "86-27rC0sbZG8cOYu1R1Sqdj.png",
                "106-FalFlux2Max-1Mfn7n6Pz0mGSSt6Jv4J3.png",
            ],
            videos: ["208427b7c5aa764d.mp4"]
        ),
        Scene(
            folder: "scene1",
            images: [
                "249-Reve-kRu_EgeylK3MKnm6Q3thm.png",
            ],
            videos: ["4a82106f6a255857.mp4"]
        ),
    ]

    private static func path(_ scene: Scene, _ file: String) -> String {
        "\(scene.folder)/\(file)"
    }


    private static let demoAudioFile = "demo.mp3"

    /// Dev knob: when true, dwells are compressed for fast iteration. Flip
    /// to `false` before ship and the real production p50 timings take over
    /// (image gen ~6s, video gen ~60s, etc.).
    private static let fastIterationMode = true

    private static var imageGenSleep: Duration {
        fastIterationMode ? .milliseconds(600) : .seconds(6)
    }
    private static var videoGenSleep: Duration {
        // Demo dwell. Real backend p50 is ~60s; in a teaching demo a 60s
        // wait gates the third-act payoff (lyrics auto-paste + tab bar)
        // behind a wall of patience evaluators don't give. 12s is long
        // enough to read the async pattern (shimmer → keep working →
        // reveal), short enough that completion doesn't drop off.
        fastIterationMode ? .milliseconds(1500) : .seconds(12)
    }
    private static var chatSleep: Duration {
        fastIterationMode ? .milliseconds(200) : .milliseconds(1500)
    }
    private static var registerSleep: Duration {
        fastIterationMode ? .milliseconds(100) : .milliseconds(500)
    }
    private static var trimSleep: Duration {
        fastIterationMode ? .milliseconds(50) : .milliseconds(300)
    }
    private static var uploadSleep: Duration {
        fastIterationMode ? .milliseconds(200) : .milliseconds(800)
    }
    private static var quickFetchSleep: Duration {
        fastIterationMode ? .milliseconds(50) : .milliseconds(150)
    }

    private let lock = NSLock()
    private var sceneCursor = 0
    /// Image filename (with scene folder prefix) → scene folder. So
    /// `generateVideo` can return an MP4 from the same scene the source
    /// image came from, keeping the video under the matching lyric line.
    private var imageToScene: [String: String] = [:]
    private var sceneVideoCursors: [String: Int] = [:]
    private var videosMade = 0
    private var toppedUp = false

    /// Returns three image paths for the next scene in the cycle along with
    /// the lyric line this scene starts at (nil for scene1 which has no
    /// per-scene line.json). Scenes with fewer than three images repeat
    /// within the scene so the batch beat stays consistent.
    private func nextSceneTriplet() -> (images: [String], startLine: Int?) {
        lock.lock(); defer { lock.unlock() }
        let scene = Self.scenes[sceneCursor % Self.scenes.count]
        sceneCursor += 1
        let startLine = DemoLyricsBundle.sceneStartLines[scene.folder]
        var triplet: [String] = []
        for i in 0..<3 {
            let img = scene.images[i % scene.images.count]
            let imgPath = Self.path(scene, img)
            triplet.append(imgPath)
            imageToScene[imgPath] = scene.folder
        }
        return (triplet, startLine)
    }

    /// Returns the next video for the scene the source image came from,
    /// cycling through that scene's videos if it has more than one.
    private func nextVideoForImage(_ image: String) -> String {
        lock.lock(); defer { lock.unlock() }
        let sceneFolder = imageToScene[image] ?? Self.scenes.last!.folder
        guard let scene = Self.scenes.first(where: { $0.folder == sceneFolder })
        else { return Self.path(Self.scenes.last!, Self.scenes.last!.videos.first!) }
        let cursor = sceneVideoCursors[sceneFolder, default: 0]
        let videoFile = scene.videos[cursor % scene.videos.count]
        sceneVideoCursors[sceneFolder] = cursor + 1
        return Self.path(scene, videoFile)
    }

    private func recordVideo() {
        lock.lock(); defer { lock.unlock() }
        videosMade += 1
    }

    /// Called by the demo topup sheet's "purchase" short-circuit so the next
    /// `currentCredit()` reads as plentiful again.
    func topUp() {
        lock.lock(); defer { lock.unlock() }
        toppedUp = true
        videosMade = 0
    }

    private func balance() -> Int64 {
        // Demo: balance never drops. The topup beat is a real-app concern;
        // here it would interrupt the tour with a paywall the user can't pay.
        return 500
    }

    // MARK: Account

    func currentCredit() async throws -> Credit {
        try await Task.sleep(for: Self.quickFetchSleep)
        return Credit(credits: balance())
    }

    func currentPricing() async throws -> Pricing {
        try await Task.sleep(for: Self.quickFetchSleep)
        return Pricing(
            chat: 1,
            microPixLyra: 3,
            microPixVega: 3,
            nanoPixLuna: 3,
            image: 1,
            nanoRenSpica: 50,
            gb: 100
        )
    }

    func allProjects() async throws -> [Project] {
        try await Task.sleep(for: Self.quickFetchSleep)
        return [
            Project(
                audio: Self.demoAudioFile,
                summary: "Demo song"
            )
        ]
    }

    // MARK: Prompts

    func chatPrompt(_ seed: String) async throws -> String {
        try await Task.sleep(for: Self.chatSleep)
        return seed
    }

    func chatDerive(priorPrompt: String, userTweak: String) async throws -> String {
        try await Task.sleep(for: Self.chatSleep)
        if priorPrompt.isEmpty { return userTweak }
        return "\(priorPrompt) — \(userTweak)"
    }

    // MARK: Image generation

    func generateImageBatch(prompt: String) async -> [GeneratedImage] {
        // Draw the scene up-front so all three slots share it AND share the
        // scene's starting lyric line — three models in parallel still match
        // the real fan-out timing.
        let triplet = nextSceneTriplet()
        async let a: GeneratedImage? = makeImage(file: triplet.images[0], prompt: prompt, source: .lyra, lineIndex: triplet.startLine)
        async let b: GeneratedImage? = makeImage(file: triplet.images[1], prompt: prompt, source: .vega, lineIndex: triplet.startLine)
        async let c: GeneratedImage? = makeImage(file: triplet.images[2], prompt: prompt, source: .luna, lineIndex: triplet.startLine)
        return await [a, b, c].compactMap { $0 }
    }

    private func makeImage(
        file: String,
        prompt: String,
        source: GeneratedImage.Source,
        lineIndex: Int?
    ) async -> GeneratedImage? {
        try? await Task.sleep(for: Self.imageGenSleep)
        return GeneratedImage(
            id: UUID(),
            file: file,
            prompt: prompt,
            source: source,
            lineIndex: lineIndex
        )
    }

    // MARK: Video generation

    func registerImageForVideo(filename: String) async throws -> String {
        try await Task.sleep(for: Self.registerSleep)
        return filename
    }

    func trimAndUploadAudioClip(
        sourceAudioFile: String,
        startMs: Int,
        durationMs: Int
    ) async throws -> String {
        try await Task.sleep(for: Self.trimSleep)
        return sourceAudioFile
    }

    func generateVideo(
        imageFile: String,
        audioFile: String,
        prompt: String
    ) async throws -> String {
        try await Task.sleep(for: Self.videoGenSleep)
        recordVideo()
        return nextVideoForImage(imageFile)
    }

    // MARK: Upload

    func uploadImageBinary(data: Data, suggestedName: String) async throws -> String {
        try await Task.sleep(for: Self.uploadSleep)
        let filename = "upload-\(UUID().uuidString).jpg"
        if let img = UIImage(data: data) {
            await MainActor.run {
                DemoUploadCache.images[filename] = img
            }
        }
        return filename
    }
}

// MARK: - Onboarding audio (app-scoped, primed at launch)

@MainActor @Observable
final class OnboardingAudio {
    static let shared = OnboardingAudio()

    private var player: AVAudioPlayer?
    private var hasStarted = false
    private var preparing = false
    /// `start()` was called before `prepare()` finished. In the production
    /// app the SongView gateway absorbs the decode time so this never fires;
    /// in the demo (no gateway) the onboarding view mounts at launch and the
    /// race is real — flag the request so `prepare()`'s completion can kick
    /// playback off as soon as the player exists.
    private var pendingStart = false
    /// Guards against double-fading when both the natural end-of-track fade
    /// and an explicit `fadeOut(duration:)` (e.g., first-batch landed) fire.
    private var hasFadedOut = false

    private init() {}

    func prepare(resource: String, ext: String) {
        guard player == nil, !preparing else { return }
        preparing = true
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let url = Bundle.demoResources.url(forResource: resource, withExtension: ext)
            else {
                await MainActor.run { [weak self] in self?.preparing = false }
                return
            }
            do {
                let p = try AVAudioPlayer(contentsOf: url)
                p.numberOfLoops = 0
                p.volume = 0
                p.prepareToPlay()
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.player = p
                    self.preparing = false
                    if self.pendingStart {
                        self.pendingStart = false
                        self.beginPlayback()
                    }
                }
            } catch {
                await MainActor.run { [weak self] in self?.preparing = false }
            }
        }
    }

    func start(resource: String, ext: String) {
        guard !hasStarted else { return }
        if player == nil {
            pendingStart = true
            if !preparing { prepare(resource: resource, ext: ext) }
            return
        }
        beginPlayback()
    }

    private func beginPlayback() {
        guard !hasStarted, let p = player else { return }
        hasStarted = true
        try? AVAudioSession.sharedInstance().setCategory(
            .ambient, mode: .default, options: [.mixWithOthers]
        )
        try? AVAudioSession.sharedInstance().setActive(true)
        p.play()
        p.setVolume(0.6, fadeDuration: 0.3)

        // Schedule a graceful end-of-track fade so the music tapers rather
        // than cutting off if the user lingers on the onboarding/grid past
        // the explicit `fadeOut(duration:)` beat. Re-entrancy is fine —
        // whichever fade-trigger fires first wins via `hasFadedOut`.
        let fadeLeadTime: TimeInterval = 1.5
        let timeUntilFade = max(0, p.duration - fadeLeadTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeUntilFade) { [weak self] in
            self?.fadeOut(duration: fadeLeadTime)
        }
    }

    func fadeOut(duration: TimeInterval = 0.6) {
        guard !hasFadedOut, let p = player else { return }
        hasFadedOut = true
        p.setVolume(0, fadeDuration: Float(duration) > 0 ? duration : 0.001)
        let delay = max(duration, 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.player?.stop()
            self?.player = nil
            try? AVAudioSession.sharedInstance().setActive(false,
                options: [.notifyOthersOnDeactivation])
        }
    }
}

// MARK: - Like store (in-memory only for demo)

/// Demo builds want every launch to feel like the user's first time, so
/// likes are session-scoped — no UserDefaults read or write. A returning
/// device gets a clean slate.
@MainActor @Observable
final class LikeStore {
    private(set) var liked: Set<String> = []

    func isLiked(_ id: UUID) -> Bool { liked.contains(id.uuidString) }

    func toggle(_ id: UUID) {
        if liked.contains(id.uuidString) { liked.remove(id.uuidString) }
        else { liked.insert(id.uuidString) }
    }
}

// MARK: - Demo topup (StoreKit-free)

/// Mirrors the production `StoreService` surface — same `Tier`, same
/// `products` lookup, same `purchase(...)` shape — but products are canned
/// and `purchase(...)` short-circuits to a completed top-up.
@MainActor @Observable
final class StoreService {
    enum Tier: String, CaseIterable, Identifiable {
        case creator, artist, director
        var id: String { rawValue }
        var displayName: String { rawValue.capitalized }
        var blurb: String {
            switch self {
            case .creator: "Starter pack — make a few scenes."
            case .artist: "Most popular — build full sets."
            case .director: "Pro pack — direct full music videos."
            }
        }
    }

    struct DemoProduct: Hashable {
        let displayPrice: String
    }

    private(set) var products: [Tier: DemoProduct] = [:]
    private(set) var error: String?

    private let onPurchase: @MainActor () -> Void

    init(onPurchase: @escaping @MainActor () -> Void) {
        self.onPurchase = onPurchase
    }

    func loadProducts() async {
        // No network, no StoreKit configuration — canned tiers so the sheet
        // reads honestly.
        products = [
            .creator: DemoProduct(displayPrice: "$2.99"),
            .artist: DemoProduct(displayPrice: "$9.99"),
            .director: DemoProduct(displayPrice: "$24.99"),
        ]
        error = nil
    }

    func purchase(_ tier: Tier) async throws -> Bool {
        _ = tier
        try await Task.sleep(for: .milliseconds(500))
        onPurchase()
        return true
    }
}

// MARK: - View model

@MainActor @Observable
final class GenerateViewModel {

    enum Phase: Hashable {
        case onboarding
        case grid
        case derive(image: GeneratedImage)
    }

    enum TutorialMoment: Hashable {
        case none, tapImageToDerive, likeAnImage, selectLikedForVideo
    }

    enum GridFilter: Hashable, CaseIterable {
        case all, liked, videos
        var label: String {
            switch self { case .all: "All"; case .liked: "Liked"; case .videos: "Videos" }
        }
    }

    var phase: Phase = .onboarding
    var tutorialMoment: TutorialMoment = .none
    var filter: GridFilter = .all

    var isSelectingForVideo: Bool = false
    var selectedImageIds: [UUID] = []

    var viewingVideo: GeneratedVideo? = nil

    var project: Project?
    var images: [GeneratedImage] = []
    var videos: [GeneratedVideo] = []
    var pendingVideos: [PendingVideo] = []
    var pendingImages: [PendingImage] = []
    var pendingGenerations: [PendingGeneration] = []

    var credit: Credit?
    var pricing: Pricing?
    var loadingBalance = false
    var errorMessage: String?

    var presentingTopup = false
    var presentingProjects = false
    private var pendingActionAfterTopup: (() -> Void)?

    var allProjects: [Project] = []

    var lyrics: String?
    var audiolines: [SongLine]?

    /// True once the user has dismissed the full-screen video detail at least
    /// once. Drives the demo-only third act: the editor tab slides up from
    /// the bottom and (if the user never tapped *Add your lyrics*) the grid
    /// re-sections itself by lyric line.
    var revealEditorTab = false
    private var hasHandledFirstVideoDismiss = false

    /// Demo lyrics, sourced from the shared `DemoLyricsBundle` so the line
    /// indices the service tagged images with match the indices the view
    /// model assigns when this text is pasted.
    private static var demoLyrics: String { DemoLyricsBundle.combinedText }

    let likeStore = LikeStore()
    let store: StoreService
    let onboardingAudio = OnboardingAudio.shared
    private let service: GenerateService

    init(service: GenerateService = DemoGenerateService()) {
        self.service = service
        // The demo store short-circuits purchases by topping up the demo
        // service's ledger; injecting the closure keeps the seam clean.
        if let demo = service as? DemoGenerateService {
            self.store = StoreService(onPurchase: { demo.topUp() })
        } else {
            self.store = StoreService(onPurchase: { })
        }
        if devSeedEnabled { devSeed() }
    }

    private func devSeed() {
        let seedProject = Project(
            audio: "demo.mp3",
            summary: "Dev seed"
        )
        self.allProjects = [seedProject]
        self.project = seedProject
        self.images = [
            "019e7f3d-7bff-7901-ac73-8c7372b56330.png",
            "019e7f3d-a3c0-7e63-a239-d84846529654.png",
            "019e7f3d-aa21-7173-86ae-fbe8d61d0a84.png",
        ].map { name in
            GeneratedImage(
                id: UUID(),
                file: name,
                prompt: "Dev seed",
                source: .lyra
            )
        }
        self.phase = .grid
    }

    // Derived

    var filteredImages: [GeneratedImage] {
        switch filter {
        case .all, .videos: images
        case .liked: images.filter { likeStore.isLiked($0.id) }
        }
    }
    var likedImages: [GeneratedImage] { images.filter { likeStore.isLiked($0.id) } }

    var generationCost: Int64 {
        guard let p = pricing else { return 0 }
        return p.chat + p.microPixLyra + p.microPixVega + p.nanoPixLuna
    }

    var videoCost: Int64 {
        guard let p = pricing else { return 0 }
        return p.image + p.nanoRenSpica
    }

    var bandwidthMinPerFile: Int64 { 1 }

    // MARK: - Lyrics + line cursor

    func pasteLyrics(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let rawLines = trimmed
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let lines = rawLines.enumerated().map { idx, text in
            SongLine(
                id: UUID(),
                index: idx,
                text: text,
                startMs: idx * 6_000,
                durationMs: 6_000
            )
        }
        self.lyrics = trimmed
        withAnimation(.spring(duration: 0.5)) {
            self.audiolines = lines
            backfillLineIndices()
        }
    }

    private func backfillLineIndices() {
        guard let audiolines, !audiolines.isEmpty else { return }
        var nextLine = 0
        for i in images.indices where images[i].lineIndex == nil {
            images[i].lineIndex = audiolines[nextLine % audiolines.count].index
            nextLine += 1
        }
        // Videos inherit the line of the picture they were made from. Run
        // after image backfill so the lookup always finds a tagged primary.
        for i in videos.indices where videos[i].lineIndex == nil {
            guard let primaryId = videos[i].sourceImageIds.first,
                  let primary = images.first(where: { $0.id == primaryId })
            else { continue }
            videos[i].lineIndex = primary.lineIndex
        }
        for i in pendingVideos.indices where pendingVideos[i].lineIndex == nil {
            guard let primaryId = pendingVideos[i].sourceImageIds.first,
                  let primary = images.first(where: { $0.id == primaryId })
            else { continue }
            pendingVideos[i].lineIndex = primary.lineIndex
        }
    }

    func nextUnfilledLines(count: Int) -> [Int] {
        guard let audiolines, !audiolines.isEmpty else { return [] }
        let used = Set(images.compactMap { $0.lineIndex })
        var result: [Int] = []
        for line in audiolines where !used.contains(line.index) {
            result.append(line.index)
            if result.count >= count { return result }
        }
        var i = 0
        while result.count < count {
            result.append(audiolines[i % audiolines.count].index)
            i += 1
        }
        return result
    }

    func tagBatch(_ batch: [GeneratedImage]) -> [GeneratedImage] {
        guard audiolines != nil else { return batch }
        // The demo service may have pre-tagged images with their scene's
        // starting line. Preserve those; only fill in lines for genuinely
        // untagged images (uploads, real-service results).
        var result = batch
        let untaggedSlots = result.indices.filter { result[$0].lineIndex == nil }
        guard !untaggedSlots.isEmpty else { return result }
        let lineIndices = nextUnfilledLines(count: untaggedSlots.count)
        for (i, slot) in untaggedSlots.enumerated() where i < lineIndices.count {
            result[slot].lineIndex = lineIndices[i]
        }
        return result
    }

    func fillLine(_ lineIndex: Int) {
        guard let audiolines, audiolines.contains(where: { $0.index == lineIndex })
        else { return }
        guard gateOnCredit(cost: generationCost, retry: { [weak self] in
            self?.fillLine(lineIndex)
        }) else { return }

        let seedText = audiolines.first(where: { $0.index == lineIndex })?.text
            ?? project?.summary
            ?? "A vibrant music video moment"
        let pendings = (0..<3).map { _ in
            PendingGeneration(id: UUID(), lineIndex: lineIndex)
        }
        let pendingIds = pendings.map(\.id)

        withAnimation(.spring(duration: 0.3)) {
            pendingGenerations.append(contentsOf: pendings)
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                let enriched = try await self.service.chatPrompt(seedText)
                let batch = await self.service.generateImageBatch(prompt: enriched)
                let tagged = batch.map { img -> GeneratedImage in
                    var t = img; t.lineIndex = lineIndex; return t
                }
                await MainActor.run {
                    withAnimation(.spring(duration: 0.35)) {
                        self.pendingGenerations.removeAll { pendingIds.contains($0.id) }
                        self.images.append(contentsOf: tagged)
                    }
                }
                await self.refreshCredit()
            } catch {
                await MainActor.run {
                    for i in self.pendingGenerations.indices
                        where pendingIds.contains(self.pendingGenerations[i].id) {
                        self.pendingGenerations[i].state = .failed
                    }
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // Lifecycle

    func bootstrap() async {
        loadingBalance = true
        defer { loadingBalance = false }
        async let credit = try? service.currentCredit()
        async let pricing = try? service.currentPricing()
        async let projects = try? service.allProjects()
        self.credit = await credit
        self.pricing = await pricing
        let loaded = await projects ?? []
        self.allProjects = loaded
        if !loaded.isEmpty {
            self.project = loaded.first
        }
        await store.loadProducts()
    }

    // MARK: - Project switcher

    func openProjects() { presentingProjects = true }

    func switchToProject(_ p: Project) {
        guard p.id != project?.id else {
            presentingProjects = false
            return
        }
        withAnimation(.spring(duration: 0.4)) {
            self.project = p
            self.images = []
            self.videos = []
            self.pendingImages = []
            self.pendingVideos = []
            self.pendingGenerations = []
            self.lyrics = nil
            self.audiolines = nil
            self.selectedImageIds = []
            self.isSelectingForVideo = false
            self.phase = .grid
            self.presentingProjects = false
        }
    }

    // Onboarding
    /// Onboarding's settled headline is the CTA. Tap = begin immediately —
    /// no second "Ready?" beat.
    func finishOnboarding() { tapStart() }

    func tapStart() {
        // Keep the music going through the first reveal — fading it out here
        // would silence the moment the pictures land. Fade after they're in.
        Task { await performInitialGeneration() }
    }

    private func performInitialGeneration() async {
        guard gateOnCredit(cost: generationCost, retry: { [weak self] in
            Task { await self?.performInitialGeneration() }
        }) else { return }

        // Land on the grid immediately with three shimmer cells — same pattern
        // as derive / fill-line / upload. No separate full-screen wait.
        let pendings = (0..<3).map { _ in
            PendingGeneration(id: UUID(), lineIndex: nil)
        }
        let pendingIds = pendings.map(\.id)
        withAnimation(.spring(duration: 0.4)) {
            pendingGenerations.append(contentsOf: pendings)
            phase = .grid
        }

        let seed = project?.summary
            ?? project?.audioLines.first?.line
            ?? "A vibrant music video opening scene"
        do {
            let enriched = try await service.chatPrompt(seed)
            let batch = await service.generateImageBatch(prompt: enriched)
            let tagged = tagBatch(batch)
            withAnimation(.spring(duration: 0.45)) {
                pendingGenerations.removeAll { pendingIds.contains($0.id) }
                images.append(contentsOf: tagged)
            }
            // Dopamine beat: the first three pictures land. Medium impact
            // matches the weight of "you made these."
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            await refreshCredit()
            scheduleTutorialMoment(.tapImageToDerive)
            onboardingAudio.fadeOut(duration: 1.2)
        } catch {
            for i in pendingGenerations.indices
                where pendingIds.contains(pendingGenerations[i].id) {
                pendingGenerations[i].state = .failed
            }
            errorMessage = error.localizedDescription
        }
    }

    // Derive

    func openDerive(_ image: GeneratedImage) { phase = .derive(image: image) }

    func submitDerivation(from image: GeneratedImage, tweak: String) {
        guard gateOnCredit(cost: generationCost, retry: { [weak self] in
            self?.submitDerivation(from: image, tweak: tweak)
        }) else { return }

        let lineIndices: [Int?] = {
            guard audiolines != nil else {
                return Array(repeating: nil, count: 3)
            }
            let next = nextUnfilledLines(count: 3)
            return (0..<3).map { i in i < next.count ? next[i] : nil }
        }()
        let pendings = lineIndices.map { PendingGeneration(id: UUID(), lineIndex: $0) }
        let pendingIds = pendings.map(\.id)
        let priorPrompt = image.prompt

        withAnimation(.spring(duration: 0.35)) {
            pendingGenerations.append(contentsOf: pendings)
            phase = .grid
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                let enriched = try await self.service.chatDerive(
                    priorPrompt: priorPrompt, userTweak: tweak
                )
                let batch = await self.service.generateImageBatch(prompt: enriched)
                let tagged = batch.enumerated().map { (offset, img) -> GeneratedImage in
                    var t = img
                    if offset < lineIndices.count, let li = lineIndices[offset] {
                        t.lineIndex = li
                    }
                    return t
                }
                await MainActor.run {
                    withAnimation(.spring(duration: 0.4)) {
                        self.pendingGenerations.removeAll { pendingIds.contains($0.id) }
                        self.images.append(contentsOf: tagged)
                    }
                    if self.tutorialMoment == .tapImageToDerive {
                        self.scheduleTutorialMoment(.likeAnImage)
                    }
                }
                await self.refreshCredit()
            } catch {
                await MainActor.run {
                    for i in self.pendingGenerations.indices
                        where pendingIds.contains(self.pendingGenerations[i].id) {
                        self.pendingGenerations[i].state = .failed
                    }
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func dismissPendingGeneration(_ id: UUID) {
        withAnimation { pendingGenerations.removeAll { $0.id == id } }
    }

    /// Coach marks dimming the screen the instant a reveal happens kills the
    /// dopamine of the moment. Defer the transition so the user gets a beat
    /// to savor before being instructed. The default delay matches the
    /// settle of the spring animations that just played.
    private func scheduleTutorialMoment(_ moment: TutorialMoment, after seconds: Double = 1.2) {
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard let self else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                self.tutorialMoment = moment
            }
        }
    }

    // Like

    func toggleLikeImage(_ image: GeneratedImage) {
        likeStore.toggle(image.id)
        if likeStore.isLiked(image.id), tutorialMoment == .likeAnImage {
            // Shorter delay here — the user just did the deliberate action
            // (tapped heart); the next nudge should follow quickly but not
            // step on the heart-fill animation.
            scheduleTutorialMoment(.selectLikedForVideo, after: 0.6)
        }
    }

    func toggleLikeVideo(_ video: GeneratedVideo) {
        likeStore.toggle(video.id)
    }

    // In-grid select mode for video creation.

    var canMakeVideo: Bool { !likedImages.isEmpty }

    func enterMakeVideo() {
        guard canMakeVideo else { return }
        selectedImageIds = []
        withAnimation(.spring(duration: 0.3)) { isSelectingForVideo = true }
    }

    func cancelMakeVideo() {
        withAnimation(.spring(duration: 0.3)) {
            isSelectingForVideo = false
            selectedImageIds = []
        }
    }

    func toggleSelection(_ id: UUID) {
        guard likeStore.isLiked(id) else { return }
        if let i = selectedImageIds.firstIndex(of: id) {
            selectedImageIds.remove(at: i)
        } else if selectedImageIds.count < 3 {
            selectedImageIds.append(id)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func confirmMakeVideo() {
        let ids = selectedImageIds
        guard !ids.isEmpty else { return }
        guard let project, !project.audio.isEmpty else {
            errorMessage = "Project audio missing"; return
        }
        guard gateOnCredit(cost: videoCost, retry: { [weak self] in
            self?.confirmMakeVideo()
        }) else { return }
        guard let firstId = ids.first,
              let primary = images.first(where: { $0.id == firstId })
        else { return }

        isSelectingForVideo = false
        selectedImageIds = []

        let pending = PendingVideo(
            id: UUID(),
            sourceImageIds: ids,
            posterFile: primary.file,
            lineIndex: primary.lineIndex
        )
        withAnimation(.spring(duration: 0.3)) {
            pendingVideos.append(pending)
        }

        let projectAudio = project.audio
        let prompt = primary.prompt
        let lineRange: (start: Int, duration: Int)? = {
            guard let lineIndex = primary.lineIndex,
                  let line = audiolines?.first(where: { $0.index == lineIndex })
            else { return nil }
            return (line.startMs, line.durationMs)
        }()

        Task { [weak self] in
            guard let self else { return }
            do {
                let registered = try await self.service.registerImageForVideo(filename: primary.file)
                let audioFile: String
                if let r = lineRange {
                    do {
                        audioFile = try await self.service.trimAndUploadAudioClip(
                            sourceAudioFile: projectAudio,
                            startMs: r.start,
                            durationMs: r.duration
                        )
                    } catch {
                        audioFile = projectAudio
                    }
                } else {
                    audioFile = projectAudio
                }
                let videoFile = try await self.service.generateVideo(
                    imageFile: registered,
                    audioFile: audioFile,
                    prompt: prompt
                )
                let wasFirstVideo = self.videos.isEmpty
                withAnimation(.spring(duration: 0.4)) {
                    self.pendingVideos.removeAll { $0.id == pending.id }
                    self.videos.append(GeneratedVideo(
                        id: UUID(),
                        file: videoFile,
                        posterFile: primary.file,
                        sourceImageIds: ids,
                        lineIndex: primary.lineIndex
                    ))
                }
                if wasFirstVideo {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                await self.refreshCredit()
                if self.tutorialMoment == .selectLikedForVideo {
                    self.tutorialMoment = .none
                }
            } catch {
                if let idx = self.pendingVideos.firstIndex(where: { $0.id == pending.id }) {
                    self.pendingVideos[idx].state = .failed
                }
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func dismissPendingVideo(_ id: UUID) {
        withAnimation { pendingVideos.removeAll { $0.id == id } }
    }

    // MARK: - Upload your own image

    func handlePhotoPick(_ data: Data) {
        let pending = PendingImage(id: UUID())
        withAnimation(.spring(duration: 0.3)) {
            pendingImages.append(pending)
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                let file = try await self.service.uploadImageBinary(
                    data: data,
                    suggestedName: "upload-\(UUID().uuidString).jpg"
                )
                let newImage = GeneratedImage(
                    id: UUID(),
                    file: file,
                    prompt: "Your picture",
                    source: .upload
                )
                let tagged = await MainActor.run { self.tagBatch([newImage]).first ?? newImage }
                withAnimation(.spring(duration: 0.4)) {
                    self.pendingImages.removeAll { $0.id == pending.id }
                    self.images.append(tagged)
                }
                await self.refreshCredit()
            } catch {
                if let idx = self.pendingImages.firstIndex(where: { $0.id == pending.id }) {
                    self.pendingImages[idx].state = .failed
                }
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func dismissPendingImage(_ id: UUID) {
        withAnimation { pendingImages.removeAll { $0.id == id } }
    }

    // Credit / topup gate

    private func gateOnCredit(cost: Int64, retry: @escaping () -> Void) -> Bool {
        guard let c = credit else { return true }
        if c.credits < cost {
            pendingActionAfterTopup = retry
            presentingTopup = true
            return false
        }
        return true
    }

    func refreshCredit() async { credit = try? await service.currentCredit() }

    func purchase(_ tier: StoreService.Tier) async {
        do {
            if try await store.purchase(tier) {
                await refreshCredit()
                presentingTopup = false
                let pending = pendingActionAfterTopup
                pendingActionAfterTopup = nil
                pending?()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dismissTopup() { presentingTopup = false; pendingActionAfterTopup = nil }

    /// Called the first time the user closes the full-screen video detail —
    /// the natural end of the screen's purpose. Sequence: let the cover
    /// finish dismissing, auto-paste demo lyrics if the user hadn't (the
    /// grid re-sections itself on screen), then slide the editor tab up
    /// from the bottom as the path forward.
    func handleVideoDetailDismissed() {
        guard !hasHandledFirstVideoDismiss else { return }
        hasHandledFirstVideoDismiss = true

        Task { [weak self] in
            // Wait for the fullScreenCover dismiss animation to land so the
            // lyric sections animate into a grid the user can actually see.
            try? await Task.sleep(for: .milliseconds(400))
            guard let self else { return }
            if self.lyrics == nil {
                self.pasteLyrics(Self.demoLyrics)
            }
            // Beat between transformations so each one earns its own moment.
            try? await Task.sleep(for: .milliseconds(800))
            withAnimation(.spring(duration: 0.6, bounce: 0.25)) {
                self.revealEditorTab = true
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

// MARK: - Authorized image (bundle-resolved in demo)

private struct AuthorizedImage: View {
    let filename: String
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?

    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    var body: some View {
        ZStack {
            if isPreview {
                Image(uiImage: bundledImage).resizable().aspectRatio(contentMode: contentMode)
            } else if let image {
                Image(uiImage: image).resizable().aspectRatio(contentMode: contentMode)
            } else {
                Shimmer()
            }
        }
        .task(id: filename) {
            guard !isPreview else { return }
            await load()
        }
    }

    private var bundledImage: UIImage {
        guard let url = Media.url(filename) else {
            fatalError("DemoGenerate: missing asset URL for \(filename)")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("DemoGenerate: cannot read bytes for \(filename)")
        }
        guard let img = UIImage(data: data) else {
            fatalError("DemoGenerate: cannot decode image for \(filename)")
        }
        return img
    }

    private func load() async {
        // Demo upload cache first — user-supplied photos live here.
        if let cached = await MainActor.run(body: { DemoUploadCache.images[filename] }) {
            await MainActor.run { self.image = cached }
            return
        }
        let bundled = bundledImage
        await MainActor.run { self.image = bundled }
    }
}

// MARK: - Shimmer placeholder

private struct Shimmer: View {
    @State private var phase: CGFloat = -1
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Theme.surface
                LinearGradient(
                    colors: [.clear, Theme.accentMagenta.opacity(0.35),
                             Theme.accentBlue.opacity(0.35), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: geo.size.width * 0.7)
                .offset(x: phase * geo.size.width)
                .blur(radius: 18)
            }
        }
        .clipped()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: false)) {
                phase = 1.5
            }
        }
    }
}

// MARK: - Authorized auto-muted looping video cell

private struct AuthorizedVideoView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PlayerUIView { PlayerUIView(url: url) }
    func updateUIView(_ uiView: PlayerUIView, context: Context) {}
}

private final class PlayerUIView: UIView {
    private let player: AVPlayer
    private let layerView = AVPlayerLayer()
    init(url: URL) {
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        super.init(frame: .zero)
        backgroundColor = .black
        player.isMuted = true
        player.actionAtItemEnd = .none
        layerView.player = player
        layerView.videoGravity = .resizeAspectFill
        layer.addSublayer(layerView)
        player.play()
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak player] _ in player?.seek(to: .zero); player?.play() }
    }
    required init?(coder: NSCoder) { fatalError() }
    override func layoutSubviews() { super.layoutSubviews(); layerView.frame = bounds }
}

// MARK: - Video detail playback (full screen, sound on)

private struct VideoDetailView: View {
    let video: GeneratedVideo
    @Bindable var viewModel: GenerateViewModel
    let onDismiss: () -> Void
    @State private var player: AVPlayer?
    /// Set true when `setupPlayback` discovers the video file isn't bundled.
    /// Without this the spinner would spin forever on the poster image when
    /// the demo MP4 hasn't been shipped yet.
    @State private var videoUnavailable = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                AuthorizedImage(filename: video.posterFile)
                    .ignoresSafeArea()
                if !videoUnavailable {
                    ProgressView().controlSize(.large).tint(.white)
                }
            }
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.ultraThinMaterial, in: .circle)
                    }
                    .padding(16)
                }
                Spacer()
            }
        }
        .task { setupPlayback() }
        .onDisappear { teardownPlayback() }
    }

    private func setupPlayback() {
        guard let url = Media.url(video.file) else {
            videoUnavailable = true
            return
        }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let p = AVPlayer(playerItem: item)
        p.isMuted = false
        self.player = p
        p.play()
    }

    private func teardownPlayback() {
        player?.pause()
        player = nil
        try? AVAudioSession.sharedInstance().setCategory(
            .ambient, mode: .default, options: [.mixWithOthers]
        )
    }
}

// MARK: - Projects sheet (switch song / new song)

private struct ProjectsSheet: View {
    @Bindable var viewModel: GenerateViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if viewModel.allProjects.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(viewModel.allProjects, id: \.id) { project in
                            Button {
                                viewModel.switchToProject(project)
                            } label: {
                                row(project)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Theme.surface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Your songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.muted)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.muted)
            Text("No songs yet")
                .font(.headline)
                .foregroundStyle(Theme.onSurface)
            Text("Tap + above to upload your first song.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    @ViewBuilder
    private func row(_ project: Project) -> some View {
        let isCurrent = project.id == viewModel.project?.id
        HStack(spacing: 14) {
            let h = abs(project.id.hashValue)
            LinearGradient(
                colors: [
                    Color(hue: Double(h % 360) / 360, saturation: 0.7, brightness: 0.55),
                    Color(hue: Double((h / 360) % 360) / 360, saturation: 0.8, brightness: 0.4),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(width: 56, height: 56)
            .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title(for: project))
                    .font(.headline)
                    .foregroundStyle(Theme.onSurface)
                    .lineLimit(1)
                Text(subtitle(for: project))
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }
            Spacer()
            if isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.accentMagenta)
            }
        }
        .padding(.vertical, 4)
    }

    private func title(for p: Project) -> String {
        let s = p.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.isEmpty { return s }
        let audioBase = (p.audio as NSString).lastPathComponent
        let stripped = (audioBase as NSString).deletingPathExtension
        return stripped.isEmpty ? "Untitled song" : stripped
    }

    private func subtitle(for p: Project) -> String {
        let lineCount = p.audioLines.count
        if lineCount > 0 { return "\(lineCount) lyric line\(lineCount == 1 ? "" : "s")" }
        return p.audio
    }
}

// MARK: - Coach mark

private struct CoachMark: View {
    let title: String
    let message: String
    let onDismiss: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea().onTapGesture(perform: onDismiss)
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                        Text(title).font(.headline).foregroundStyle(Theme.onSurface)
                    }
                    Text(message).font(.subheadline).foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Spacer()
                        Button("Got it", action: onDismiss).buttonStyle(.glassProminent)
                    }
                }
                .padding(20)
                .background(.regularMaterial, in: .rect(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24)
                    .stroke(Theme.accentMagenta.opacity(0.4), lineWidth: 1))
                .padding(.horizontal, 20).padding(.bottom, 32)
                .shadow(color: .black.opacity(0.4), radius: 30, y: 10)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Make video bottom shelf

/// The commit shelf that appears while the user is picking pictures for a
/// video. Lives at the outer container level (not inside the GridView
/// scroll) so it stacks above the `DemoTabBar` via consecutive
/// `safeAreaInset` modifiers instead of overlapping it.
private struct MakeVideoShelf: View {
    @Bindable var viewModel: GenerateViewModel

    var body: some View {
        Button("Make video") {
            viewModel.confirmMakeVideo()
        }
        .buttonStyle(AccentButtonStyle())
        .disabled(viewModel.selectedImageIds.isEmpty)
        .opacity(viewModel.selectedImageIds.isEmpty ? 0.5 : 1)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }
}

// MARK: - Demo tab bar (third-act reveal)

/// Slides up after the user closes the first video — the demo's third act
/// hand-off. Floating Liquid Glass capsule (iOS 26 pattern), not a
/// full-width shelf. Two tabs: Generate (active) and Editor (gently
/// pulsing as the next destination). The Editor tap in this isolated
/// build confirms with a soft haptic; the parent app wires it to the
/// next demo screen.
private struct DemoTabBar: View {
    let onEditorTap: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 0) {
            tab(systemName: "wand.and.stars", label: "Generate", active: true, pulse: false,
                accessibilityLabel: "Generate, current tab") { }
            tab(systemName: "scissors", label: "Editor", active: false, pulse: pulse,
                accessibilityLabel: "Editor, next demo") {
                UISelectionFeedbackGenerator().selectionChanged()
                onEditorTap()
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 24)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 40)
        .padding(.bottom, 8)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    @ViewBuilder
    private func tab(
        systemName: String,
        label: String,
        active: Bool,
        pulse: Bool,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(.subheadline.weight(.semibold))
                    .symbolRenderingMode(.hierarchical)
                Text(label)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(active ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.muted))
            .scaleEffect(pulse ? 1.06 : 1.0)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Credit chip

private struct CreditChip: View {
    let credits: Int64
    let isLoading: Bool
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill").font(.caption.weight(.bold))
                .foregroundStyle(Theme.accent)
            if isLoading {
                ProgressView().scaleEffect(0.6).frame(width: 12, height: 12)
            } else {
                Text("\(credits)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.onSurface)
                    .contentTransition(.numericText(value: Double(credits)))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .glassEffect(.regular, in: .capsule)
    }
}

// MARK: - ContentView

public struct ContentView: View {
    /// Parent-app hook. Fires when the user taps the Editor tab in the demo
    /// tab bar — i.e. the demo has served its purpose and the host should
    /// navigate to the next demo screen (or wherever). Default is a no-op
    /// for standalone runs of this target.
    let onDemoComplete: () -> Void

    @State private var viewModel = GenerateViewModel()
    @State private var photoPickerItem: PhotosPickerItem?

    public init(onDemoComplete: @escaping () -> Void = {}) {
        self.onDemoComplete = onDemoComplete
    }

    public var body: some View {
        Group {
            switch viewModel.phase {
            case .onboarding:
                KineticOnboardingView(onComplete: viewModel.finishOnboarding)
                    .task { viewModel.onboardingAudio.start(resource: "onboarding", ext: "wav") }
                    // Onboarding is full-bleed; hide any host nav bar so the
                    // kinetic burst owns the top edge.
                    .toolbar(.hidden, for: .navigationBar)
            case .grid, .derive:
                gridLayer
                    .toolbar { toolbar }
                    .navigationDestination(isPresented: deriveBinding) {
                        if case .derive(let image) = viewModel.phase {
                            DeriveView(image: image, viewModel: viewModel)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .task { await viewModel.bootstrap() }
        .onChange(of: photoPickerItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    viewModel.handlePhotoPick(data)
                }
                photoPickerItem = nil
            }
        }
        .sheet(isPresented: $viewModel.presentingTopup) {
            TopupSheet(viewModel: viewModel)
                .presentationDetents([.medium])
                .presentationBackground(.clear)
        }
        .fullScreenCover(item: $viewModel.viewingVideo) { video in
            VideoDetailView(video: video, viewModel: viewModel) {
                viewModel.viewingVideo = nil
            }
        }
        .onChange(of: viewModel.viewingVideo) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                viewModel.handleVideoDetailDismissed()
            }
        }
        .sheet(isPresented: $viewModel.presentingProjects) {
            ProjectsSheet(viewModel: viewModel)
                .presentationDetents([.large])
                .presentationBackground(.regularMaterial)
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(viewModel.errorMessage ?? "") }
        )
        // Bottom slot priority:
        // 1. Make video shelf while picking pictures (Photos pattern — shelf
        //    takes the bottom, tab bar steps aside)
        // 2. Tab bar at the grid level, only when the user isn't pushed into
        //    a destination (derive). Same behaviour as native TabView with
        //    `.toolbar(.hidden, for: .tabBar)` on push.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if viewModel.isSelectingForVideo {
                MakeVideoShelf(viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if viewModel.revealEditorTab && !isInDerive {
                DemoTabBar(onEditorTap: onDemoComplete)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var gridLayer: some View {
        GridView(viewModel: viewModel)
            .overlay { coachMarkOverlay }
    }

    @ViewBuilder
    private var coachMarkOverlay: some View {
        switch viewModel.tutorialMoment {
        case .none: EmptyView()
        case .tapImageToDerive:
            CoachMark(
                title: "Tap one you like",
                message: "We'll change it for you.",
                onDismiss: { withAnimation { viewModel.tutorialMoment = .none } }
            )
        case .likeAnImage:
            CoachMark(
                title: "Tap ♡ to save it",
                message: "Saved pictures can become videos.",
                onDismiss: { withAnimation { viewModel.tutorialMoment = .none } }
            )
        case .selectLikedForVideo:
            CoachMark(
                title: "Tap Make Video",
                message: "Up top-right. Pick up to 3 of your saved pictures.",
                onDismiss: { withAnimation { viewModel.tutorialMoment = .none } }
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if viewModel.isSelectingForVideo {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel", action: viewModel.cancelMakeVideo)
                    .foregroundStyle(Theme.onSurface)
            }
            ToolbarItem(placement: .principal) {
                Text("\(viewModel.selectedImageIds.count) of 3 picked")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .contentTransition(.numericText(value: Double(viewModel.selectedImageIds.count)))
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Theme.onSurface)
                }
                .accessibilityLabel("Upload picture from photos")
            }
            if let project = viewModel.project {
                ToolbarItem(placement: .principal) {
                    Button(action: viewModel.openProjects) {
                        HStack(spacing: 6) {
                            Text(songTitle(for: project))
                                .font(.headline)
                                .foregroundStyle(Theme.onSurface)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Theme.muted)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Current song: \(songTitle(for: project)). Double tap to switch.")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: viewModel.enterMakeVideo) {
                    HStack(spacing: 4) {
                        Image(systemName: "film.fill")
                        Text("Make Video")
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(viewModel.canMakeVideo ? Theme.onSurface : Theme.muted)
                .disabled(!viewModel.canMakeVideo)
                .accessibilityLabel("Make video")
                .accessibilityHint(viewModel.canMakeVideo
                    ? "Pick up to three of your saved pictures"
                    : "Save at least one picture first")
            }
        }
    }

    private var isInDerive: Bool {
        if case .derive = viewModel.phase { return true }
        return false
    }

    private var deriveBinding: Binding<Bool> {
        Binding(
            get: { if case .derive = viewModel.phase { true } else { false } },
            set: { v in if !v, case .derive = viewModel.phase { viewModel.phase = .grid } }
        )
    }

    /// Prefer the project's summary as a display title; fall back to the
    /// audio filename with its extension stripped so the toolbar never reads
    /// like a developer artifact (e.g. "demo.mp3").
    private func songTitle(for project: Project) -> String {
        let s = project.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.isEmpty { return s }
        let base = (project.audio as NSString).lastPathComponent
        let stripped = (base as NSString).deletingPathExtension
        return stripped.isEmpty ? "Untitled song" : stripped
    }
}

#Preview { ContentView().preferredColorScheme(.dark) }

// MARK: - Kinetic onboarding

private enum OnboardingSide { case left, right }

private struct DiagonalHalfShape: Shape {
    let side: OnboardingSide
    var topRatio: CGFloat = 0.65
    var bottomRatio: CGFloat = 0.35

    func path(in rect: CGRect) -> Path {
        let topX = rect.width * topRatio
        let bottomX = rect.width * bottomRatio
        return Path { p in
            switch side {
            case .left:
                p.move(to: .zero)
                p.addLine(to: CGPoint(x: topX, y: 0))
                p.addLine(to: CGPoint(x: bottomX, y: rect.height))
                p.addLine(to: CGPoint(x: 0, y: rect.height))
                p.closeSubpath()
            case .right:
                p.move(to: CGPoint(x: topX, y: 0))
                p.addLine(to: CGPoint(x: rect.width, y: 0))
                p.addLine(to: CGPoint(x: rect.width, y: rect.height))
                p.addLine(to: CGPoint(x: bottomX, y: rect.height))
                p.closeSubpath()
            }
        }
    }
}

private struct DiagonalLineShape: Shape {
    var topRatio: CGFloat = 0.65
    var bottomRatio: CGFloat = 0.35

    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.width * topRatio, y: 0))
            p.addLine(to: CGPoint(x: rect.width * bottomRatio, y: rect.height))
        }
    }
}

private struct KineticOnboardingView: View {
    let onComplete: () -> Void
    var images: [String] = ["img1", "img2", "img3", "img4"]
    var forcedHeld: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start: Date = .init()
    @State private var showSkipHint = false

    private var renderStill: Bool { reduceMotion || forcedHeld }

    private let cutInterval: Double = 0.25
    private let burstDuration: Double = 2.0
    private let settleDuration: Double = 0.5
    private let holdDuration: Double = 1.0
    private let ghostDuration: Double = 0.3
    private let returnDuration: Double = 0.5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if renderStill {
                staticHero
            } else {
                TimelineView(.animation) { ctx in
                    let t = ctx.date.timeIntervalSince(start)
                    content(at: t)
                }
            }

            VStack {
                Spacer()
                if showSkipHint {
                    Text("tap to begin")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 32)
                        .transition(.opacity)
                }
            }
        }
        .contentShape(.rect)
        .onTapGesture { onComplete() }
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(1.4))
                withAnimation(.easeIn(duration: 0.6)) { showSkipHint = true }
            }
        }
    }

    @ViewBuilder
    private func content(at t: TimeInterval) -> some View {
        let phase = phase(at: t)
        let beat = Int(t / cutInterval)
        let leftIdx = phase.isBursting ? (beat % images.count) : 0
        let rightIdx = phase.isBursting ? ((beat + 1) % images.count) : (images.count - 1)

        GeometryReader { geo in
            ZStack {
                halfImage(
                    file: images[leftIdx],
                    tint: Theme.accentMagenta,
                    side: .left,
                    in: geo.size,
                    holding: !phase.isBursting
                )
                halfImage(
                    file: images[rightIdx],
                    tint: Theme.accentBlue,
                    side: .right,
                    in: geo.size,
                    holding: !phase.isBursting
                )
                DiagonalLineShape()
                    .stroke(.white.opacity(0.85), lineWidth: 1.5)

                VStack {
                    Spacer()
                    Text("Let's make a music video.")
                        .font(.system(size: 38, weight: .heavy))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.7), radius: 10, y: 4)
                        .padding(.horizontal, 24)
                    Spacer().frame(height: geo.size.height * 0.42)
                }
                .opacity(phase.headlineAlpha)
            }
            .opacity(phase.masterAlpha)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func halfImage(file: String, tint: Color, side: OnboardingSide,
                            in size: CGSize, holding: Bool) -> some View {
        // Pass `Bundle.module` so the package's own resources are searched
        // when this lib is imported into a host app. Force-unwrap: missing
        // demo asset is a build-time bug, not a runtime fallback to hide.
        let uiImage = UIImage(named: file, in: .demoResources, with: nil)!
        Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size.width, height: size.height)
            .clipped()
            .overlay(tint.opacity(holding ? 0.5 : 0.3).blendMode(.overlay))
            .clipShape(DiagonalHalfShape(side: side))
    }

    private struct Phase {
        var isBursting: Bool
        var masterAlpha: Double
        var headlineAlpha: Double
    }

    private func phase(at t: TimeInterval) -> Phase {
        let burstEnd  = burstDuration
        let settleEnd = burstEnd + settleDuration
        let holdEnd   = settleEnd + holdDuration
        let ghostEnd  = holdEnd + ghostDuration
        let returnEnd = ghostEnd + returnDuration

        if t < burstEnd {
            return Phase(isBursting: true, masterAlpha: 1, headlineAlpha: 0)
        } else if t < settleEnd {
            let p = (t - burstEnd) / settleDuration
            return Phase(isBursting: false, masterAlpha: 1, headlineAlpha: p)
        } else if t < holdEnd {
            return Phase(isBursting: false, masterAlpha: 1, headlineAlpha: 1)
        } else if t < ghostEnd {
            let p = (t - holdEnd) / ghostDuration
            return Phase(isBursting: false, masterAlpha: 1 - p * 0.7, headlineAlpha: 1)
        } else if t < returnEnd {
            let p = (t - ghostEnd) / returnDuration
            return Phase(isBursting: false, masterAlpha: 0.3 + p * 0.7, headlineAlpha: 1)
        } else {
            return Phase(isBursting: false, masterAlpha: 1, headlineAlpha: 1)
        }
    }

    @ViewBuilder
    private var staticHero: some View {
        GeometryReader { geo in
            ZStack {
                halfImage(file: images[0], tint: Theme.accentMagenta,
                          side: .left, in: geo.size, holding: true)
                halfImage(file: images[1 % images.count], tint: Theme.accentBlue,
                          side: .right, in: geo.size, holding: true)
                DiagonalLineShape()
                    .stroke(.white.opacity(0.85), lineWidth: 1.5)
                VStack {
                    Spacer()
                    Text("Let's make a music video.")
                        .font(.system(size: 38, weight: .heavy))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.7), radius: 10, y: 4)
                        .padding(.horizontal, 24)
                    Spacer().frame(height: geo.size.height * 0.42)
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("Onboarding") {
    KineticOnboardingView(onComplete: {})
        .preferredColorScheme(.dark)
}

#Preview("Onboarding — Held") {
    KineticOnboardingView(onComplete: {}, forcedHeld: true)
        .preferredColorScheme(.dark)
}

// MARK: - Pulsing dots (custom "something is being made" indicator)

/// Three white dots that pulse in sequence like a heartbeat. Replaces the
/// stock `ProgressView` in shimmer cells so every "in-flight" moment in the
/// journey shares one indicator language.
private struct PulsingDots: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animating = false
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(.white)
                    .frame(width: 8, height: 8)
                    .scaleEffect(reduceMotion ? 0.75 : (animating ? 1.0 : 0.5))
                    .opacity(reduceMotion ? 0.7 : (animating ? 1.0 : 0.4))
                    .animation(
                        reduceMotion
                            ? nil
                            : .easeInOut(duration: 0.65)
                                .repeatForever()
                                .delay(Double(i) * 0.18),
                        value: animating
                    )
            }
        }
        .onAppear { if !reduceMotion { animating = true } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("In progress")
    }
}

// MARK: - Grid

private struct GridView: View {
    @Bindable var viewModel: GenerateViewModel
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    private var visibleVideos: [GeneratedVideo] {
        switch viewModel.filter {
        case .all, .videos: return viewModel.videos
        case .liked: return viewModel.videos.filter { viewModel.likeStore.isLiked($0.id) }
        }
    }

    private var visiblePendingVideos: [PendingVideo] {
        switch viewModel.filter {
        case .all, .videos: return viewModel.pendingVideos
        case .liked: return []
        }
    }

    private var visiblePendingImages: [PendingImage] {
        viewModel.filter == .all ? viewModel.pendingImages : []
    }

    private var visiblePendingGenerations: [PendingGeneration] {
        viewModel.filter == .all ? viewModel.pendingGenerations : []
    }

    private var hasNoContent: Bool {
        let imagesEmpty = viewModel.filter == .videos
            || (viewModel.filteredImages.isEmpty
                && visiblePendingImages.isEmpty
                && visiblePendingGenerations.isEmpty)
        let videosEmpty = visibleVideos.isEmpty && visiblePendingVideos.isEmpty
        return imagesEmpty && videosEmpty
    }

    private var shouldSection: Bool {
        viewModel.filter == .all && viewModel.audiolines != nil
    }

    /// Filter pills only earn their space once there's something real to
    /// filter. Pendings don't count — they're transient. Without this guard
    /// the user sees "All / Liked / Videos" before any of those categories
    /// have ever held an item, which reads as noise on the first paint.
    private var hasFilterableContent: Bool {
        !viewModel.images.isEmpty || !viewModel.videos.isEmpty
    }

    /// True only on the very first batch: nothing has landed yet and shimmer
    /// cells are pending. Gives us a moment to carry the user with a status
    /// line above the empty grid.
    private var isInitialBatchInFlight: Bool {
        viewModel.images.isEmpty
            && viewModel.videos.isEmpty
            && !viewModel.pendingGenerations.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            if hasFilterableContent {
                filterBar
            }
            if isInitialBatchInFlight {
                Text("Three from your idea coming up…")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .transition(.opacity)
            }
            if hasNoContent {
                emptyState
            } else if shouldSection, let audiolines = viewModel.audiolines {
                sectionedScroll(audiolines: audiolines)
            } else {
                flatScroll
            }
        }
    }

    private var flatScroll: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                if viewModel.filter != .videos {
                    ForEach(visiblePendingImages) { pendingImageCell($0) }
                    ForEach(visiblePendingGenerations) { pendingGenerationCell($0) }
                    ForEach(viewModel.filteredImages) { imageCell($0) }
                }
                ForEach(visiblePendingVideos) { pendingCell($0) }
                ForEach(visibleVideos) { videoCell($0) }
            }
            .padding(.horizontal, 2)
            .padding(.top, 6)
        }
        .contentMargins(.bottom, bottomChromeMargin, for: .scrollContent)
    }

    @ViewBuilder
    private func sectionedScroll(audiolines: [SongLine]) -> some View {
        // Top block: uploads in flight + pending videos that don't yet have
        // a line (e.g. video pending before lyrics were pasted). Once they
        // resolve / lyrics backfill, they'll move into their line section.
        let unlinedPendingVideos = visiblePendingVideos.filter { $0.lineIndex == nil }
        let unlinedVideos = visibleVideos.filter { $0.lineIndex == nil }
        return ScrollView {
            LazyVStack(spacing: 0) {
                if !visiblePendingImages.isEmpty || !unlinedPendingVideos.isEmpty {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(visiblePendingImages) { pendingImageCell($0) }
                        ForEach(unlinedPendingVideos) { pendingCell($0) }
                    }
                    .padding(.horizontal, 2)
                    .padding(.top, 6)
                }

                ForEach(audiolines) { line in
                    let imagesForLine = viewModel.filteredImages.filter { $0.lineIndex == line.index }
                    let pendingsForLine = visiblePendingGenerations.filter { $0.lineIndex == line.index }
                    let videosForLine = visibleVideos.filter { $0.lineIndex == line.index }
                    let pendingVideosForLine = visiblePendingVideos.filter { $0.lineIndex == line.index }
                    Section {
                        if !pendingsForLine.isEmpty
                            || !imagesForLine.isEmpty
                            || !pendingVideosForLine.isEmpty
                            || !videosForLine.isEmpty {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(pendingsForLine) { pendingGenerationCell($0) }
                                ForEach(imagesForLine) { imageCell($0) }
                                ForEach(pendingVideosForLine) { pendingCell($0) }
                                ForEach(videosForLine) { videoCell($0) }
                            }
                            .padding(.horizontal, 2)
                            .padding(.top, 4)
                        }
                    } header: {
                        sectionHeader(
                            line: line,
                            imageCount: imagesForLine.count + pendingsForLine.count
                                + videosForLine.count + pendingVideosForLine.count
                        )
                    }
                }

                if !unlinedVideos.isEmpty {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(unlinedVideos) { videoCell($0) }
                    }
                    .padding(.horizontal, 2)
                    .padding(.top, 12)
                }
            }
        }
        .contentMargins(.bottom, bottomChromeMargin, for: .scrollContent)
    }

    /// Bottom margin the scrolls reserve so the last row clears whichever
    /// bottom chrome is currently visible (Make video shelf or tab bar).
    /// `safeAreaInset` on the outer container doesn't propagate cleanly into
    /// an inner scroll through NavigationStack, so we account for it here.
    private var bottomChromeMargin: CGFloat {
        if viewModel.isSelectingForVideo { return 80 }
        if viewModel.revealEditorTab { return 72 }
        return 0
    }

    @ViewBuilder
    private func sectionHeader(line: SongLine, imageCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(line.text)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.onSurface)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text(imageCount == 0 ? "No pictures yet"
                                : "\(imageCount) \(imageCount == 1 ? "picture" : "pictures")")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 28)
        .padding(.bottom, 10)
        .contextMenu {
            Button {
                viewModel.fillLine(line.index)
            } label: {
                Label("Make pictures for this line", systemImage: "sparkles")
            }
        }
        .accessibilityLabel(line.text)
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: emptyIcon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.muted)
            Text(emptyTitle)
                .font(.headline)
                .foregroundStyle(Theme.onSurface)
            Text(emptyBody)
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyIcon: String {
        switch viewModel.filter {
        case .all: "photo.on.rectangle"
        case .liked: "heart"
        case .videos: "film"
        }
    }
    private var emptyTitle: String {
        switch viewModel.filter {
        case .all: "No pictures yet"
        case .liked: "Nothing hearted yet"
        case .videos: "No videos yet"
        }
    }
    private var emptyBody: String {
        switch viewModel.filter {
        case .all: "Tap Start to make your first ones."
        case .liked: "Tap the heart on a picture to save it. Saved pictures can become videos."
        case .videos: "Heart a few pictures, then make a video."
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(GenerateViewModel.GridFilter.allCases, id: \.self) { f in
                Button {
                    withAnimation(.spring) { viewModel.filter = f }
                } label: {
                    Text(f.label)
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .background {
                    if viewModel.filter == f {
                        Capsule().fill(Theme.accentMagenta.opacity(0.25))
                            .overlay(Capsule().stroke(Theme.accentMagenta.opacity(0.6), lineWidth: 1))
                    } else {
                        Capsule().fill(.white.opacity(0.08))
                    }
                }
                .foregroundStyle(viewModel.filter == f ? Theme.onSurface : Theme.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    @ViewBuilder
    private func imageCell(_ image: GeneratedImage) -> some View {
        let liked = viewModel.likeStore.isLiked(image.id)
        let selecting = viewModel.isSelectingForVideo
        let selected = viewModel.selectedImageIds.contains(image.id)
        let eligible = !selecting || liked

        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                AuthorizedImage(filename: image.file)
            }
            .clipped()
            .overlay {
                if selecting && selected {
                    Theme.accentMagenta.opacity(0.18)
                }
            }
            .overlay(alignment: .topTrailing) {
                if selecting {
                    if eligible {
                        selectionBadge(order: viewModel.selectedImageIds.firstIndex(of: image.id))
                    }
                } else {
                    heartButton(isLiked: liked) {
                        viewModel.toggleLikeImage(image)
                    }
                }
            }
            .opacity(eligible ? 1 : 0.3)
            .contentShape(.rect)
            .onTapGesture {
                if selecting {
                    guard eligible else { return }
                    withAnimation(.spring(duration: 0.25)) {
                        viewModel.toggleSelection(image.id)
                    }
                } else {
                    viewModel.openDerive(image)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                selecting
                    ? (selected ? "Picture, selected" : "Picture, double tap to select")
                    : "Picture, double tap to remake"
            )
            .accessibilityValue(liked ? "Saved" : "")
    }

    @ViewBuilder
    private func selectionBadge(order: Int?) -> some View {
        ZStack {
            if let order {
                Text("\(order + 1)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Theme.accent, in: .circle)
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
            } else {
                Circle()
                    .stroke(.white.opacity(0.9), lineWidth: 1.5)
                    .background(Circle().fill(.black.opacity(0.25)))
                    .frame(width: 26, height: 26)
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 4, y: 1)
        .padding(8)
    }

    @ViewBuilder
    private func pendingImageCell(_ pending: PendingImage) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZStack {
                    Theme.surface
                    if pending.state == .working {
                        Shimmer()
                        VStack(spacing: 10) {
                            PulsingDots()
                            Text("Uploading…")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                            Text("Upload failed — tap to dismiss")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                    }
                }
            }
            .clipped()
            .contentShape(.rect)
            .onTapGesture {
                if pending.state == .failed {
                    viewModel.dismissPendingImage(pending.id)
                }
            }
    }

    @ViewBuilder
    private func pendingGenerationCell(_ pending: PendingGeneration) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZStack {
                    Theme.surface
                    if pending.state == .working {
                        Shimmer()
                        VStack(spacing: 10) {
                            PulsingDots()
                            Text("Making…")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                            Text("Failed — tap to dismiss")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                    }
                }
            }
            .clipped()
            .contentShape(.rect)
            .onTapGesture {
                if pending.state == .failed {
                    viewModel.dismissPendingGeneration(pending.id)
                }
            }
    }

    @ViewBuilder
    private func pendingCell(_ pending: PendingVideo) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZStack {
                    AuthorizedImage(filename: pending.posterFile)
                        .opacity(pending.state == .failed ? 0.5 : 0.4)
                    if pending.state == .working {
                        VStack(spacing: 10) {
                            PulsingDots()
                            Text("Making…")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                            Text("Failed — tap to dismiss")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                    }
                }
            }
            .clipped()
            .contentShape(.rect)
            .onTapGesture {
                if pending.state == .failed {
                    viewModel.dismissPendingVideo(pending.id)
                }
            }
    }

    @ViewBuilder
    private func videoCell(_ video: GeneratedVideo) -> some View {
        let selecting = viewModel.isSelectingForVideo
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZStack {
                    if let url = Media.url(video.file) {
                        AuthorizedVideoView(url: url)
                    } else {
                        AuthorizedImage(filename: video.posterFile)
                    }
                    Image(systemName: "play.circle.fill").font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.85)).shadow(radius: 4)
                }
            }
            .clipped()
            .overlay(alignment: .topTrailing) {
                if !selecting {
                    heartButton(isLiked: viewModel.likeStore.isLiked(video.id)) {
                        viewModel.toggleLikeVideo(video)
                    }
                }
            }
            .opacity(selecting ? 0.3 : 1)
            .contentShape(.rect)
            .onTapGesture {
                guard !selecting else { return }
                viewModel.viewingVideo = video
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Video, double tap to watch")
            .accessibilityValue(viewModel.likeStore.isLiked(video.id) ? "Saved" : "")
    }

    @ViewBuilder
    private func heartButton(isLiked: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(duration: 0.35)) { action() }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            if isLiked {
                Image(systemName: "heart.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(7)
                    .background(Theme.accent, in: .circle)
                    .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 1)
            } else {
                Image(systemName: "heart")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(7)
                    .background(.ultraThinMaterial, in: .circle)
                    .overlay(Circle().stroke(.white.opacity(0.4), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.35), radius: 4, y: 1)
            }
        }
        .buttonStyle(.plain)
        .padding(8)
        .contentTransition(.symbolEffect(.replace))
        .accessibilityLabel(isLiked ? "Saved, double tap to unsave" : "Save")
    }
}

// MARK: - Derive

private struct DeriveView: View {
    let image: GeneratedImage
    @Bindable var viewModel: GenerateViewModel
    @State private var tweak: String = ""
    @FocusState private var focused: Bool

    private var trimmed: String {
        tweak.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                AuthorizedImage(filename: image.file)
                    .frame(width: 64, height: 64)
                    .clipShape(.rect(cornerRadius: 12))
                    .accessibilityLabel("Picture you tapped")
                VStack(alignment: .leading, spacing: 2) {
                    Text("From this one")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                    Text("Tell me what to change")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.onSurface)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            TextField(
                "Try \u{201C}sunset\u{201D} or \u{201C}add fireworks\u{201D}",
                text: $tweak,
                axis: .vertical
            )
            .focused($focused)
            .font(.body)
            .lineLimit(3...8)
            .foregroundStyle(Theme.onSurface)
            .padding(16)
            .background(Theme.surface, in: .rect(cornerRadius: 16))
            .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Change it")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = true }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = false }
                    .font(.body.weight(.semibold))
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                focused = false
                viewModel.submitDerivation(from: image, tweak: trimmed)
            } label: {
                Text(trimmed.isEmpty ? "Type to make new ones" : "Make new ones")
                    .animation(.easeInOut(duration: 0.15), value: trimmed.isEmpty)
            }
            .buttonStyle(AccentButtonStyle())
            .disabled(trimmed.isEmpty)
            .padding(16)
            .background(.regularMaterial)
        }
    }
}

// MARK: - Topup

private struct TopupSheet: View {
    @Bindable var viewModel: GenerateViewModel

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(.white.opacity(0.2)).frame(width: 40, height: 4).padding(.top, 8)
            VStack(spacing: 6) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Theme.accent)
                Text("Top up to continue").font(.title2.bold())
                    .foregroundStyle(Theme.onSurface)
                Text("You need more credits to run this generation. Pick a pack:")
                    .font(.footnote).foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center).padding(.horizontal, 24)
            }
            VStack(spacing: 10) {
                ForEach(StoreService.Tier.allCases) { tier in
                    let product = viewModel.store.products[tier]
                    Button {
                        Task { await viewModel.purchase(tier) }
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tier.displayName).font(.headline)
                                    .foregroundStyle(Theme.onSurface)
                                Text(tier.blurb).font(.caption).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Text(product?.displayPrice ?? "—").font(.title3.weight(.bold))
                                .foregroundStyle(Theme.accent)
                        }
                        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surface, in: .rect(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .stroke(Theme.accentMagenta.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain).disabled(product == nil)
                }
            }
            .padding(.horizontal, 16)
            if let err = viewModel.store.error {
                Text(err).font(.caption).foregroundStyle(.red).padding(.horizontal, 16)
            }
            Button("Not now", action: viewModel.dismissTopup)
                .buttonStyle(.glass).padding(.bottom, 16)
        }
        .padding(.bottom, 16).background(.regularMaterial)
        .clipShape(.rect(cornerRadii: .init(topLeading: 28, topTrailing: 28)))
        .task { await viewModel.store.loadProducts() }
    }
}

