//
//  ContentView.swift
//  Generate
//
//  Single-file flagship Generate screen.
//  Tutorial wizard: onboarding → start CTA → grid → derive → like → compose video → done.
//

import SwiftUI
import AVKit
import AVFoundation
import PhotosUI
import Observation
import FoundationModels
import Api

// MARK: - Routing

/// Stack-driven app navigation. `ContentView` owns the path; `Generate` and
/// the derive destination push/pop these cases as the user moves.
enum AppRoute: Hashable {
    /// Push the GenerateNew ("Change it") screen for the source image with this filename.
    case derive(String)
    /// Push a Generate destination with a generation intent — the destination
    /// view fires the upsert + poll for that action on appear.
    case generate(GenerateAction)
}

/// Generation intents handed to a pushed Generate destination via routing.
enum GenerateAction: Hashable {
    /// User submitted a "tell me what to change" prompt for `filename`.
    case deriveImage(text: String, filename: String)
}

// MARK: - App root

/// Root view of the Generate2 app. Takes a tokenid from the parent app (or
/// the hardcoded dev token in standalone runs) and installs it as the API
/// bearer before any route fires.
struct ContentView: View {
    let tokenid: String
    /// Parent app's topup handler. Generate2 calls this when credits are
    /// insufficient; the parent shows its own purchase UI and resolves true
    /// on success, false on cancel/failure. Default = no topup available.
    let onTopupNeeded: () async -> Bool
    @State private var path: [AppRoute] = []

    init(tokenid: String, onTopupNeeded: @escaping () async -> Bool = { false }) {
        self.tokenid = tokenid
        self.onTopupNeeded = onTopupNeeded
        UserDefaults.standard.set(tokenid, forKey: "idToken")
        ApiAPIConfiguration.shared.customHeaders["Authorization"] = "Bearer \(tokenid)"
    }

    var body: some View {
        NavigationStack(path: $path) {
            Generate(appPath: $path, action: nil, onTopupNeeded: onTopupNeeded)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .derive(let filename):
                        GenerateNew(filename: filename, path: $path)
                    case .generate(let action):
                        Generate(appPath: $path, action: action, onTopupNeeded: onTopupNeeded)
                    }
                }
        }
    }
}

// MARK: - Auth context (set once at app launch in GenerateApp.swift)

fileprivate enum AppAuth {
    static var bearer: String {
        UserDefaults.standard.string(forKey: "idToken") ?? ""
    }
    static var userId: String {
        jwtSub() ?? ""
    }
}

/// Dev seed flag — set true to pre-populate FemiGenerateViewModel with a sample
/// project + bundled images. Off for normal runs.
private let devSeedEnabled = false

// MARK: - FemiTheme

enum FemiTheme {
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

struct FemiAccentButtonStyle: ButtonStyle {
    var fullWidth: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 0 : 28)
            .background(FemiTheme.accent, in: .capsule)
            .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
            .shadow(color: FemiTheme.accentMagenta.opacity(0.35), radius: 18, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Local models (client-side state)

struct FemiGeneratedImage: Identifiable, Hashable, Sendable {
    enum Source: String, Sendable { case zimage, nanoBanana, flux2, upload, unknown }
    let id: UUID
    let file: String
    let prompt: String
    let source: Source
    /// Index into `FemiGenerateViewModel.audiolines`. Nil before lyrics are pasted.
    /// Drives the Photos-style by-line grouping in the grid.
    var lineIndex: Int? = nil
}

/// A single timed lyric line. Server-side forced alignment is the production
/// path; the client stub in `pasteLyrics` assigns equal 6s windows as a
/// placeholder until that pipeline exists.
struct FemiSongLine: Identifiable, Hashable, Sendable {
    let id: UUID
    let index: Int
    let text: String
    let startMs: Int
    let durationMs: Int
}

struct FemiGeneratedVideo: Identifiable, Hashable, Sendable {
    let id: UUID
    let file: String
    let posterFile: String
    let sourceImageIds: [UUID]
}

/// A video that's being generated in the background. The grid renders this as a
/// shimmer cell so the user can keep doing other things while it cooks.
struct FemiPendingVideo: Identifiable, Hashable, Sendable {
    enum State: Hashable, Sendable { case working, failed }
    let id: UUID
    let sourceImageIds: [UUID]
    let posterFile: String
    var state: State = .working
}

/// An image being uploaded from the user's photo library. Mirrors FemiPendingVideo —
/// the grid shows a shimmer cell while the upload happens in the background.
struct FemiPendingImage: Identifiable, Hashable, Sendable {
    enum State: Hashable, Sendable { case working, failed }
    let id: UUID
    var state: State = .working
}

/// An in-flight image generation (derive or fill-line). Rendered as a shimmer
/// cell in the grid so the rest of the UI stays interactive. `lineIndex` is
/// pre-computed at task start so the cell lands in the correct section.
struct FemiPendingGeneration: Identifiable, Hashable, Sendable {
    enum State: Hashable, Sendable { case working, failed }
    let id: UUID
    let lineIndex: Int?
    var state: State = .working
}

// MARK: - POST /api (Generate, Poll, Chat)

private enum FemiApiRoute {
    static var emptyPay: ApiPay {
        ApiPay(
            currency: "",
            id: UUID(),
            jws: "",
            loaded: false,
            packageName: "",
            price: 0,
            productId: "",
            provider: .apple,
            refId: "",
            userId: AppAuth.userId
        )
    }

    static var emptyPricing: ApiPricing {
        ApiPricing(
            artist: 0, audio: 0, chat: 0, creator: 0, director: 0,
            falFlux2Pro: 0, falNanoBanana2: 0, falZImageTurbo: 0,
            gb: 0, generate: 0, id: UUID(), image: 0, lyricSync: 0,
            microPixLyra: 0, microPixVega: 0, nanoPixLuna: 0, nanoRenSpica: 0,
            question: 0, summary: 0, upload: 0
        )
    }

    /// Server requires `messages` on every POST /api; empty arrays are omitted from multipart.
    private static func wireMessages(_ messages: [ApiChatMessage]) -> [ApiChatMessage] {
        messages.isEmpty ? [ApiChatMessage(content: "", role: .user)] : messages
    }

    static func call(
        action: ApiAction,
        audio: String = "",
        credit: Int64 = 0,
        file: String = "",
        id: UUID = UUID(),
        image: String = "",
        messages: [ApiChatMessage] = [],
        model: ApiAiModel = .zimageturbo,
        prompt: String = "",
        requestId: String = "",
        status: ApiStatus = .pending
    ) async throws -> API {
        try await ApiRouteAPI.api(
            action: action,
            audio: audio,
            balance: 0,
            credit: credit,
            file: file,
            id: id,
            image: image,
            messages: wireMessages(messages),
            model: model,
            pay: emptyPay,
            pricing: emptyPricing,
            prompt: prompt,
            requestId: requestId,
            status: status,
            userId: AppAuth.userId
        )
    }

    static func assistantReply(in messages: [ApiChatMessage], fallback: String) -> String {
        messages.last(where: { $0.role == .assistant })?.content ?? fallback
    }
}

// MARK: - Derive prompt (GenerateNew → Generate route; not FemiGenerateAPI)

private enum DerivePrompt {
    private static let max = 400

    static func enrich(prior: String, tweak: String) async throws -> String {
        var messages: [ApiChatMessage] = []
        let instruction: String
        if prior.isEmpty {
            instruction = "Make one concise image prompt (max 300 characters): \(tweak)"
        } else {
            messages.append(ApiChatMessage(content: prior, role: .assistant))
            instruction = "Rewrite the image prompt with this change. One concise prompt only (max 300 characters). Change: \(tweak)"
        }
        messages.append(ApiChatMessage(content: instruction, role: .user))
        let response = try await FemiApiRoute.call(action: .chat, messages: messages)
        let reply = FemiApiRoute.assistantReply(in: response.messages, fallback: tweak)
        return reply.count <= max ? reply : String(reply.prefix(max))
    }
}

// MARK: - API service wrapper

struct FemiGenerateAPI: Sendable {

    func currentBalance() async throws -> Int64 {
        try await FemiApiRoute.call(action: .balance).balance
    }

    func currentPricing() async throws -> ApiPricing {
        try await FemiApiRoute.call(action: .pricing).pricing
    }

    // The generated `ProjectRouteAPI.project` is now an upsert (flat fields),
    // not a paginate-style list. Stubbed until a list endpoint exists.
    func latestProject() async throws -> Project? { nil }
    func allProjects() async throws -> [Project] { [] }

    /// Hard cap on prompt size before sending to image models.
    /// The image models (Vega in particular) reject prompts above this length.
    private let imagePromptMax = 400

    private func capped(_ s: String) -> String {
        s.count <= imagePromptMax ? s : String(s.prefix(imagePromptMax))
    }

    func chatPrompt(_ seed: String) async throws -> String {
        let instruction = "Write one concise image-generation prompt (max 300 characters) for this scene: \(seed)"
        let messages = [ApiChatMessage(content: instruction, role: .user)]
        let response = try await FemiApiRoute.call(action: .chat, messages: messages)
        let reply = FemiApiRoute.assistantReply(in: response.messages, fallback: seed)
        return capped(reply)
    }

    /// Upsert all three text-to-image models and return server `request_id`s
    /// immediately so the UI can poll while bytes are still generating.
    func startImageBatch(prompt: String) async -> [String] {
        await withTaskGroup(of: String?.self) { group in
            group.addTask { await startOne(model: .zimageturbo, prompt: prompt) }
            group.addTask { await startOne(model: .nanoBanana2, prompt: prompt) }
            group.addTask { await startOne(model: .flux2Pro, prompt: prompt) }
            var ids: [String] = []
            for await result in group {
                if let id = result { ids.append(id) }
            }
            return ids
        }
    }

    /// Fan out 3 text-to-image models in parallel: ZImageTurbo, NanoBanana2,
    /// Flux2Pro. Yields each image as it lands so the UI can swap shimmer
    /// cells one-by-one instead of waiting on the slowest model. Failed models
    /// produce no yield — the call site marks the leftover pending `.failed`.
    func generateImageBatch(prompt: String) -> AsyncStream<FemiGeneratedImage> {
        AsyncStream { continuation in
            let task = Task {
                await withTaskGroup(of: FemiGeneratedImage?.self) { group in
                    group.addTask { await runOne(model: .zimageturbo, source: .zimage, prompt: prompt) }
                    group.addTask { await runOne(model: .nanoBanana2, source: .nanoBanana, prompt: prompt) }
                    group.addTask { await runOne(model: .flux2Pro, source: .flux2, prompt: prompt) }
                    for await result in group {
                        if let img = result { continuation.yield(img) }
                    }
                    continuation.finish()
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private var pollInterval: Duration { .seconds(30) }
    private var pollTimeout: Duration { .seconds(120) }

    private func startOne(model: ApiAiModel, prompt: String) async -> String? {
        guard let started = try? await FemiApiRoute.call(
            action: .generate,
            model: model,
            prompt: capped(prompt),
            status: .pending
        ), !started.requestId.isEmpty else { return nil }
        return started.requestId
    }

    private func runOne(
        model: ApiAiModel,
        source: FemiGeneratedImage.Source,
        prompt: String
    ) async -> FemiGeneratedImage? {
        guard let requestId = await startOne(model: model, prompt: prompt),
              let done = try? await pollGenerate(requestId: requestId) else { return nil }
        return FemiGeneratedImage(id: done.id, file: done.file, prompt: done.prompt, source: source)
    }

    func pollGenerate(requestId: String) async throws -> API {
        let started = ContinuousClock.now
        while ContinuousClock.now - started <= pollTimeout {
            let row = try await FemiApiRoute.call(action: .poll, requestId: requestId)
            switch row.status {
            case .completed: return row
            case .failed: throw NSError(domain: "Generate", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Generation failed"])
            case .pending: break
            }
            try await Task.sleep(for: pollInterval)
        }
        throw NSError(domain: "Generate", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Timed out"])
    }

    fileprivate static func source(for model: ApiAiModel) -> FemiGeneratedImage.Source {
        switch model {
        case .zimageturbo: return .zimage
        case .nanoBanana2: return .nanoBanana
        case .flux2Pro: return .flux2
        case .ltx23a2v: return .unknown
        }
    }

    /// Image-to-video via POST /api (Ltx2_3A2V). Starts pending, polls until Completed.
    func generateVideo(
        imageFile: String,
        audioFile: String,
        prompt: String
    ) async throws -> String {
        let started = try await FemiApiRoute.call(
            action: .generate,
            audio: audioFile,
            image: imageFile,
            model: .ltx23a2v,
            prompt: capped(prompt),
            status: .pending
        )
        guard !started.requestId.isEmpty else {
            throw NSError(domain: "Video", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No request_id returned"])
        }
        let done = try await pollGenerate(requestId: started.requestId)
        guard !done.file.isEmpty else {
            throw NSError(domain: "Video", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Completed but no file"])
        }
        return done.file
    }

    /// Required pre-step for video: register an existing generated image as an Image record.
    /// Downloads bytes from femi.market then re-uploads via /upload.
    func registerImageForVideo(filename: String) async throws -> String {
        let data = try await MediaApi.fetch(filename, idToken: AppAuth.bearer)
        return try await upload(data: data,
                                suggestedName: (filename as NSString).lastPathComponent)
    }

    /// Upload binary bytes to `/upload`. Writes to `Documents/<suggestedName>`
    /// so the generated route's multipart encoder can stream the file (it
    /// resolves bare filenames against the app's Documents dir), then deletes
    /// the temp file. Returns the server-assigned filename.
    func upload(data: Data, suggestedName: String) async throws -> String {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localURL = dir.appendingPathComponent(suggestedName)
        try data.write(to: localURL)
        defer { try? FileManager.default.removeItem(at: localURL) }
        let result = try await UploadRouteAPI.upload(
            credit: 0,
            episodes: [],
            file: suggestedName,
            id: UUID(),
            model: .unknown,
            project: 0,
            prompt: "",
            rating: 0,
            userId: AppAuth.userId
        )
        return result.file
    }

    // MARK: - Line-scoped audio for video generation

    /// Downloads the project audio, trims to `(startMs, durationMs)` via
    /// AVAssetExportSession, uploads the slice as a new Audio record, returns
    /// the resulting server filename. Caller passes the trimmed filename to
    /// POST /api video generation so the audio-conditioned video matches the
    /// moment in the song. Throws on any step — caller is expected to fall
    /// back to the full project audio.
    func trimAndUploadAudioClip(
        sourceAudioFile: String,
        startMs: Int,
        durationMs: Int
    ) async throws -> String {
        // 1) Fetch source bytes (MediaApi.session caches so repeated trims for
        // the same song don't re-download).
        let data = try await MediaApi.fetch(sourceAudioFile, idToken: AppAuth.bearer)
        let tempDir = FileManager.default.temporaryDirectory
        let sourceLocal = tempDir.appendingPathComponent("source-\(UUID().uuidString).m4a")
        try data.write(to: sourceLocal)
        defer { try? FileManager.default.removeItem(at: sourceLocal) }

        // 2) Trim with AVAssetExportSession.
        let asset = AVURLAsset(url: sourceLocal)
        guard let exporter = AVAssetExportSession(
            asset: asset, presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw NSError(domain: "Audio", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No exporter for asset"])
        }
        let outputURL = tempDir.appendingPathComponent("clip-\(UUID().uuidString).m4a")
        let start = CMTime(value: Int64(startMs), timescale: 1000)
        let dur = CMTime(value: Int64(durationMs), timescale: 1000)
        exporter.timeRange = CMTimeRange(start: start, duration: dur)
        try await exporter.export(to: outputURL, as: .m4a)
        defer { try? FileManager.default.removeItem(at: outputURL) }

        // 3) Upload trimmed clip via /upload.
        let clipData = try Data(contentsOf: outputURL)
        return try await upload(data: clipData,
                                suggestedName: "clip-\(UUID().uuidString).m4a")
    }
}

// MARK: - Onboarding audio (app-scoped, primed at launch)

/// App-scoped singleton. `prepare(...)` runs the heavy work (bundle URL
/// lookup, decode, prepareToPlay) off-main. Call it once at launch — by the
/// time the splash appears the player is sitting ready. `start()` is the hot
/// path: no I/O, just `play()` on main. Per engine: heavy work runs detached,
/// then hands off — the interactive moment never blocks on I/O.
@MainActor @Observable
final class FemiOnboardingAudio {
    static let shared = FemiOnboardingAudio()

    private var player: AVAudioPlayer?
    private var hasStarted = false
    private var preparing = false

    private init() {}

    /// Idempotent. Loads + decodes the WAV off-main. Safe to call repeatedly.
    func prepare(resource: String, ext: String) {
        guard player == nil, !preparing else { return }
        preparing = true
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let url = Bundle.main.url(forResource: resource, withExtension: ext)
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
                }
            } catch {
                await MainActor.run { [weak self] in self?.preparing = false }
            }
        }
    }

    /// Splash mount calls this. Player is always primed by app-launch
    /// `prepare(...)` — by the time the user picks a song, previews it, and
    /// taps "Use this song", prepare has finished. Just session-activate + play().
    func start(resource _: String, ext _: String) {
        guard !hasStarted, let p = player else { return }
        hasStarted = true
        try? AVAudioSession.sharedInstance().setCategory(
            .ambient, mode: .default, options: [.mixWithOthers]
        )
        try? AVAudioSession.sharedInstance().setActive(true)
        p.play()
        p.setVolume(0.6, fadeDuration: 0.3)
    }

    /// Cross-fades to silence over `duration` seconds, then releases the session.
    /// Idempotent — calling again after a fade is in flight is a no-op.
    func fadeOut(duration: TimeInterval = 0.6) {
        guard let p = player else { return }
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

// MARK: - Local store (UploadSong filename for toolbar)
//
// `UploadSong` → actual audio filename saved under Documents/<Project>/.

enum FemiLocalStore {
    private static let uploadSongKey = "UploadSong"

    static var uploadSong: String? {
        get { UserDefaults.standard.string(forKey: uploadSongKey) }
        set {
            if let v = newValue { UserDefaults.standard.set(v, forKey: uploadSongKey) }
            else { UserDefaults.standard.removeObject(forKey: uploadSongKey) }
        }
    }
}

// MARK: - Like store (client-only, UserDefaults)

@MainActor @Observable
final class FemiLikeStore {
    /// In-memory likes for images and session-only video likes.
    var liked: Set<String> = []
    func isLiked(_ id: UUID) -> Bool { liked.contains(id.uuidString) }
    func toggle(_ id: UUID) {
        if liked.contains(id.uuidString) { liked.remove(id.uuidString) }
        else { liked.insert(id.uuidString) }
    }
    func setLiked(_ id: UUID, _ value: Bool) {
        if value { liked.insert(id.uuidString) }
        else { liked.remove(id.uuidString) }
    }
}

// MARK: - View model

@MainActor @Observable
final class FemiGenerateViewModel {

    enum GenerationKind: Hashable { case initial, derived, video }

    enum Phase: Hashable {
        case onboarding
        case generating(GenerationKind)
        case grid
        case derive(image: FemiGeneratedImage)
        case complete
    }

    enum TutorialMoment: Hashable {
        case none, likeAnImage, selectLikedForVideo, likeYourVideo
    }

    enum GridFilter: Hashable, CaseIterable {
        case all, liked, videos
        var label: String {
            switch self { case .all: "All"; case .liked: "Liked"; case .videos: "Videos" }
        }
    }

    var phase: Phase = .grid
    var tutorialMoment: TutorialMoment = .none
    var filter: GridFilter = .all

    // In-grid Photos-style select-for-video mode.
    var isSelectingForVideo: Bool = false
    var selectedImageIds: [UUID] = []

    // Video detail playback (with sound).
    var viewingVideo: FemiGeneratedVideo? = nil

    var project: Project?
    var images: [FemiGeneratedImage] = []
    var videos: [FemiGeneratedVideo] = []
    var pendingVideos: [FemiPendingVideo] = []
    var pendingImages: [FemiPendingImage] = []
    var pendingGenerations: [FemiPendingGeneration] = []

    var credit: Credit?
    var pricing: ApiPricing?
    var loadingBalance = false
    var errorMessage: String?

    /// Parent-supplied async topup handler. Set by `Generate` on appear from
    /// the `onTopupNeeded` arg threaded down from `ContentView`. The gate
    /// awaits this when credits run dry — parent shows its own sheet, resolves
    /// the closure when its purchase flow completes (success or cancel).
    var onTopupNeeded: (() async -> Bool)?
    var presentingLyricPaste = false
    var presentingProjects = false
    var presentingNewSong = false

    /// All of the user's projects, loaded via paginate. Drives the toolbar
    /// switcher list. Includes the current project.
    var allProjects: [Project] = []

    /// Pasted lyrics text. Nil until the user pastes via the scene-player
    /// affordance. Once set, the grid switches from flat to sectioned-by-line.
    var lyrics: String?
    /// Timed lyric lines. Populated by `pasteLyrics`. Nil before paste.
    var audiolines: [FemiSongLine]?

    let likeStore = FemiLikeStore()
    let onboardingAudio = FemiOnboardingAudio.shared
    private let service = FemiGenerateAPI()  // renamed from GenerateService to avoid DemoGenerate.swift collision

    init() {
        if devSeedEnabled { devSeed() }
        seedDummyProjectsForUIDemo()
    }

    /// Temporary: populate `allProjects` with 10 placeholder Projects so the
    /// Recent + A-Z + search UI in `ProjectsSheet` is visible without real
    /// data. Names are NATO phonetic so they're clearly placeholders and
    /// give A-Z spread. Remove this when real projects exist.
    private func seedDummyProjectsForUIDemo() {
        let names = [
            "Alpha", "Bravo", "Charlie", "Delta", "Echo",
            "Foxtrot", "Golf", "Hotel", "India", "Juliett",
        ]
        let dummies = names.map { name in
            Project(
                about: "", audio: "\(name.lowercased()).mp3", audioLines: [],
                faqs: [], genre: "", id: UUID(), playlist: "",
                seasons: [], summary: name, userId: AppAuth.userId
            )
        }
        self.allProjects = dummies
        self.project = dummies.first
    }

    /// Dev seed: skip Song → splash → CTA → first generation and land
    /// in the grid pre-populated with a project + 3 images. Audio + image
    /// filenames point at bundled assets so `FemiAuthorizedImage`'s dev-mode
    /// bundle short-circuit can render them without a network call. The
    /// `summary` is derived from the audio file's name exactly like
    /// `handleSongPicked` does — same code path as production.
    private func devSeed() {
        let seedProject = Project(
            about: "",
            audio: "9f420313-7a42-4e12-8367-24751afba0eb.mp3",
            audioLines: [],
            faqs: [],
            genre: "",
            id: UUID(),
            playlist: "",
            seasons: [],
            summary: "",
            userId: AppAuth.userId
        )
        self.allProjects = [seedProject]
        self.project = seedProject
        self.images = [
            "019e7f3d-7bff-7901-ac73-8c7372b56330.png",
            "019e7f3d-a3c0-7e63-a239-d84846529654.png",
            "019e7f3d-aa21-7173-86ae-fbe8d61d0a84.png",
        ].map { name in
            FemiGeneratedImage(
                id: UUID(),
                file: name,
                prompt: "Dev seed",
                source: .zimage
            )
        }
        self.phase = .grid
    }

    // Derived

    var filteredImages: [FemiGeneratedImage] {
        switch filter {
        case .all, .videos: images
        case .liked: images.filter { likeStore.isLiked($0.id) }
        }
    }
    var likedImages: [FemiGeneratedImage] { images.filter { likeStore.isLiked($0.id) } }

    /// chat + 3 image models (ZImageTurbo, NanoBanana2, Flux2Pro). Bandwidth shown separately.
    var generationCost: Int64 {
        guard let p = pricing else { return 0 }
        return p.chat + p.falZImageTurbo + p.falNanoBanana2 + p.falFlux2Pro
    }

    /// image upload + nano_ren_spica. Bandwidth charged on poster/video display.
    var videoCost: Int64 {
        guard let p = pricing else { return 0 }
        return p.image + p.nanoRenSpica
    }

    // MARK: - Lyrics + line cursor

    /// User pastes lyrics from the scene player. Stub force-alignment: split on
    /// newlines, assign equal 6s windows. Server-side WhisperX alignment is the
    /// real path — this client stub exists so the UX can land without it.
    func pasteLyrics(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let rawLines = trimmed
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let lines = rawLines.enumerated().map { idx, text in
            FemiSongLine(
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

    /// On first lyric paste, walk through existing untagged images and assign
    /// them line indices in order. After this every image in `images` has a
    /// `lineIndex` (modulo the line count if more images than lines).
    private func backfillLineIndices() {
        guard let audiolines, !audiolines.isEmpty else { return }
        var nextLine = 0
        for i in images.indices where images[i].lineIndex == nil {
            images[i].lineIndex = audiolines[nextLine % audiolines.count].index
            nextLine += 1
        }
    }

    /// Cursor through the song: returns up to `count` line indices that
    /// currently have no images. Wraps around when all lines are covered.
    func nextUnfilledLines(count: Int) -> [Int] {
        guard let audiolines, !audiolines.isEmpty else { return [] }
        let used = Set(images.compactMap { $0.lineIndex })
        var result: [Int] = []
        for line in audiolines where !used.contains(line.index) {
            result.append(line.index)
            if result.count >= count { return result }
        }
        // All lines filled at least once — fall through, wrapping by index.
        var i = 0
        while result.count < count {
            result.append(audiolines[i % audiolines.count].index)
            i += 1
        }
        return result
    }

    /// Stamp a fresh line index on each image in a freshly-returned batch.
    /// Pre-lyrics this is a no-op — images stay untagged until backfill.
    func tagBatch(_ batch: [FemiGeneratedImage]) -> [FemiGeneratedImage] {
        guard audiolines != nil else { return batch }
        let lineIndices = nextUnfilledLines(count: batch.count)
        return batch.enumerated().map { (offset, image) in
            var tagged = image
            if offset < lineIndices.count {
                tagged.lineIndex = lineIndices[offset]
            }
            return tagged
        }
    }

    /// Power-user override (context menu on a section header): generate 3
    /// images all tagged with the given line index. Pending cells appear in
    /// the section immediately, real images replace them when generation
    /// completes. Bypasses the cursor — user is directly addressing a moment.
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
            FemiPendingGeneration(id: UUID(), lineIndex: lineIndex)
        }
        let pendingIds = pendings.map(\.id)

        withAnimation(.spring(duration: 0.3)) {
            pendingGenerations.append(contentsOf: pendings)
        }

        Task { [weak self] in
            guard let self else { return }
            var pendingQueue = pendingIds
            do {
                let enriched = try await self.service.chatPrompt(seedText)
                for await img in self.service.generateImageBatch(prompt: enriched) {
                    var tagged = img
                    tagged.lineIndex = lineIndex
                    await MainActor.run {
                        guard !pendingQueue.isEmpty else { return }
                        let pid = pendingQueue.removeFirst()
                        withAnimation(.spring(duration: 0.35)) {
                            self.pendingGenerations.removeAll { $0.id == pid }
                            self.images.append(tagged)
                        }
                    }
                    persistImageToICloud(tagged)
                }
                await MainActor.run {
                    for pid in pendingQueue {
                        if let i = self.pendingGenerations.firstIndex(where: { $0.id == pid }) {
                            self.pendingGenerations[i].state = .failed
                        }
                    }
                }
                await self.refreshCredit()
            } catch {
                await MainActor.run {
                    for pid in pendingQueue {
                        if let i = self.pendingGenerations.firstIndex(where: { $0.id == pid }) {
                            self.pendingGenerations[i].state = .failed
                        }
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
        loadProjectGenerationsFromDisk()
        async let balance = try? service.currentBalance()
        async let pricing = try? service.currentPricing()
        async let projects = try? service.allProjects()
        if let balance = await balance {
            self.credit = Credit(credits: balance)
        }
        self.pricing = await pricing
        let loaded = await projects ?? []
        // Don't overwrite the UI-demo dummy seed when bootstrap returns empty.
        if !loaded.isEmpty { self.allProjects = loaded }
        // First-run gateway is handled in RootView (SongView appears
        // instantly there). By the time ContentView mounts, the user has
        // already picked a song — `project` will be set via
        // `handleSongPicked` if `loaded` is empty server-side. For returning
        // users, take the most recent project from the server.
        if !loaded.isEmpty {
            self.project = loaded.first
        }
    }

    /// Restore prior generations from the local project folder.
    func loadProjectGenerationsFromDisk() {
        let existing = Set(images.map(\.file))
        for url in ProjectService.getAllGenerations() {
            let filename = url.lastPathComponent
            guard !existing.contains(filename) else { continue }
            guard Self.isGridImageFile(filename) else { continue }
            images.append(FemiGeneratedImage(
                id: UUID(),
                file: filename,
                prompt: "",
                source: .unknown
            ))
        }
        syncImageLikesFromDisk()
    }

    /// Mirror on-disk `xmp:Rating` into `likeStore` (new UUIDs each launch).
    private func syncImageLikesFromDisk() {
        for image in images where ProjectService.getLike(image.file) {
            likeStore.setLiked(image.id, true)
        }
    }

    private static func isGridImageFile(_ filename: String) -> Bool {
        switch URL(fileURLWithPath: filename).pathExtension.lowercased() {
        case "png", "jpg", "jpeg", "webp", "gif", "heic", "heif": return true
        default: return false
        }
    }

    // MARK: - Project switcher

    func openProjects() { presentingProjects = true }

    /// Tapped a project in the projects sheet. Resets in-memory state and
    /// switches the active project. Server-side re-fetch of historical
    /// generations is a future task — switching to an old project starts
    /// with an empty grid the user keeps adding to.
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

    /// Tapped "+" in the projects sheet. Dismiss the sheet first so we don't
    /// stack sheets, then present SongView.
    func openNewSong() {
        presentingProjects = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.presentingNewSong = true
        }
    }

    /// SongView completed. The upload + project upsert happened inside
    /// SongView itself — refetch projects and select the most recent.
    func handleSongPicked() {
        presentingNewSong = false
        Task { [weak self] in
            guard let self else { return }
            let loaded = (try? await self.service.allProjects()) ?? []
            await MainActor.run {
                withAnimation(.spring(duration: 0.4)) {
                    self.allProjects = loaded
                    if let newest = loaded.first {
                        self.project = newest
                    }
                    self.images = []
                    self.videos = []
                    self.pendingImages = []
                    self.pendingVideos = []
                    self.pendingGenerations = []
                    self.lyrics = nil
                    self.audiolines = nil
                    self.selectedImageIds = []
                    self.isSelectingForVideo = false
                    self.phase = .onboarding
                }
            }
        }
    }

    // Onboarding — kinetic is a single beat; advancing means we're done.
    func finishOnboarding() { phase = .grid }

    // Start (first generation). Terms screen upstream owns cost disclosure;
    // we fire generation directly.

    func tapStart() {
        // Fade the onboarding WAV out as the user transitions away from the
        // onboarding/Ready beat. Idempotent if it's already stopped.
        onboardingAudio.fadeOut(duration: 0.6)
        Task { await performInitialGeneration() }
    }

    private func performInitialGeneration() async {
        guard gateOnCredit(cost: generationCost, retry: { [weak self] in
            Task { await self?.performInitialGeneration() }
        }) else { return }

        // Land on the grid immediately with three shimmer cells — same pattern
        // as derive / fill-line / upload. No separate full-screen wait.
        let pendings = (0..<3).map { _ in
            FemiPendingGeneration(id: UUID(), lineIndex: nil)
        }
        let pendingIds = pendings.map(\.id)
        withAnimation(.spring(duration: 0.4)) {
            pendingGenerations.append(contentsOf: pendings)
            phase = .grid
        }

        // If the menu entry point requested an LLM-derived prompt, resolve
        // it now — the shimmer is already on screen, so the on-device LLM
        // latency is hidden by the loaders.
        if needsLLMPrompt {
            needsLLMPrompt = false
            pendingInitialPrompt = await initialStartPrompt()
        }

        let seed = pendingInitialPrompt
            ?? project?.summary
            ?? project?.audioLines.first?.line
            ?? "A vibrant music video opening scene"
        pendingInitialPrompt = nil

        // Pre-allocate line indices so streamed images land in the right
        // sections without needing the whole batch up-front.
        var lineIter = (audiolines != nil ? nextUnfilledLines(count: 3) : []).makeIterator()
        var pendingQueue = pendingIds
        var isFirst = true
        do {
            let enriched = try await service.chatPrompt(seed)
            for await img in service.generateImageBatch(prompt: enriched) {
                var tagged = img
                tagged.lineIndex = lineIter.next()
                let pid = pendingQueue.removeFirst()
                withAnimation(.spring(duration: 0.45)) {
                    pendingGenerations.removeAll { $0.id == pid }
                    images.append(tagged)
                }
                if isFirst {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    isFirst = false
                }
                persistImageToICloud(tagged)
            }
            for pid in pendingQueue {
                if let i = pendingGenerations.firstIndex(where: { $0.id == pid }) {
                    pendingGenerations[i].state = .failed
                }
            }
            await refreshCredit()
        } catch {
            for pid in pendingQueue {
                if let i = pendingGenerations.firstIndex(where: { $0.id == pid }) {
                    pendingGenerations[i].state = .failed
                }
            }
            errorMessage = error.localizedDescription
        }
    }

    // Derive

    func openDerive(_ image: FemiGeneratedImage) { phase = .derive(image: image) }

    /// Set by `tapInitialFromMenu()` (or seeded externally). Consumed inside
    /// `performInitialGeneration` so the first batch uses the user's words
    /// instead of a fallback seed.
    var pendingInitialPrompt: String?

    /// Set by `tapInitialFromMenu()`. Causes `performInitialGeneration` to
    /// run the on-device Apple Intelligence prompt AFTER the shimmer cells
    /// land, so the user sees the loaders instantly instead of waiting on
    /// the LLM call.
    var needsLLMPrompt = false

    /// Entry point from the toolbar Generate menu item. Drops the shimmer
    /// cells immediately; the LLM-derived prompt resolves inside the async
    /// generation flow rather than blocking the tap.
    func tapInitialFromMenu() {
        pendingInitialPrompt = nil
        needsLLMPrompt = true
        tapStart()
    }

    func dismissFemiPendingGeneration(_ id: UUID) {
        withAnimation { pendingGenerations.removeAll { $0.id == id } }
    }

    /// Upsert a three-model batch from a GenerateNew route action, then poll
    /// each server `request_id` and swap shimmers for images as they land.
    func runGenerateAction(_ action: GenerateAction) async {
        let pendings = (0..<3).map { _ in
            FemiPendingGeneration(id: UUID(), lineIndex: nil)
        }
        withAnimation(.spring(duration: 0.35)) {
            pendingGenerations.append(contentsOf: pendings)
        }

        let prompt: String
        do {
            switch action {
            case .deriveImage(let text, let filename):
                let prior = ProjectService.getPrompt(filename) ?? ""
                prompt = try await DerivePrompt.enrich(prior: prior, tweak: text)
            }
        } catch {
            for p in pendings {
                if let i = pendingGenerations.firstIndex(where: { $0.id == p.id }) {
                    pendingGenerations[i].state = .failed
                }
            }
            errorMessage = error.localizedDescription
            return
        }

        let requestIds = await service.startImageBatch(prompt: prompt)
        if requestIds.isEmpty {
            for p in pendings {
                if let i = pendingGenerations.firstIndex(where: { $0.id == p.id }) {
                    pendingGenerations[i].state = .failed
                }
            }
            return
        }

        // Trim surplus shimmers when fewer than three models accepted.
        if requestIds.count < pendings.count {
            for p in pendings.suffix(pendings.count - requestIds.count) {
                pendingGenerations.removeAll { $0.id == p.id }
            }
        }

        await pollRequestIds(requestIds, pendings: Array(pendings.prefix(requestIds.count)))
    }

    private func pollRequestIds(
        _ requestIds: [String],
        pendings: [FemiPendingGeneration]
    ) async {
        let pairs = Array(zip(pendings, requestIds))

        await withTaskGroup(of: (UUID, Result<API, Error>).self) { group in
            for (pending, requestId) in pairs {
                let shimmerId = pending.id
                group.addTask {
                    do {
                        let row = try await self.service.pollGenerate(requestId: requestId)
                        return (shimmerId, .success(row))
                    } catch {
                        return (shimmerId, .failure(error))
                    }
                }
            }
            for await (shimmerId, result) in group {
                switch result {
                case .success(let row):
                    let img = FemiGeneratedImage(
                        id: row.id,
                        file: row.file,
                        prompt: row.prompt,
                        source: FemiGenerateAPI.source(for: row.model)
                    )
                    withAnimation(.spring(duration: 0.4)) {
                        pendingGenerations.removeAll { $0.id == shimmerId }
                        if !images.contains(where: { $0.file == img.file }) {
                            images.append(img)
                        }
                    }
                    persistImageToICloud(img)
                case .failure:
                    if let i = pendingGenerations.firstIndex(where: { $0.id == shimmerId }) {
                        pendingGenerations[i].state = .failed
                    }
                }
            }
        }
    }

    // Like

    func toggleLikeImage(_ image: FemiGeneratedImage) {
        likeStore.toggle(image.id)
        ProjectService.like(image.file, likeStore.isLiked(image.id))
        if likeStore.isLiked(image.id), tutorialMoment == .likeAnImage {
            tutorialMoment = .selectLikedForVideo
        }
    }

    func toggleLikeVideo(_ video: FemiGeneratedVideo) {
        likeStore.toggle(video.id)
        if likeStore.isLiked(video.id), tutorialMoment == .likeYourVideo {
            phase = .complete
            tutorialMoment = .none
        }
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
        // Only liked images are selectable. Cap at 3.
        guard likeStore.isLiked(id) else { return }
        if let i = selectedImageIds.firstIndex(of: id) {
            selectedImageIds.remove(at: i)
        } else if selectedImageIds.count < 3 {
            selectedImageIds.append(id)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    /// Fire-and-forget. Adds a FemiPendingVideo immediately, kicks off the long generation
    /// in a background Task, mutates `videos` when it completes. The grid stays
    /// interactive the entire time — user can derive, like, browse, even queue more
    /// videos while the first is cooking.
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

        // Exit select mode immediately. No phase change — stay on grid.
        isSelectingForVideo = false
        selectedImageIds = []

        let pending = FemiPendingVideo(
            id: UUID(),
            sourceImageIds: ids,
            posterFile: primary.file
        )
        withAnimation(.spring(duration: 0.3)) {
            pendingVideos.append(pending)
        }

        let projectAudio = project.audio
        let prompt = primary.prompt
        // Snapshot the line range for the primary image (if any) so the Task
        // doesn't have to re-read main-actor state.
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
                // Trim the audio to the line's range when we have one. Audio
                // conditioning still drives motion — we're just making sure
                // the conditioning is on the right moment of the song.
                let audioFile: String
                if let r = lineRange {
                    do {
                        audioFile = try await self.service.trimAndUploadAudioClip(
                            sourceAudioFile: projectAudio,
                            startMs: r.start,
                            durationMs: r.duration
                        )
                    } catch {
                        // Fall back to the full project audio — generation
                        // succeeds with a less precise audio range.
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
                // Swap pending → real video.
                withAnimation(.spring(duration: 0.4)) {
                    self.pendingVideos.removeAll { $0.id == pending.id }
                    self.videos.append(FemiGeneratedVideo(
                        id: UUID(),
                        file: videoFile,
                        posterFile: primary.file,
                        sourceImageIds: ids
                    ))
                }
                await self.refreshCredit()
                if self.tutorialMoment == .selectLikedForVideo {
                    self.tutorialMoment = .likeYourVideo
                }
            } catch {
                // Mark the pending entry as failed so the cell shows a retry/error state.
                if let idx = self.pendingVideos.firstIndex(where: { $0.id == pending.id }) {
                    self.pendingVideos[idx].state = .failed
                }
                self.errorMessage = error.localizedDescription
            }
        }
    }

    /// Discard a failed pending video.
    func dismissFemiPendingVideo(_ id: UUID) {
        withAnimation { pendingVideos.removeAll { $0.id == id } }
    }

    // MARK: - Upload your own image

    /// Fire-and-forget upload. User-supplied bytes go to /image, server returns a
    /// filename, we add it to the grid as a normal FemiGeneratedImage (source: .upload).
    /// Same async pattern as video gen — grid stays interactive while upload runs.
    func handlePhotoPick(_ data: Data) {
        let pending = FemiPendingImage(id: UUID())
        withAnimation(.spring(duration: 0.3)) {
            pendingImages.append(pending)
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                let file = try await self.service.upload(
                    data: data,
                    suggestedName: "upload-\(UUID().uuidString).jpg"
                )
                let newImage = FemiGeneratedImage(
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

    func dismissFemiPendingImage(_ id: UUID) {
        withAnimation { pendingImages.removeAll { $0.id == id } }
    }

    // Credit / topup gate

    /// Minimum wallet balance required before generate/video; at or below → topup.
    private let minimumBalanceForGeneration: Int64 = 50

    private func gateOnCredit(cost: Int64, retry: @escaping () -> Void) -> Bool {
        guard pricing != nil else {
            Task { await refreshPricing() }
            return false
        }
        guard let c = credit else {
            Task { await refreshCredit() }
            return false
        }
        if c.credits <= minimumBalanceForGeneration || c.credits < cost {
            // Parent app owns the topup UX. Fire its closure; on success,
            // refresh balance and re-fire the original action.
            Task { [weak self] in
                guard let self else { return }
                guard let handler = self.onTopupNeeded, await handler() else { return }
                await self.refreshCredit()
                await MainActor.run { retry() }
            }
            return false
        }
        return true
    }

    func refreshCredit() async {
        if let balance = try? await service.currentBalance() {
            credit = Credit(credits: balance)
        }
    }

    func refreshPricing() async {
        pricing = try? await service.currentPricing()
    }

    /// Fetch generated image bytes and persist them to the local project folder.
    fileprivate func persistImageToICloud(_ img: FemiGeneratedImage) {
        Task {
            let data = try! await MediaApi.fetch(img.file, idToken: AppAuth.bearer)
            let model = Self.aiSystemName(for: img.source)
            ProjectService.saveFile(
                data,
                named: img.file,
                prompt: img.prompt.isEmpty ? nil : img.prompt,
                model: model.isEmpty ? nil : model
            )
        }
    }

    private static func aiSystemName(for source: FemiGeneratedImage.Source) -> String {
        switch source {
        case .zimage: return ApiAiModel.zimageturbo.rawValue
        case .nanoBanana: return ApiAiModel.nanoBanana2.rawValue
        case .flux2: return ApiAiModel.flux2Pro.rawValue
        case .upload, .unknown: return ""
        }
    }

}

// MARK: - Authorized image (femi.market, header-injected)

struct FemiAuthorizedImage: View {
    let filename: String
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?
    @State private var failed = false

    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    var body: some View {
        ZStack {
            if isPreview {
                // Deterministic colorful placeholder so Xcode previews look like
                // real content without hitting the network.
                previewSurface
            } else if let image {
                Image(uiImage: image).resizable().aspectRatio(contentMode: contentMode)
            } else if failed {
                Color.black.opacity(0.4).overlay(
                    Image(systemName: "photo").foregroundStyle(FemiTheme.muted)
                )
            } else {
                Shimmer()
            }
        }
        .task(id: filename) {
            guard !isPreview else { return }
            await load()
        }
    }

    @ViewBuilder
    private var previewSurface: some View {
        if let img = bundledPreviewImage {
            Image(uiImage: img).resizable().aspectRatio(contentMode: contentMode)
        } else {
            let hue = Double(abs(filename.hashValue % 360)) / 360.0
            LinearGradient(
                colors: [
                    Color(hue: hue, saturation: 0.7, brightness: 0.6),
                    Color(hue: hue + 0.1, saturation: 0.9, brightness: 0.4)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    private var bundledPreviewImage: UIImage? {
        let ns = filename as NSString
        let name = ns.deletingPathExtension
        let ext = ns.pathExtension.isEmpty ? "png" : ns.pathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return UIImage(data: data)
    }

    private func load() async {
        // Dev seed bundle short-circuit: when `devSeedEnabled` is true and
        // the filename has no path component (e.g. "90.png"), check the app
        // bundle first. Avoids a network round-trip for stand-in images and
        // is gated on the flag so production behavior is unaffected.
        if devSeedEnabled, !filename.contains("/"),
           let bundled = bundledPreviewImage {
            await MainActor.run { self.image = bundled }
            return
        }
        if let current = ProjectService.current {
            let localURL = ProjectService.documents
                .appendingPathComponent(current)
                .appendingPathComponent((filename as NSString).lastPathComponent)
            if let data = try? Data(contentsOf: localURL),
               let img = UIImage(data: data) {
                await MainActor.run { self.image = img }
                return
            }
        }
        do {
            // MediaApi.session caps to 6 concurrent + caches, so a sea of cells
            // doesn't blast the server (C9) and re-displays are instant.
            let data = try await MediaApi.fetch(filename, idToken: AppAuth.bearer)
            if let img = UIImage(data: data) {
                await MainActor.run { self.image = img }
            } else {
                await MainActor.run { self.failed = true }
            }
        } catch {
            await MainActor.run { self.failed = true }
        }
    }
}

// MARK: - Shimmer placeholder

private struct Shimmer: View {
    @State private var phase: CGFloat = -1
    var body: some View {
        GeometryReader { geo in
            ZStack {
                FemiTheme.surface
                LinearGradient(
                    colors: [.clear, FemiTheme.accentMagenta.opacity(0.35),
                             FemiTheme.accentBlue.opacity(0.35), .clear],
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
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": ["Authorization": "Bearer \(AppAuth.bearer)"]
        ])
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

/// Tap a video cell → this opens full-screen with native controls and audio.
/// Switches AVAudioSession to .playback so the user's silent switch doesn't mute
/// the video (intentional: they tapped to watch, that's consent). Reverts to
/// .ambient on dismiss so the rest of the app stays polite.
private struct VideoDetailView: View {
    let video: FemiGeneratedVideo
    @Bindable var viewModel: FemiGenerateViewModel
    let onDismiss: () -> Void
    @State private var player: AVPlayer?
    @State private var presentingLyricPaste = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                FemiAuthorizedImage(filename: video.posterFile)
                    .ignoresSafeArea()
                ProgressView().controlSize(.large).tint(.white)
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
                lyricsAffordance
            }
        }
        .task { setupPlayback() }
        .onDisappear { teardownPlayback() }
        .sheet(isPresented: $presentingLyricPaste) {
            LyricPasteSheet(
                save: { text in viewModel.pasteLyrics(text) },
                onClose: { presentingLyricPaste = false }
            )
            .presentationDetents([.large])
            .presentationBackground(.regularMaterial)
        }
    }

    /// Revelation moment: subtle affordance offering lyric overlay + perfect
    /// timing. Hidden once the user has pasted lyrics — at that point the
    /// machinery is in place and the overlay would be the next premium ask.
    @ViewBuilder
    private var lyricsAffordance: some View {
        if viewModel.audiolines == nil {
            Button {
                presentingLyricPaste = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "text.justify.left")
                        .font(.subheadline.weight(.semibold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add your lyrics")
                            .font(.subheadline.weight(.semibold))
                        Text("Make every moment sync to your words.")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(FemiTheme.accentMagenta.opacity(0.45), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .buttonStyle(.plain)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private func setupPlayback() {
        let path = video.file.hasPrefix("/") ? String(video.file.dropFirst()) : video.file
        guard !path.isEmpty, let url = URL(string: "https://femi.market/\(path)") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": ["Authorization": "Bearer \(AppAuth.bearer)"]
        ])
        let item = AVPlayerItem(asset: asset)
        let p = AVPlayer(playerItem: item)
        p.isMuted = false
        self.player = p
        p.play()
    }

    private func teardownPlayback() {
        player?.pause()
        player = nil
        // Restore ambient session so onboarding WAV behaves politely on next launch.
        try? AVAudioSession.sharedInstance().setCategory(
            .ambient, mode: .default, options: [.mixWithOthers]
        )
    }
}

// MARK: - Projects sheet (switch song / new song)

/// Opens from the principal toolbar switcher. Lists the user's projects;
/// tap a row to switch, "+" presents Song.swift to create a new project.
private struct ProjectsSheet: View {
    @Bindable var viewModel: FemiGenerateViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FemiTheme.background.ignoresSafeArea()
                cardPager
            }
            .navigationTitle("Your songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(FemiTheme.muted)
                }
            }
            .toolbarBackground(FemiTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    /// Vertical paged card stack. Each project is its own full-bleed card;
    /// the final card is "New song" — same gesture, same surface, no separate
    /// + button. Swipe up/down to switch between cards.
    @ViewBuilder
    private var cardPager: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.allProjects, id: \.id) { project in
                        projectCard(project, size: geo.size)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                    newSongCard(size: geo.size)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
        }
    }

    @ViewBuilder
    private func projectCard(_ project: Project, size: CGSize) -> some View {
        let isCurrent = project.id == viewModel.project?.id
        let h = abs(project.id.hashValue)
        let cardWidth = size.width - 48
        let cardHeight = size.height - 80

        Button {
            viewModel.switchToProject(project)
        } label: {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [
                            Color(hue: Double(h % 360) / 360, saturation: 0.75, brightness: 0.6),
                            Color(hue: Double((h / 360) % 360) / 360, saturation: 0.85, brightness: 0.35),
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.55)],
                        startPoint: .center, endPoint: .bottom
                    )
                    VStack(alignment: .leading, spacing: 6) {
                        if isCurrent {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Now")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(FemiTheme.accentMagenta)
                        }
                        Text(project.summary.isEmpty
                             ? (project.audio as NSString).deletingPathExtension
                             : project.summary)
                            .font(.system(size: 40, weight: .heavy))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                        Text((project.audio as NSString).lastPathComponent)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(1)
                    }
                    .padding(24)
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipShape(.rect(cornerRadius: 28))
                .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func newSongCard(size: CGSize) -> some View {
        let cardWidth = size.width - 48
        let cardHeight = size.height - 80

        Button(action: viewModel.openNewSong) {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(FemiTheme.accent)
                        .frame(width: 96, height: 96)
                        .shadow(color: FemiTheme.accentMagenta.opacity(0.5),
                                radius: 24, y: 8)
                    Image(systemName: "plus")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("New song")
                    .font(.title.bold())
                    .foregroundStyle(FemiTheme.onSurface)
                Text("Start a fresh production.")
                    .font(.subheadline)
                    .foregroundStyle(FemiTheme.muted)
            }
            .frame(width: cardWidth, height: cardHeight)
            .background(FemiTheme.surface, in: .rect(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(FemiTheme.accentMagenta.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
            )
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lyric paste sheet

/// Surfaces on first scene playback (`audiolines == nil`). User pastes their
/// own lyrics; on Save the sheet dismisses immediately. Per HIG: ideally
/// content displays instantly, success doesn't need a confirmation banner,
/// and only failures warrant an alert. Failures (when the real server call
/// lands) will surface via `viewModel.errorMessage` → `.alert`, not in here.
///
/// Layout follows Apple's compose-sheet pattern (Mail, Reminders, Calendar):
/// `NavigationStack` + toolbar buttons + a TextEditor that fills the body.
/// SwiftUI's built-in keyboard avoidance plays nicely with this structure
/// because it's the layout Apple designed for — no manual keyboard observer,
/// no decorative chrome that crops when the keyboard rises. Brand is layered
/// on top via the principal title, the gradient Save button, and a dark
/// `FemiTheme.background` instead of the default sheet material.
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
                FemiTheme.background.ignoresSafeArea()

                TextEditor(text: $text)
                    .focused($focused)
                    .font(.body)
                    .foregroundStyle(FemiTheme.onSurface)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .tint(FemiTheme.accentMagenta)

                if text.isEmpty {
                    Text("Drop your lyrics here. One line at a time — the way your song breathes.")
                        .font(.body.italic())
                        .foregroundStyle(FemiTheme.muted)
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
                            .foregroundStyle(FemiTheme.accent)
                        Text("Your lyrics")
                            .font(.headline)
                            .foregroundStyle(FemiTheme.onSurface)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        focused = false
                        onClose()
                    }
                    .foregroundStyle(FemiTheme.muted)
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
                                    : AnyShapeStyle(FemiTheme.accent)
                            )
                            .clipShape(.capsule)
                    }
                    .disabled(trimmed.isEmpty)
                }
            }
            .toolbarBackground(FemiTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear { focused = true }
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
                        Image(systemName: "sparkles").foregroundStyle(FemiTheme.accent)
                        Text(title).font(.headline).foregroundStyle(FemiTheme.onSurface)
                    }
                    Text(message).font(.subheadline).foregroundStyle(FemiTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Spacer()
                        Button("Got it", action: onDismiss).buttonStyle(.glassProminent)
                    }
                }
                .padding(20)
                .background(.regularMaterial, in: .rect(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24)
                    .stroke(FemiTheme.accentMagenta.opacity(0.4), lineWidth: 1))
                .padding(.horizontal, 20).padding(.bottom, 32)
                .shadow(color: .black.opacity(0.4), radius: 30, y: 10)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Credit chip

private struct CreditChip: View {
    let credits: Int64
    let isLoading: Bool
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill").font(.caption.weight(.bold))
                .foregroundStyle(FemiTheme.accent)
            if isLoading {
                ProgressView().scaleEffect(0.6).frame(width: 12, height: 12)
            } else {
                Text("\(credits)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FemiTheme.onSurface)
                    .contentTransition(.numericText(value: Double(credits)))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .glassEffect(.regular, in: .capsule)
    }
}

// MARK: - GenerateNew (derive prompt input)

/// Destination pushed for `.derive(filename)` route. User types a natural
/// language change; submit forwards to `.generate(.deriveImage(...))` so
/// the Generate destination runs the upsert + poll.
struct GenerateNew: View {
    let filename: String
    @Binding var path: [AppRoute]
    @State private var tweak: String = ""
    @FocusState private var focused: Bool

    private var trimmed: String {
        tweak.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                FemiAuthorizedImage(filename: filename)
                    .frame(width: 64, height: 64)
                    .clipShape(.rect(cornerRadius: 12))
                    .accessibilityLabel("Picture you tapped")
                VStack(alignment: .leading, spacing: 2) {
                    Text("From this one")
                        .font(.footnote)
                        .foregroundStyle(FemiTheme.muted)
                    Text("Tell me what to change")
                        .font(.title3.bold())
                        .foregroundStyle(FemiTheme.onSurface)
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
            .foregroundStyle(FemiTheme.onSurface)
            .padding(16)
            .background(FemiTheme.surface, in: .rect(cornerRadius: 16))
            .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(FemiTheme.background.ignoresSafeArea())
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
                path = [.generate(.deriveImage(text: trimmed, filename: filename))]
            } label: {
                Text(trimmed.isEmpty ? "Type to make new ones" : "Make new ones")
                    .animation(.easeInOut(duration: 0.15), value: trimmed.isEmpty)
            }
            .buttonStyle(FemiAccentButtonStyle())
            .disabled(trimmed.isEmpty)
            .padding(16)
            .background(.regularMaterial)
        }
    }
}

// MARK: - UploadSong placeholder (audio import sheet)

struct UploadSong: View {
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                FemiTheme.background.ignoresSafeArea()
                VStack(spacing: 14) {
                    Image(systemName: "music.note")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(FemiTheme.accent)
                    Text("Upload song")
                        .font(.title2.bold())
                        .foregroundStyle(FemiTheme.onSurface)
                    Text("Audio import lives here.")
                        .font(.footnote)
                        .foregroundStyle(FemiTheme.muted)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onComplete)
                        .foregroundStyle(FemiTheme.muted)
                }
            }
            .toolbarBackground(FemiTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - ContentView

struct Generate: View {
    @Binding var appPath: [AppRoute]
    /// Generation intent from GenerateNew via `.generate(GenerateAction)`.
    /// Nil on the tab-root Generate; set on the pushed destination.
    let action: GenerateAction?
    /// Parent app's topup handler — installed on the view model on appear so
    /// `gateOnCredit` can await it when credits run dry.
    let onTopupNeeded: () async -> Bool
    @State private var viewModel = FemiGenerateViewModel()
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false
    @State private var presentingSongPickerDummy = false
    @State private var presentingProjectPickerDummy = false

    var body: some View {
        ZStack {
            FemiTheme.background.ignoresSafeArea()
            content
        }
        .toolbar { toolbar }
        .fullScreenCover(item: $viewModel.viewingVideo) { video in
            VideoDetailView(video: video, viewModel: viewModel) {
                viewModel.viewingVideo = nil
            }
        }
        .sheet(isPresented: $presentingSongPickerDummy) {
            UploadSong(onComplete: { presentingSongPickerDummy = false })
        }
        .sheet(isPresented: $presentingProjectPickerDummy) {
            ProjectPickerDummy()
        }
        .environment(viewModel)
        // Sync viewModel.phase → Router's appPath. Route payload is the
        // filename String — Router never sees feature model types.
        .onChange(of: viewModel.phase) { _, newPhase in
            if case .derive(let image) = newPhase {
                if !appPath.contains(where: { if case .derive = $0 { return true } else { return false } }) {
                    appPath.append(.derive(image.file))
                }
            } else if let idx = appPath.lastIndex(where: { if case .derive = $0 { return true } else { return false } }) {
                appPath.remove(at: idx)
            }
        }
        // Reverse sync: when the user swipes back from FemiDeriveView, appPath
        // drops the .derive entry; bring the viewModel back to .grid.
        .onChange(of: appPath) { _, _ in
            if case .derive = viewModel.phase,
               !appPath.contains(where: { if case .derive = $0 { return true } else { return false } }) {
                viewModel.phase = .grid
            }
        }
        .preferredColorScheme(.dark)
        .task {
            viewModel.onTopupNeeded = onTopupNeeded
            await viewModel.bootstrap()
        }
        .task(id: action) {
            guard let action else { return }
            await viewModel.runGenerateAction(action)
        }
        .photosPicker(isPresented: $showingPhotoPicker,
                      selection: $photoPickerItem,
                      matching: .images)
        // Photo picker bridge: user picks → load Data → hand off to view model.
        .onChange(of: photoPickerItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    viewModel.handlePhotoPick(data)
                }
                photoPickerItem = nil
            }
        }
        .toolbar(viewModel.isSelectingForVideo ? .hidden : .visible, for: .tabBar)
        .animation(.spring(duration: 0.3), value: viewModel.isSelectingForVideo)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if viewModel.isSelectingForVideo {
                FemiMakeVideoShelf(viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .onboarding:
            KineticOnboardingView(onComplete: viewModel.finishOnboarding)
                .task { viewModel.onboardingAudio.start(resource: "generate_onboarding", ext: "wav") }
        case .generating(let kind):
            GeneratingOverlay(kind: kind)
        case .grid, .derive:
            gridLayer
        case .complete:
            CompletionView(onDone: { viewModel.phase = .grid })
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
        case .likeYourVideo:
            CoachMark(
                title: "Tap ♡ to save your video",
                message: "That's it. You're done.",
                onDismiss: { withAnimation { viewModel.tutorialMoment = .none } }
            )
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if viewModel.isSelectingForVideo {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel", action: viewModel.cancelMakeVideo)
                    .foregroundStyle(FemiTheme.onSurface)
            }
            ToolbarItem(placement: .principal) {
                Text("\(viewModel.selectedImageIds.count) of 3 picked")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FemiTheme.muted)
                    .contentTransition(.numericText(value: Double(viewModel.selectedImageIds.count)))
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                if shouldShowUploadButton {
                    Menu {
                        Button {
                            viewModel.tapInitialFromMenu()
                        } label: {
                            Label("Generate", systemImage: "sparkles")
                        }
                        Button {
                            showingPhotoPicker = true
                        } label: {
                            Label("Upload from Photos", systemImage: "photo")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(FemiTheme.onSurface)
                    }
                }
            }
            // Title triggers two dummy pickers via gesture:
            //   - tap        → song picker (common action, discoverable)
            //   - long-press → project picker (rare action, hidden moat)
            ToolbarItem(placement: .principal) {
                Button {
                    presentingSongPickerDummy = true
                } label: {
                    HStack(spacing: 6) {
                        if let song = FemiLocalStore.uploadSong {
                            Text(song)
                                .font(.headline)
                                .foregroundStyle(FemiTheme.onSurface)
                                .lineLimit(1)
                        } else {
                            Text("No song")
                                .font(.headline)
                                .foregroundStyle(FemiTheme.muted)
                        }
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(FemiTheme.muted)
                    }
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                        presentingProjectPickerDummy = true
                    }
                )
            }
            ToolbarItem(placement: .topBarTrailing) {
                if shouldShowMakeVideoButton {
                    Button(action: viewModel.enterMakeVideo) {
                        HStack(spacing: 4) {
                            Image(systemName: "film.fill")
                            Text("Make Video")
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(viewModel.canMakeVideo ? FemiTheme.onSurface : FemiTheme.muted)
                    .disabled(!viewModel.canMakeVideo)
                    .accessibilityLabel("Make video")
                    .accessibilityHint(viewModel.canMakeVideo
                        ? "Pick up to three of your saved pictures"
                        : "Save at least one picture first")
                }
            }
        }
    }

    /// Show the + (upload) button only when the user is on the grid.
    private var shouldShowUploadButton: Bool {
        if case .grid = viewModel.phase { return true }
        return false
    }

    /// Toolbar chrome (switcher, credit chip, Make Video) only appears on
    /// the grid. Splash / startCta / generating overlay / completion stay
    /// chrome-free.
    private var shouldShowGridChrome: Bool {
        if case .grid = viewModel.phase { return true }
        return false
    }

    private func projectTitle(_ p: Project) -> String {
        let s = p.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.isEmpty { return s }
        let audioBase = (p.audio as NSString).lastPathComponent
        let stripped = (audioBase as NSString).deletingPathExtension
        return stripped.isEmpty ? "Untitled song" : stripped
    }

    /// Only show Make Video in the toolbar when the user is on the grid (not derive, etc.).
    private var shouldShowMakeVideoButton: Bool {
        if case .grid = viewModel.phase { return true }
        return false
    }

    private var deriveBinding: Binding<Bool> {
        Binding(
            get: { if case .derive = viewModel.phase { true } else { false } },
            set: { v in if !v, case .derive = viewModel.phase { viewModel.phase = .grid } }
        )
    }

}


// MARK: - Dummy pickers (stand-ins for Team 1 / Team 2 surfaces)


/// Stand-in for Team 1's project picker. Undefined for now per spec.
/// First-launch flow auto-creates Project=1 so this screen isn't required
/// to start using Generate.
private struct ProjectPickerDummy: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FemiTheme.background.ignoresSafeArea()
                VStack(spacing: 18) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(FemiTheme.accent)
                    Text("Project picker")
                        .font(.title2.bold())
                        .foregroundStyle(FemiTheme.onSurface)
                    Text("Dummy. Real screen owned by Team 1.\nUndefined for now.")
                        .font(.footnote)
                        .foregroundStyle(FemiTheme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    if let current = ProjectService.current {
                        Text("Current project: \(current)")
                            .font(.caption)
                            .foregroundStyle(FemiTheme.muted)
                            .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("Project picker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(FemiTheme.muted)
                }
            }
            .toolbarBackground(FemiTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Kinetic onboarding sandbox
//
// Spike of the proposed flagship onboarding. Two diagonal halves, each cutting
// to different images on opposite beats during a 1.5s burst, then settling into
// a held composition with the headline. A subtle "ghost" beat dims the image
// briefly before returning. Cuts run at 4 Hz (well under the 3 Hz photosensitive
// threshold). Reduce-Motion serves a still hero. Tap anywhere to skip.

private enum OnboardingSide { case left, right }

private struct DiagonalHalfShape: Shape {
    let side: OnboardingSide
    // Top edge intersect at 65% across, bottom at 35% — ~30° lean.
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
    // Asset-catalog names (no extension). Bundled with the binary.
    var images: [String] = ["generate_img1", "generate_img2", "generate_img3", "generate_img4"]
    /// Skip the kinetic burst and render the held composition directly.
    /// Used for previewing the "after settle" state.
    var forcedHeld: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start: Date = .init()
    @State private var showSkipHint = false

    private var renderStill: Bool { reduceMotion || forcedHeld }

    // Timing — burst long enough for 4 images to each appear twice per side.
    private let cutInterval: Double = 0.25     // 4 Hz
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
                    Text("tap to continue")
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
        // Right side cuts on an offset beat so the two halves are never in lock.
        let leftIdx = phase.isBursting ? (beat % images.count) : 0
        let rightIdx = phase.isBursting ? ((beat + 1) % images.count) : (images.count - 1)

        GeometryReader { geo in
            ZStack {
                halfImage(
                    file: images[leftIdx],
                    tint: FemiTheme.accentMagenta,
                    side: .left,
                    in: geo.size,
                    holding: !phase.isBursting
                )
                halfImage(
                    file: images[rightIdx],
                    tint: FemiTheme.accentBlue,
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
        // Asset-catalog images, shipped in the binary. Faster than FemiAuthorizedImage
        // (no network, no caching layer) and works offline / before auth is set.
        Image(file)
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
        let burstEnd  = burstDuration                       // 1.5
        let settleEnd = burstEnd + settleDuration           // 2.0
        let holdEnd   = settleEnd + holdDuration            // 3.0
        let ghostEnd  = holdEnd + ghostDuration             // 3.3
        let returnEnd = ghostEnd + returnDuration           // 3.8

        if t < burstEnd {
            return Phase(isBursting: true, masterAlpha: 1, headlineAlpha: 0)
        } else if t < settleEnd {
            let p = (t - burstEnd) / settleDuration
            return Phase(isBursting: false, masterAlpha: 1, headlineAlpha: p)
        } else if t < holdEnd {
            return Phase(isBursting: false, masterAlpha: 1, headlineAlpha: 1)
        } else if t < ghostEnd {
            // "Ghost": dim everything to 30% to suggest a held breath.
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
                halfImage(file: images[0], tint: FemiTheme.accentMagenta,
                          side: .left, in: geo.size, holding: true)
                halfImage(file: images[1 % images.count], tint: FemiTheme.accentBlue,
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



// MARK: - Generating overlay

private struct GeneratingOverlay: View {
    let kind: FemiGenerateViewModel.GenerationKind
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().stroke(FemiTheme.accentMagenta.opacity(0.4), lineWidth: 3)
                    .frame(width: 140, height: 140).blur(radius: 2)
                ProgressView().controlSize(.large).tint(FemiTheme.accentMagenta)
            }
            Text(title).font(.title3.bold()).foregroundStyle(FemiTheme.onSurface)
            Text(subtitle).font(.subheadline).foregroundStyle(FemiTheme.muted)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
        }
        .background(FemiTheme.background.ignoresSafeArea())
    }
    private var title: String {
        switch kind {
        case .initial: "Making your pictures"
        case .derived: "Making new ones"
        case .video: "Making your video"
        }
    }
    private var subtitle: String {
        switch kind {
        case .initial: "Music's on. Just a moment."
        case .derived: "Just a moment."
        case .video: "Almost there."
        }
    }
}

// MARK: - Grid helpers (match DemoGenerate styling)

@ViewBuilder
private func femiSelectionBadge(order: Int?) -> some View {
    ZStack {
        if let order {
            Text("\(order + 1)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(FemiTheme.accent, in: .circle)
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
private func femiHeartButton(isLiked: Bool, action: @escaping () -> Void) -> some View {
    Button {
        withAnimation(.spring(duration: 0.35)) { action() }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    } label: {
        if isLiked {
            Image(systemName: "heart.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(7)
                .background(FemiTheme.accent, in: .circle)
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

// MARK: - Grid

/// Single image cell. Heart toggles via `likeStore`; disk mirror in `toggleLikeImage`.
private struct FemiImageCell: View {
    let image: FemiGeneratedImage
    @Bindable var viewModel: FemiGenerateViewModel

    var body: some View {
        let liked = viewModel.likeStore.isLiked(image.id)
        let selecting = viewModel.isSelectingForVideo
        let selected = viewModel.selectedImageIds.contains(image.id)
        let eligible = !selecting || liked

        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay { FemiAuthorizedImage(filename: image.file) }
            .clipped()
            .overlay {
                if selecting && selected {
                    FemiTheme.accentMagenta.opacity(0.18)
                }
            }
            .overlay(alignment: .topTrailing) {
                if selecting {
                    if eligible {
                        femiSelectionBadge(
                            order: viewModel.selectedImageIds.firstIndex(of: image.id)
                        )
                    }
                } else {
                    femiHeartButton(isLiked: liked) {
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
}

/// Commit shelf while picking pictures for a video (Photos pattern).
private struct FemiMakeVideoShelf: View {
    @Bindable var viewModel: FemiGenerateViewModel

    var body: some View {
        Button("Make video") {
            viewModel.confirmMakeVideo()
        }
        .buttonStyle(FemiAccentButtonStyle())
        .disabled(viewModel.selectedImageIds.isEmpty)
        .opacity(viewModel.selectedImageIds.isEmpty ? 0.5 : 1)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
    }
}

private struct GridView: View {
    @Bindable var viewModel: FemiGenerateViewModel
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    private var visibleVideos: [FemiGeneratedVideo] {
        switch viewModel.filter {
        case .all, .videos: return viewModel.videos
        case .liked: return viewModel.videos.filter { viewModel.likeStore.isLiked($0.id) }
        }
    }

    /// Pending videos show on All and Videos filters (curation isn't possible yet).
    private var visibleFemiPendingVideos: [FemiPendingVideo] {
        switch viewModel.filter {
        case .all, .videos: return viewModel.pendingVideos
        case .liked: return []
        }
    }

    /// Pending uploads only visible on the All filter — they can't be liked yet.
    private var visibleFemiPendingImages: [FemiPendingImage] {
        viewModel.filter == .all ? viewModel.pendingImages : []
    }

    /// Pending generations only visible on the All filter for the same reason.
    private var visibleFemiPendingGenerations: [FemiPendingGeneration] {
        viewModel.filter == .all ? viewModel.pendingGenerations : []
    }

    private var hasNoContent: Bool {
        let imagesEmpty = viewModel.filter == .videos
            || (viewModel.filteredImages.isEmpty
                && visibleFemiPendingImages.isEmpty
                && visibleFemiPendingGenerations.isEmpty)
        let videosEmpty = visibleVideos.isEmpty && visibleFemiPendingVideos.isEmpty
        return imagesEmpty && videosEmpty
    }

    /// Sectioned layout kicks in only on the All filter and only after the
    /// user has pasted lyrics. Liked / Videos stay flat — those are curation
    /// surfaces and don't benefit from line grouping.
    private var shouldSection: Bool {
        viewModel.filter == .all && viewModel.audiolines != nil
    }

    private var bottomChromeMargin: CGFloat {
        viewModel.isSelectingForVideo ? 80 : 0
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            if hasNoContent {
                emptyState
            } else if shouldSection, let audiolines = viewModel.audiolines {
                sectionedScroll(audiolines: audiolines)
            } else {
                flatScroll
            }
        }
    }

    // MARK: - Flat scroll (pre-lyrics or non-All filters)

    private var flatScroll: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                if viewModel.filter != .videos {
                    ForEach(visibleFemiPendingImages) { pendingImageCell($0) }
                    ForEach(visibleFemiPendingGenerations) { pendingGenerationCell($0) }
                    ForEach(viewModel.filteredImages) { FemiImageCell(image: $0, viewModel: viewModel) }
                }
                ForEach(visibleFemiPendingVideos) { pendingCell($0) }
                ForEach(visibleVideos) { videoCell($0) }
            }
            .padding(.horizontal, 2)
            .padding(.top, 6)
        }
        .contentMargins(.bottom, bottomChromeMargin, for: .scrollContent)
    }

    // MARK: - Sectioned scroll (post-lyrics, All filter)

    /// Photos-style sectioned grid. Each lyric line is a `Section` with a
    /// pinned header that sticks to the top of the viewport as you scroll —
    /// matches the Photos.app pattern. Empty lines render as the header
    /// alone (no body), keeping the song's structure visible without noise.
    @ViewBuilder
    private func sectionedScroll(audiolines: [FemiSongLine]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                if !visibleFemiPendingImages.isEmpty || !visibleFemiPendingVideos.isEmpty {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(visibleFemiPendingImages) { pendingImageCell($0) }
                        ForEach(visibleFemiPendingVideos) { pendingCell($0) }
                    }
                    .padding(.horizontal, 2)
                    .padding(.top, 6)
                }

                ForEach(audiolines) { line in
                    let imagesForLine = viewModel.filteredImages.filter { $0.lineIndex == line.index }
                    let pendingsForLine = visibleFemiPendingGenerations.filter { $0.lineIndex == line.index }
                    Section {
                        if !pendingsForLine.isEmpty || !imagesForLine.isEmpty {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(pendingsForLine) { pendingGenerationCell($0) }
                                ForEach(imagesForLine) { FemiImageCell(image: $0, viewModel: viewModel) }
                            }
                            .padding(.horizontal, 2)
                            .padding(.top, 4)
                        }
                    } header: {
                        sectionHeader(
                            line: line,
                            imageCount: imagesForLine.count + pendingsForLine.count
                        )
                    }
                }

                if !visibleVideos.isEmpty {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(visibleVideos) { videoCell($0) }
                    }
                    .padding(.horizontal, 2)
                    .padding(.top, 12)
                }
            }
        }
        .contentMargins(.bottom, bottomChromeMargin, for: .scrollContent)
    }

    /// Photos-style section header: bold display title + small caption
    /// underneath, opaque background so the pinned state reads cleanly.
    /// Native power-user discovery via `.contextMenu` (long-press surfaces
    /// the action with iOS's own animation + haptic).
    @ViewBuilder
    private func sectionHeader(line: FemiSongLine, imageCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(line.text)
                .font(.title2.weight(.bold))
                .foregroundStyle(FemiTheme.onSurface)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Text(imageCount == 0 ? "No pictures yet"
                                : "\(imageCount) \(imageCount == 1 ? "picture" : "pictures")")
                .font(.subheadline)
                .foregroundStyle(FemiTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 28)
        .padding(.bottom, 10)
        .background(FemiTheme.background)
        .contextMenu {
            Button {
                viewModel.fillLine(line.index)
            } label: {
                Label("Make pictures for this line", systemImage: "sparkles")
            }
        }
        .accessibilityLabel(line.text)
    }

    // MARK: - Empty state (C6)

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: emptyIcon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(FemiTheme.muted)
            Text(emptyTitle)
                .font(.headline)
                .foregroundStyle(FemiTheme.onSurface)
            Text(emptyBody)
                .font(.subheadline)
                .foregroundStyle(FemiTheme.muted)
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
        case .liked: "Hold a picture to heart it. Hearted pictures can become videos."
        case .videos: "Heart a few pictures, then make a video."
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(FemiGenerateViewModel.GridFilter.allCases, id: \.self) { f in
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
                        Capsule().fill(FemiTheme.accentMagenta.opacity(0.25))
                            .overlay(Capsule().stroke(FemiTheme.accentMagenta.opacity(0.6), lineWidth: 1))
                    } else {
                        Capsule().fill(.white.opacity(0.08))
                    }
                }
                .foregroundStyle(viewModel.filter == f ? FemiTheme.onSurface : FemiTheme.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
    }

    // Sized square via a placeholder Color.clear with explicit 1:1 fit.
    // This pattern guarantees every column width matches; the old approach
    // (`.aspectRatio(1, contentMode: .fill)` on the image itself) let the image
    // propose its own intrinsic size first, which can fight the column width
    // and produce subtle differences across cells.


    /// Photos-style numbered selection badge. Empty circle when eligible-but-not-picked,
    /// magenta filled circle with the pick order when selected.
    @ViewBuilder
    private func selectionBadge(order: Int?) -> some View {
        ZStack {
            if let order {
                Text("\(order + 1)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(FemiTheme.accent, in: .circle)
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

    /// Shimmer cell while an uploaded photo is sent to the image service.
    @ViewBuilder
    private func pendingImageCell(_ pending: FemiPendingImage) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZStack {
                    FemiTheme.surface
                    if pending.state == .working {
                        Shimmer()
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
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
                    viewModel.dismissFemiPendingImage(pending.id)
                }
            }
    }

    /// Shimmer cell for in-flight image generation (derive or fill-line).
    /// Same visual language as `pendingImageCell` — the user reads "something
    /// is being made for this slot" without us having to label which kind.
    @ViewBuilder
    private func pendingGenerationCell(_ pending: FemiPendingGeneration) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZStack {
                    FemiTheme.surface
                    if pending.state == .working {
                        Shimmer()
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
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
                    viewModel.dismissFemiPendingGeneration(pending.id)
                }
            }
    }

    /// Shimmer cell with the source picture as a soft poster while video gen runs.
    /// When generation fails, taps dismiss the cell.
    @ViewBuilder
    private func pendingCell(_ pending: FemiPendingVideo) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZStack {
                    FemiAuthorizedImage(filename: pending.posterFile)
                        .opacity(pending.state == .failed ? 0.5 : 0.4)
                    if pending.state == .working {
                        VStack(spacing: 10) {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .controlSize(.regular)
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
                    viewModel.dismissFemiPendingVideo(pending.id)
                }
            }
    }

    @ViewBuilder
    private func videoCell(_ video: FemiGeneratedVideo) -> some View {
        // Videos aren't selectable for new videos (per spec: video-from-video deferred).
        // In select mode, dim them.
        let selecting = viewModel.isSelectingForVideo
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZStack {
                    let p = video.file.hasPrefix("/") ? String(video.file.dropFirst()) : video.file
                    if !p.isEmpty, let url = URL(string: "https://femi.market/\(p)") {
                        AuthorizedVideoView(url: url)
                    } else {
                        FemiAuthorizedImage(filename: video.posterFile)
                    }
                    Image(systemName: "play.circle.fill").font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.85)).shadow(radius: 4)
                }
            }
            .clipped()
            .overlay(alignment: .topTrailing) {
                if !selecting {
                    femiHeartButton(isLiked: viewModel.likeStore.isLiked(video.id)) {
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
            .accessibilityLabel("Video, double tap to watch")
            .accessibilityValue(viewModel.likeStore.isLiked(video.id) ? "Saved" : "")
    }
}

// MARK: - Completion

private struct CompletionView: View {
    let onDone: () -> Void
    @State private var pulse = false
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle().fill(FemiTheme.accentMagenta.opacity(pulse ? 0.5 : 0.2))
                    .frame(width: pulse ? 260 : 200, height: pulse ? 260 : 200)
                    .blur(radius: 30)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 96, weight: .bold))
                    .foregroundStyle(FemiTheme.accent)
            }
            VStack(spacing: 12) {
                Text("You did it.").font(.largeTitle.bold())
                    .foregroundStyle(FemiTheme.onSurface)
                Text("That's a video. Make more whenever you want.")
                    .font(.body).foregroundStyle(FemiTheme.muted)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(FemiAccentButtonStyle())
                .padding(.horizontal, 24).padding(.bottom, 48)
        }
        .background(FemiTheme.background.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}


// MARK: - JWT

private func jwtSub() -> String? {
    guard let token = UserDefaults.standard.string(forKey: "idToken") else { return nil }
    let parts = token.split(separator: ".")
    guard parts.count >= 2 else { return nil }
    var payload = String(parts[1])
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let pad = (4 - payload.count % 4) % 4
    payload.append(String(repeating: "=", count: pad))
    guard
        let data = Data(base64Encoded: payload),
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let sub = json["sub"] as? String
    else { return nil }
    return sub
}

/// First-batch prompt: Apple Intelligence if the on-device model is available,
/// otherwise a hardcoded fallback so the user still gets a generation.
fileprivate func initialStartPrompt() async -> String {
    let fallback = "A vibrant music video opening scene"
    guard case .available = SystemLanguageModel.default.availability else {
        return fallback
    }
    do {
        let session = LanguageModelSession(
            instructions: "Write a single vivid one-sentence visual prompt for the opening scene of a music video. Respond with only the scene description, no preamble."
        )
        let response = try await session.respond(to: "Generate a music video opening scene prompt.")
        let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? fallback : text
    } catch {
        return fallback
    }
}
