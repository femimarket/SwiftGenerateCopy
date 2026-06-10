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
import StoreKit
import PhotosUI
import Observation
import Api

// MARK: - Auth context (set once at app launch in GenerateApp.swift)

enum AppAuth {
    static var bearer: String {
        UserDefaults.standard.string(forKey: "idToken") ?? ""
    }
    static var userId: String {
        jwtSub() ?? ""
    }
}

/// Dev seed flag — set true to pre-populate GenerateViewModel with a sample
/// project + bundled images. Off for normal runs.
private let devSeedEnabled = false

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

// MARK: - Media URL helper
// Media (images / audio / video filenames returned by generation endpoints)
// are served from femi.market, not api.earnfemi.com.

private enum Media {
    static func url(_ filename: String) -> URL? {
        guard !filename.isEmpty else { return nil }
        let path = filename.hasPrefix("/") ? String(filename.dropFirst()) : filename
        return URL(string: "https://femi.market/\(path)")
    }

    static var authHeaders: [String: String] {
        ["Authorization": "Bearer \(AppAuth.bearer)"]
    }

    // Dedicated session for media fetches (images, video, audio).
    // - Concurrency capped so a 30-cell grid doesn't blast 30 simultaneous requests.
    // - In-memory + on-disk cache so liked / re-shown items don't re-incur the bandwidth charge.
    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 6
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(
            memoryCapacity: 64 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024
        )
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()
}

// MARK: - Local models (client-side state)

struct GeneratedImage: Identifiable, Hashable, Sendable {
    enum Source: String, Sendable { case lyra, vega, luna, upload }
    let id: UUID
    let file: String
    let prompt: String
    let source: Source
    /// Index into `GenerateViewModel.audiolines`. Nil before lyrics are pasted.
    /// Drives the Photos-style by-line grouping in the grid.
    var lineIndex: Int? = nil
}

/// A single timed lyric line. Server-side forced alignment is the production
/// path; the client stub in `pasteLyrics` assigns equal 6s windows as a
/// placeholder until that pipeline exists.
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
}

/// A video that's being generated in the background. The grid renders this as a
/// shimmer cell so the user can keep doing other things while it cooks.
struct PendingVideo: Identifiable, Hashable, Sendable {
    enum State: Hashable, Sendable { case working, failed }
    let id: UUID
    let sourceImageIds: [UUID]
    let posterFile: String
    var state: State = .working
}

/// An image being uploaded from the user's photo library. Mirrors PendingVideo —
/// the grid shows a shimmer cell while the upload happens in the background.
struct PendingImage: Identifiable, Hashable, Sendable {
    enum State: Hashable, Sendable { case working, failed }
    let id: UUID
    var state: State = .working
}

/// An in-flight image generation (derive or fill-line). Rendered as a shimmer
/// cell in the grid so the rest of the UI stays interactive. `lineIndex` is
/// pre-computed at task start so the cell lands in the correct section.
struct PendingGeneration: Identifiable, Hashable, Sendable {
    enum State: Hashable, Sendable { case working, failed }
    let id: UUID
    let lineIndex: Int?
    var state: State = .working
}

// MARK: - API service wrapper

private struct GenerateService: Sendable {

    // Credit & pricing are POST envelopes; we send placeholder zeros and read the response.
    func currentCredit() async throws -> Credit {
        try await CreditAPI.creditRoute(credits: 0)
    }

    func currentPricing() async throws -> Pricing {
        try await PricingAPI.pricingRoute(
            artist: 0, audio: 0, chat: 0, creator: 0, director: 0,
            gb: 0, id: UUID(), image: 0,
            microPixLyra: 0, microPixVega: 0, nanoPixLuna: 0, nanoRenSpica: 0,
            question: 0, summary: 0, lyricSync: nil
        )
    }

    func latestProject() async throws -> Project? {
        let response = try await ProjectRouteAPI.project(
            userId: AppAuth.userId,
            paginate: ProjectPaginate(data: nil, skip: 0, take: 1)
        )
        return response.paginate?.data?.first
    }

    func allProjects() async throws -> [Project] {
        let response = try await ProjectRouteAPI.project(
            userId: AppAuth.userId,
            paginate: ProjectPaginate(data: nil, skip: 0, take: 50)
        )
        return response.paginate?.data ?? []
    }

    /// Hard cap on prompt size before sending to image models.
    /// The image models (Vega in particular) reject prompts above this length.
    private let imagePromptMax = 400

    private func capped(_ s: String) -> String {
        s.count <= imagePromptMax ? s : String(s.prefix(imagePromptMax))
    }

    func chatPrompt(_ seed: String) async throws -> String {
        let instruction = "Write one concise image-generation prompt (max 300 characters) for this scene: \(seed)"
        let chat = Chat(
            id: UUID(),
            messages: [ChatMessage(content: instruction, role: ._1)],
            userId: AppAuth.userId
        )
        let response = try await ChatRouteAPI.chat(
            userId: AppAuth.userId,
            upsert: ChatUpsert(data: [chat])
        )
        let reply = response.upsert?.data.first?.messages
            .first(where: { $0.role == ._2 })?.content ?? seed
        return capped(reply)
    }

    func chatDerive(priorPrompt: String, userTweak: String) async throws -> String {
        let instruction = "Rewrite the image prompt with this change. One concise prompt only (max 300 characters). Change: \(userTweak)"
        let chat = Chat(
            id: UUID(),
            messages: [
                ChatMessage(content: priorPrompt, role: ._2),
                ChatMessage(content: instruction, role: ._1),
            ],
            userId: AppAuth.userId
        )
        let response = try await ChatRouteAPI.chat(
            userId: AppAuth.userId,
            upsert: ChatUpsert(data: [chat])
        )
        let reply = response.upsert?.data.first?.messages
            .last(where: { $0.role == ._2 })?.content ?? userTweak
        return capped(reply)
    }

    /// Fan out 3 text-to-image models in parallel: Lyra, Vega, Luna.
    /// Each call upserts (status = Pending) and then polls by id until status = Completed.
    func generateImageBatch(prompt: String) async -> [GeneratedImage] {
        async let lyra = generateLyra(prompt: prompt)
        async let vega = generateVega(prompt: prompt)
        async let luna = generateLuna(prompt: prompt)
        return await [lyra, vega, luna].compactMap { $0 }
    }

    // Polling constants. Status: 1 = Pending, 2 = Completed, 3 = Failed.
    private var pollInterval: Duration { .milliseconds(1500) }
    private var pollTimeout: Duration { .seconds(120) }

    private func generateLyra(prompt: String) async -> GeneratedImage? {
        let payload = MicroPixLyra(
            id: UUID(), prompt: prompt, status: ._1, userId: AppAuth.userId
        )
        guard let started = try? await MicroPixLyraRouteAPI.microPixLyra(
            userId: AppAuth.userId, upsert: MicroPixLyraUpsert(data: [payload])
        ).upsert?.data.first else { return nil }
        guard let done = try? await pollLyra(id: started.id), let file = done.file
        else { return nil }
        return GeneratedImage(id: done.id, file: file, prompt: done.prompt, source: .lyra)
    }

    private func pollLyra(id: UUID) async throws -> MicroPixLyra {
        let started = ContinuousClock.now
        while ContinuousClock.now - started <= pollTimeout {
            let r = try await MicroPixLyraRouteAPI.microPixLyra(
                userId: AppAuth.userId, byId: MicroPixLyraById(id: id)
            )
            if let row = r.byId?.data {
                switch row.status {
                case ._2: return row
                case ._3: throw NSError(domain: "Lyra", code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Generation failed"])
                case ._1: break
                }
            }
            try await Task.sleep(for: pollInterval)
        }
        throw NSError(domain: "Lyra", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Timed out"])
    }

    private func generateVega(prompt: String) async -> GeneratedImage? {
        let payload = MicroPixVega(
            id: UUID(), prompt: prompt, status: ._1, userId: AppAuth.userId
        )
        guard let started = try? await MicroPixVegaRouteAPI.microPixVega(
            userId: AppAuth.userId, upsert: MicroPixVegaUpsert(data: [payload])
        ).upsert?.data.first else { return nil }
        guard let done = try? await pollVega(id: started.id), let file = done.file
        else { return nil }
        return GeneratedImage(id: done.id, file: file, prompt: done.prompt, source: .vega)
    }

    private func pollVega(id: UUID) async throws -> MicroPixVega {
        let started = ContinuousClock.now
        while ContinuousClock.now - started <= pollTimeout {
            let r = try await MicroPixVegaRouteAPI.microPixVega(
                userId: AppAuth.userId, byId: MicroPixVegaById(id: id)
            )
            if let row = r.byId?.data {
                switch row.status {
                case ._2: return row
                case ._3: throw NSError(domain: "Vega", code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Generation failed"])
                case ._1: break
                }
            }
            try await Task.sleep(for: pollInterval)
        }
        throw NSError(domain: "Vega", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Timed out"])
    }

    private func generateLuna(prompt: String) async -> GeneratedImage? {
        let payload = NanoPixLuna(
            id: UUID(), prompt: prompt, status: ._1, userId: AppAuth.userId
        )
        guard let started = try? await NanoPixLunaRouteAPI.nanoPixLuna(
            userId: AppAuth.userId, upsert: NanoPixLunaUpsert(data: [payload])
        ).upsert?.data.first else { return nil }
        guard let done = try? await pollLuna(id: started.id), let file = done.file
        else { return nil }
        return GeneratedImage(id: done.id, file: file, prompt: done.prompt, source: .luna)
    }

    private func pollLuna(id: UUID) async throws -> NanoPixLuna {
        let started = ContinuousClock.now
        while ContinuousClock.now - started <= pollTimeout {
            let r = try await NanoPixLunaRouteAPI.nanoPixLuna(
                userId: AppAuth.userId, byId: NanoPixLunaById(id: id)
            )
            if let row = r.byId?.data {
                switch row.status {
                case ._2: return row
                case ._3: throw NSError(domain: "Luna", code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Generation failed"])
                case ._1: break
                }
            }
            try await Task.sleep(for: pollInterval)
        }
        throw NSError(domain: "Luna", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Timed out"])
    }

    /// Image-to-video. Upserts (Pending) then polls until Completed.
    func generateVideo(
        imageFile: String,
        audioFile: String,
        prompt: String
    ) async throws -> String {
        let payload = NanoRenSpica(
            audio: audioFile, id: UUID(), image: imageFile,
            prompt: prompt, status: ._1, userId: AppAuth.userId
        )
        guard let started = try await NanoRenSpicaRouteAPI.nanoRenSpica(
            userId: AppAuth.userId, upsert: NanoRenSpicaUpsert(data: [payload])
        ).upsert?.data.first else {
            throw NSError(domain: "Video", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No record returned"])
        }
        let done = try await pollSpica(id: started.id)
        guard let file = done.file else {
            throw NSError(domain: "Video", code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Completed but no file"])
        }
        return file
    }

    private func pollSpica(id: UUID) async throws -> NanoRenSpica {
        let started = ContinuousClock.now
        while ContinuousClock.now - started <= pollTimeout {
            let r = try await NanoRenSpicaRouteAPI.nanoRenSpica(
                userId: AppAuth.userId, byId: NanoRenSpicaById(id: id)
            )
            if let row = r.byId?.data {
                switch row.status {
                case ._2: return row
                case ._3: throw NSError(domain: "Spica", code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Video generation failed"])
                case ._1: break
                }
            }
            try await Task.sleep(for: pollInterval)
        }
        throw NSError(domain: "Spica", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Timed out"])
    }

    /// Required pre-step for video: register an existing generated image as an Image record.
    /// Downloads bytes from femi.market then re-uploads via /image multipart.
    func registerImageForVideo(filename: String) async throws -> String {
        guard let downloadURL = Media.url(filename) else {
            throw NSError(domain: "Image", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Bad filename"])
        }
        var dl = URLRequest(url: downloadURL)
        for (k, v) in Media.authHeaders { dl.setValue(v, forHTTPHeaderField: k) }
        let (data, _) = try await Media.session.data(for: dl)
        return try await uploadImageBinary(
            data: data,
            suggestedName: (filename as NSString).lastPathComponent
        )
    }

    // MARK: - Line-scoped audio for video generation

    /// Downloads the project audio, trims to `(startMs, durationMs)` via
    /// AVAssetExportSession, uploads the slice as a new Audio record, returns
    /// the resulting server filename. Caller passes the trimmed filename to
    /// NanoRenSpica so the audio-conditioned video matches the lyric line's
    /// moment in the song. Throws on any step — caller is expected to fall
    /// back to the full project audio.
    func trimAndUploadAudioClip(
        sourceAudioFile: String,
        startMs: Int,
        durationMs: Int
    ) async throws -> String {
        guard let sourceURL = Media.url(sourceAudioFile) else {
            throw NSError(domain: "Audio", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Bad source audio filename"])
        }
        // 1) Fetch source bytes (Media.session caches so repeated trims for
        // the same song don't re-download).
        var req = URLRequest(url: sourceURL)
        for (k, v) in Media.authHeaders { req.setValue(v, forHTTPHeaderField: k) }
        let (data, _) = try await Media.session.data(for: req)
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

        // 3) Upload as Audio multipart.
        let clipData = try Data(contentsOf: outputURL)
        return try await uploadAudioBinary(
            data: clipData,
            suggestedName: "clip-\(UUID().uuidString).m4a"
        )
    }

    func uploadAudioBinary(data: Data, suggestedName: String) async throws -> String {
        var request = URLRequest(url: URL(string: ApiAPIConfiguration.shared.basePath + "/audio")!)
        request.httpMethod = "POST"
        for (k, v) in Media.authHeaders { request.setValue(v, forHTTPHeaderField: k) }
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")

        var body = Data()
        func append(_ s: String) { body.append(s.data(using: .utf8)!) }
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n")
        append("\(AppAuth.userId)\r\n")
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"upsert[data][0][id]\"\r\n\r\n")
        append("\(UUID().uuidString)\r\n")
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"upsert[data][0][file]\"; filename=\"\(suggestedName)\"\r\n")
        append("Content-Type: audio/mp4\r\n\r\n")
        body.append(data)
        append("\r\n--\(boundary)--\r\n")
        request.httpBody = body

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode)
        else {
            throw NSError(domain: "Audio", code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Audio upload failed"])
        }
        let server = try JSONDecoder().decode(AudioServerRequest.self, from: responseData)
        guard let file = server.upsert?.data.first?.file else {
            throw NSError(domain: "Audio", code: -5,
                userInfo: [NSLocalizedDescriptionKey: "No file in audio upload response"])
        }
        return file
    }

    func uploadImageBinary(data: Data, suggestedName: String) async throws -> String {
        var request = URLRequest(url: URL(string: ApiAPIConfiguration.shared.basePath + "/image")!)
        request.httpMethod = "POST"
        for (k, v) in Media.authHeaders { request.setValue(v, forHTTPHeaderField: k) }
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func append(_ s: String) { body.append(s.data(using: .utf8)!) }
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n")
        append("\(AppAuth.userId)\r\n")
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"upsert[data][0][id]\"\r\n\r\n")
        append("\(UUID().uuidString)\r\n")
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"upsert[data][0][file]\"; filename=\"\(suggestedName)\"\r\n")
        append("Content-Type: image/jpeg\r\n\r\n")
        body.append(data)
        append("\r\n--\(boundary)--\r\n")

        request.httpBody = body
        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "Image", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }
        let server = try JSONDecoder().decode(ImageServerRequest.self, from: responseData)
        guard let file = server.upsert?.data.first?.file else {
            throw NSError(domain: "Image", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "No file returned"])
        }
        return file
    }
}

// MARK: - Onboarding audio (app-scoped, primed at launch)

/// App-scoped singleton. `prepare(...)` runs the heavy work (bundle URL
/// lookup, decode, prepareToPlay) off-main. Call it once at launch — by the
/// time the splash appears the player is sitting ready. `start()` is the hot
/// path: no I/O, just `play()` on main. Per engine: heavy work runs detached,
/// then hands off — the interactive moment never blocks on I/O.
@MainActor @Observable
final class OnboardingAudio {
    static let shared = OnboardingAudio()

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

// MARK: - Like store (client-only, UserDefaults)

@MainActor @Observable
private final class LikeStore {
    private let key = "GenerateLikedIds.v1"
    private(set) var liked: Set<String>

    init() {
        liked = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    func isLiked(_ id: UUID) -> Bool { liked.contains(id.uuidString) }

    func toggle(_ id: UUID) {
        if liked.contains(id.uuidString) { liked.remove(id.uuidString) }
        else { liked.insert(id.uuidString) }
        UserDefaults.standard.set(Array(liked), forKey: key)
    }
}

// MARK: - StoreKit2 topup

@MainActor @Observable
private final class StoreService {
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

    private(set) var products: [Tier: Product] = [:]
    private(set) var error: String?

    func loadProducts() async {
        do {
            let ids = Tier.allCases.map(\.rawValue)
            let fetched = try await Product.products(for: ids)
            var dict: [Tier: Product] = [:]
            for p in fetched { if let t = Tier(rawValue: p.id) { dict[t] = p } }
            products = dict
            if fetched.isEmpty {
                error = "No products matched IDs: \(ids.joined(separator: ", ")). Check App Store Connect, your sandbox tester sign-in, or add a Configuration.storekit file to the scheme for simulator testing."
            } else if fetched.count < ids.count {
                let missing = Set(ids).subtracting(fetched.map(\.id))
                error = "Missing products: \(missing.joined(separator: ", "))"
            } else {
                error = nil
            }
        } catch {
            self.error = "Could not load products: \(error.localizedDescription)"
        }
    }

    /// Returns true if purchase succeeded and the receipt was submitted server-side.
    func purchase(_ tier: Tier) async throws -> Bool {
        guard let product = products[tier] else { return false }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .unverified: return false
            case .verified(let transaction):
                let priceMinor = NSDecimalNumber(decimal: product.price)
                    .multiplying(by: 100)
                    .int64Value
                let currencyCode = product.priceFormatStyle.currencyCode
                _ = try await ApplePayRouteAPI.applePay(
                    userId: AppAuth.userId,
                    upsert: ApplePayUpsert(data: [
                        ApplePay(
                            credit: 0,
                            currency: currencyCode,
                            id: UUID(),
                            jws: verification.jwsRepresentation,
                            loaded: false,
                            price: priceMinor,
                            productId: tier.rawValue,
                            status: .pending,
                            transactionId: String(transaction.id),
                            userId: AppAuth.userId
                        )
                    ])
                )
                await transaction.finish()
                return true
            }
        case .userCancelled, .pending: return false
        @unknown default: return false
        }
    }
}

// MARK: - View model

@MainActor @Observable
private final class GenerateViewModel {

    enum GenerationKind: Hashable { case initial, derived, video }

    enum Phase: Hashable {
        case onboarding
        case generating(GenerationKind)
        case grid
        case derive(image: GeneratedImage)
        case complete
    }

    enum TutorialMoment: Hashable {
        case none, tapImageToDerive, likeAnImage, selectLikedForVideo, likeYourVideo
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

    var presentingCostBreakdown = false
    var presentingTopup = false
    var presentingLyricPaste = false
    var presentingProjects = false
    var presentingNewSong = false
    private var pendingActionAfterTopup: (() -> Void)?

    /// All of the user's projects, loaded via paginate. Drives the toolbar
    /// switcher list. Includes the current project.
    var allProjects: [Project] = []

    /// Pasted lyrics text. Nil until the user pastes via the scene-player
    /// affordance. Once set, the grid switches from flat to sectioned-by-line.
    var lyrics: String?
    /// Timed lyric lines. Populated by `pasteLyrics`. Nil before paste.
    var audiolines: [SongLine]?

    /// Set once the user agrees to the bandwidth + generation cost breakdown.
    /// After this we silently deduct costs (still showing the inline cost on CTAs).
    private let consentKey = "hasAgreedToGenerateCosts"
    var hasGivenConsent: Bool {
        get { UserDefaults.standard.bool(forKey: consentKey) }
        set { UserDefaults.standard.set(newValue, forKey: consentKey) }
    }

    let likeStore = LikeStore()
    let store = StoreService()
    let onboardingAudio = OnboardingAudio.shared
    private let service = GenerateService()

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
    /// filenames point at bundled assets so `AuthorizedImage`'s dev-mode
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
            GeneratedImage(
                id: UUID(),
                file: name,
                prompt: "Dev seed",
                source: .lyra
            )
        }
        self.phase = .grid
        self.hasGivenConsent = true
    }

    // Derived

    var filteredImages: [GeneratedImage] {
        switch filter {
        case .all, .videos: images
        case .liked: images.filter { likeStore.isLiked($0.id) }
        }
    }
    var likedImages: [GeneratedImage] { images.filter { likeStore.isLiked($0.id) } }

    /// chat + 3 image models. Bandwidth (1 credit min per file we render) is shown separately.
    var generationCost: Int64 {
        guard let p = pricing else { return 0 }
        return p.chat + p.microPixLyra + p.microPixVega + p.nanoPixLuna
    }

    /// image upload + nano_ren_spica. Bandwidth charged on poster/video display.
    var videoCost: Int64 {
        guard let p = pricing else { return 0 }
        return p.image + p.nanoRenSpica
    }

    /// Approximate "this loop will cost a few credits in bandwidth" hint shown in the consent sheet.
    /// Actual rate is 100 credits/GB (server-driven via `pricing.gb`), min 1 credit per file.
    var bandwidthMinPerFile: Int64 { 1 }

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
    func tagBatch(_ batch: [GeneratedImage]) -> [GeneratedImage] {
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
        await store.loadProducts()
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

    // Start (first generation). Always opens the consent sheet the first time.

    func tapStart() {
        // Fade the onboarding WAV out as the user transitions away from the
        // onboarding/Ready beat. Idempotent if it's already stopped.
        onboardingAudio.fadeOut(duration: 0.6)
        if hasGivenConsent {
            Task { await performInitialGeneration() }
        } else {
            presentingCostBreakdown = true
        }
    }

    func confirmConsent() {
        hasGivenConsent = true
        presentingCostBreakdown = false
        Task {
            await performInitialGeneration()
        }
    }

    func declineConsent() {
        presentingCostBreakdown = false
    }

    private func performInitialGeneration() async {
        guard gateOnCredit(cost: generationCost, retry: { [weak self] in
            Task { await self?.performInitialGeneration() }
        }) else { return }

        phase = .generating(.initial)
        let seed = project?.summary
            ?? project?.audioLines.first?.line
            ?? "A vibrant music video opening scene"
        do {
            let enriched = try await service.chatPrompt(seed)
            let batch = await service.generateImageBatch(prompt: enriched)
            images = tagBatch(batch)
            await refreshCredit()
            phase = .grid
            tutorialMoment = .tapImageToDerive
        } catch {
            errorMessage = error.localizedDescription
            phase = .grid
        }
    }

    // Derive

    func openDerive(_ image: GeneratedImage) { phase = .derive(image: image) }

    /// Fire-and-forget. Pops back to the grid immediately, drops shimmer cells
    /// in the right sections, and runs the actual generation in a background
    /// Task — same UX pattern as `confirmMakeVideo`. The user can derive more,
    /// like, browse, queue more videos while this is cooking.
    func submitDerivation(from image: GeneratedImage, tweak: String) {
        guard gateOnCredit(cost: generationCost, retry: { [weak self] in
            self?.submitDerivation(from: image, tweak: tweak)
        }) else { return }

        // Pre-compute the line indices so the pending cells appear in their
        // final sections immediately (no jumping when they resolve).
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
            // Pop derive — back to grid with the shimmer cells in place.
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
                        self.tutorialMoment = .likeAnImage
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

    // Like

    func toggleLikeImage(_ image: GeneratedImage) {
        likeStore.toggle(image.id)
        if likeStore.isLiked(image.id), tutorialMoment == .likeAnImage {
            // Move the tutorial forward — the coach mark will point at the
            // top-right "Make Video" button so the user knows the next step.
            // No auto-filter switch: Liked filter is pure declutter.
            tutorialMoment = .selectLikedForVideo
        }
    }

    func toggleLikeVideo(_ video: GeneratedVideo) {
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

    /// Fire-and-forget. Adds a PendingVideo immediately, kicks off the long generation
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

        let pending = PendingVideo(
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
                    self.videos.append(GeneratedVideo(
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
    func dismissPendingVideo(_ id: UUID) {
        withAnimation { pendingVideos.removeAll { $0.id == id } }
    }

    // MARK: - Upload your own image

    /// Fire-and-forget upload. User-supplied bytes go to /image, server returns a
    /// filename, we add it to the grid as a normal GeneratedImage (source: .upload).
    /// Same async pattern as video gen — grid stays interactive while upload runs.
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
}

// MARK: - Authorized image (femi.market, header-injected)

private struct AuthorizedImage: View {
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
                    Image(systemName: "photo").foregroundStyle(Theme.muted)
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
        guard let url = Media.url(filename) else { failed = true; return }
        var req = URLRequest(url: url)
        for (k, v) in Media.authHeaders { req.setValue(v, forHTTPHeaderField: k) }
        do {
            // Media.session caps to 6 concurrent + caches, so a sea of cells
            // doesn't blast the server (C9) and re-displays are instant.
            let (data, _) = try await Media.session.data(for: req)
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
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": Media.authHeaders
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
    let video: GeneratedVideo
    @Bindable var viewModel: GenerateViewModel
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
                AuthorizedImage(filename: video.posterFile)
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
                        .stroke(Theme.accentMagenta.opacity(0.45), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .buttonStyle(.plain)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private func setupPlayback() {
        guard let url = Media.url(video.file) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": Media.authHeaders
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
    @Bindable var viewModel: GenerateViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                cardPager
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
                            .foregroundStyle(Theme.accentMagenta)
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
                        .fill(Theme.accent)
                        .frame(width: 96, height: 96)
                        .shadow(color: Theme.accentMagenta.opacity(0.5),
                                radius: 24, y: 8)
                    Image(systemName: "plus")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("New song")
                    .font(.title.bold())
                    .foregroundStyle(Theme.onSurface)
                Text("Start a fresh production.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
            }
            .frame(width: cardWidth, height: cardHeight)
            .background(Theme.surface, in: .rect(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Theme.accentMagenta.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
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
/// `Theme.background` instead of the default sheet material.
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
                    Text("Drop your lyrics here. One line at a time — the way your song breathes.")
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

struct Generate: View {
    var onContinue: () -> Void

    @State private var viewModel = GenerateViewModel()
    @State private var photoPickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .toolbar { toolbar }
            .navigationDestination(isPresented: deriveBinding) {
                if case .derive(let image) = viewModel.phase {
                    DeriveView(image: image, viewModel: viewModel)
                }
            }
            .sheet(isPresented: $viewModel.presentingCostBreakdown) {
                CostBreakdownSheet(viewModel: viewModel)
                    .presentationDetents([.large])
                    .presentationBackground(.clear)
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
            .sheet(isPresented: $viewModel.presentingProjects) {
                ProjectsSheet(viewModel: viewModel)
                    .presentationDetents([.large])
                    .presentationBackground(.regularMaterial)
            }
            .fullScreenCover(isPresented: $viewModel.presentingNewSong) {
                SongView(onComplete: { _ in viewModel.handleSongPicked() })
            }
        }
        .preferredColorScheme(.dark)
        .task { await viewModel.bootstrap() }
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
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .onboarding:
            KineticOnboardingView(onComplete: viewModel.finishOnboarding)
                .task { viewModel.onboardingAudio.start(resource: "onboarding", ext: "wav") }
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
                if shouldShowUploadButton {
                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Theme.onSurface)
                    }
                }
            }
            // Project switcher: tap song name → ProjectsSheet. Always renders
            // so the principal slot is never empty.
            ToolbarItem(placement: .principal) {
                Button(action: viewModel.openProjects) {
                    HStack(spacing: 6) {
                        Text(viewModel.project.map { projectTitle($0) } ?? "Generate")
                            .font(.headline)
                            .foregroundStyle(Theme.onSurface)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .buttonStyle(.plain)
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
                    .foregroundStyle(viewModel.canMakeVideo ? Theme.onSurface : Theme.muted)
                    .disabled(!viewModel.canMakeVideo)
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
    var images: [String] = ["img1", "img2", "img3", "img4"]
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
        // Asset-catalog images, shipped in the binary. Faster than AuthorizedImage
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



// MARK: - Generating overlay

private struct GeneratingOverlay: View {
    let kind: GenerateViewModel.GenerationKind
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().stroke(Theme.accentMagenta.opacity(0.4), lineWidth: 3)
                    .frame(width: 140, height: 140).blur(radius: 2)
                ProgressView().controlSize(.large).tint(Theme.accentMagenta)
            }
            Text(title).font(.title3.bold()).foregroundStyle(Theme.onSurface)
            Text(subtitle).font(.subheadline).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
        }
        .background(Theme.background.ignoresSafeArea())
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

    /// Pending videos show on All and Videos filters (curation isn't possible yet).
    private var visiblePendingVideos: [PendingVideo] {
        switch viewModel.filter {
        case .all, .videos: return viewModel.pendingVideos
        case .liked: return []
        }
    }

    /// Pending uploads only visible on the All filter — they can't be liked yet.
    private var visiblePendingImages: [PendingImage] {
        viewModel.filter == .all ? viewModel.pendingImages : []
    }

    /// Pending generations only visible on the All filter for the same reason.
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

    /// Sectioned layout kicks in only on the All filter and only after the
    /// user has pasted lyrics. Liked / Videos stay flat — those are curation
    /// surfaces and don't benefit from line grouping.
    private var shouldSection: Bool {
        viewModel.filter == .all && viewModel.audiolines != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            filterBar
            if hasNoContent {
                emptyState
            } else if shouldSection, let audiolines = viewModel.audiolines {
                sectionedScroll(audiolines: audiolines)
                    .safeAreaInset(edge: .bottom) { makeVideoCta }
            } else {
                flatScroll
                    .safeAreaInset(edge: .bottom) { makeVideoCta }
            }
        }
    }

    @ViewBuilder
    private var makeVideoCta: some View {
        if viewModel.isSelectingForVideo {
            Button {
                viewModel.confirmMakeVideo()
            } label: {
                HStack(spacing: 6) {
                    Text("Make")
                    Text("·").opacity(0.5)
                    Image(systemName: "bolt.fill").font(.footnote)
                    Text("\(viewModel.videoCost)").monospacedDigit()
                }
            }
            .buttonStyle(AccentButtonStyle())
            .disabled(viewModel.selectedImageIds.isEmpty)
            .opacity(viewModel.selectedImageIds.isEmpty ? 0.5 : 1)
            .padding(16)
            .background(.regularMaterial)
        }
    }

    // MARK: - Flat scroll (pre-lyrics or non-All filters)

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
    }

    // MARK: - Sectioned scroll (post-lyrics, All filter)

    /// Photos-style sectioned grid. Each lyric line is a `Section` with a
    /// pinned header that sticks to the top of the viewport as you scroll —
    /// matches the Photos.app pattern. Empty lines render as the header
    /// alone (no body), keeping the song's structure visible without noise.
    @ViewBuilder
    private func sectionedScroll(audiolines: [SongLine]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                if !visiblePendingImages.isEmpty || !visiblePendingVideos.isEmpty {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(visiblePendingImages) { pendingImageCell($0) }
                        ForEach(visiblePendingVideos) { pendingCell($0) }
                    }
                    .padding(.horizontal, 2)
                    .padding(.top, 6)
                }

                ForEach(audiolines) { line in
                    let imagesForLine = viewModel.filteredImages.filter { $0.lineIndex == line.index }
                    let pendingsForLine = visiblePendingGenerations.filter { $0.lineIndex == line.index }
                    Section {
                        if !pendingsForLine.isEmpty || !imagesForLine.isEmpty {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(pendingsForLine) { pendingGenerationCell($0) }
                                ForEach(imagesForLine) { imageCell($0) }
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
    }

    /// Photos-style section header: bold display title + small caption
    /// underneath, opaque background so the pinned state reads cleanly.
    /// Native power-user discovery via `.contextMenu` (long-press surfaces
    /// the action with iOS's own animation + haptic).
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
        .background(Theme.background)
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
        case .liked: "Hold a picture to heart it. Hearted pictures can become videos."
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

    // Sized square via a placeholder Color.clear with explicit 1:1 fit.
    // This pattern guarantees every column width matches; the old approach
    // (`.aspectRatio(1, contentMode: .fill)` on the image itself) let the image
    // propose its own intrinsic size first, which can fight the column width
    // and produce subtle differences across cells.

    @ViewBuilder
    private func imageCell(_ image: GeneratedImage) -> some View {
        let liked = viewModel.likeStore.isLiked(image.id)
        let selecting = viewModel.isSelectingForVideo
        let selected = viewModel.selectedImageIds.contains(image.id)
        // In select mode, non-liked pictures aren't eligible — dim + ignore taps.
        let eligible = !selecting || liked

        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                AuthorizedImage(filename: image.file)
            }
            .clipped()
            .overlay {
                // Subtle accent overlay on selected cells.
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
    }

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

    /// Shimmer cell while an uploaded photo is sent to the image service.
    @ViewBuilder
    private func pendingImageCell(_ pending: PendingImage) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZStack {
                    Theme.surface
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
                    viewModel.dismissPendingImage(pending.id)
                }
            }
    }

    /// Shimmer cell for in-flight image generation (derive or fill-line).
    /// Same visual language as `pendingImageCell` — the user reads "something
    /// is being made for this slot" without us having to label which kind.
    @ViewBuilder
    private func pendingGenerationCell(_ pending: PendingGeneration) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                ZStack {
                    Theme.surface
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
                    viewModel.dismissPendingGeneration(pending.id)
                }
            }
    }

    /// Shimmer cell with the source picture as a soft poster while video gen runs.
    /// When generation fails, taps dismiss the cell.
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
                    viewModel.dismissPendingVideo(pending.id)
                }
            }
    }

    @ViewBuilder
    private func videoCell(_ video: GeneratedVideo) -> some View {
        // Videos aren't selectable for new videos (per spec: video-from-video deferred).
        // In select mode, dim them.
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
    }

    /// Always-visible heart button. Outline = not saved, filled magenta pill = saved.
    /// Sits inside cell as a Button so its tap is consumed before the cell's
    /// `onTapGesture` (which opens derive). One affordance, two states.
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
            // Compact context header — thumbnail + "from this one" framing.
            // Keeps the source picture visible while leaving room for the input.
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

            // Vertical-axis TextField gets a real placeholder and grows naturally.
            // No overlay hack, no alignment drift on first keystroke.
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
        // Auto-focus the field so the keyboard rises immediately — this screen
        // exists for one thing.
        .onAppear { focused = true }
        // Keyboard accessory: Done button to dismiss without losing the draft.
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = false }
                    .font(.body.weight(.semibold))
            }
        }
        // CTA in safeAreaInset so the keyboard pushes it up instead of covering it.
        // Material extends to the bottom safe area automatically.
        .safeAreaInset(edge: .bottom) {
            Button {
                focused = false
                viewModel.submitDerivation(from: image, tweak: trimmed)
            } label: {
                HStack(spacing: 6) {
                    if trimmed.isEmpty {
                        Text("Type to make new ones")
                    } else {
                        Text("Make new ones")
                        Text("·").opacity(0.5)
                        Image(systemName: "bolt.fill").font(.footnote)
                        Text("\(viewModel.generationCost)").monospacedDigit()
                    }
                }
                .animation(.easeInOut(duration: 0.15), value: trimmed.isEmpty)
            }
            .buttonStyle(AccentButtonStyle())
            .disabled(trimmed.isEmpty)
            .padding(16)
            .background(.regularMaterial)
        }
    }
}

// MARK: - Cost breakdown (first-time consent — bandwidth + generation)

private struct CostBreakdownSheet: View {
    @Bindable var viewModel: GenerateViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Capsule().fill(.white.opacity(0.2)).frame(width: 40, height: 4).padding(.top, 8)
                VStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Theme.accent)
                    Text("Quick check").font(.title2.bold())
                        .foregroundStyle(Theme.onSurface)
                    Text("Here's what each step costs. Tap once, we won't ask again.")
                        .font(.footnote).foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center).padding(.horizontal, 24)
                }

                section("To make 3 pictures") {
                    row("Smart prompt", "Turns your idea into something paintable.",
                        viewModel.pricing?.chat)
                    row("Picture 1", nil, viewModel.pricing?.microPixLyra)
                    row("Picture 2", nil, viewModel.pricing?.microPixVega)
                    row("Picture 3", nil, viewModel.pricing?.nanoPixLuna)
                }

                section("To make a video") {
                    row("Prep picture", nil, viewModel.pricing?.image)
                    row("Make video", nil, viewModel.pricing?.nanoRenSpica)
                }

                section("To load files you see and hear") {
                    bandwidthRow
                    Text("Loading isn't free for us. We're a solo team, so we pass it on — \(viewModel.bandwidthMinPerFile) credit minimum per file. Bigger companies absorb it. We can't, yet.")
                        .font(.caption).foregroundStyle(Theme.muted)
                        .padding(.top, 4)
                }

                HStack(spacing: 12) {
                    Button("Not now", action: viewModel.declineConsent)
                        .buttonStyle(.glass)
                    Button("Agree & start", action: viewModel.confirmConsent)
                        .buttonStyle(AccentButtonStyle(fullWidth: false))
                }
                .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 24)
            }
        }
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadii: .init(topLeading: 28, topTrailing: 28)))
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.muted)
            content()
        }
        .padding(16)
        .background(Color.white.opacity(0.04), in: .rect(cornerRadius: 18))
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func row(_ title: String, _ subtitle: String?, _ cost: Int64?) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.onSurface)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(Theme.muted)
                }
            }
            Spacer()
            Text("\(cost ?? 0)").font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.onSurface).monospacedDigit()
        }
    }

    @ViewBuilder
    private var bandwidthRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Per file").font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.onSurface)
                Text("Audio, pictures, videos. \(viewModel.pricing?.gb ?? 100) per GB.")
                    .font(.caption).foregroundStyle(Theme.muted)
            }
            Spacer()
            Text("≥\(viewModel.bandwidthMinPerFile)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.onSurface).monospacedDigit()
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

// MARK: - Completion

private struct CompletionView: View {
    let onDone: () -> Void
    @State private var pulse = false
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accentMagenta.opacity(pulse ? 0.5 : 0.2))
                    .frame(width: pulse ? 260 : 200, height: pulse ? 260 : 200)
                    .blur(radius: 30)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 96, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            VStack(spacing: 12) {
                Text("You did it.").font(.largeTitle.bold())
                    .foregroundStyle(Theme.onSurface)
                Text("That's a video. Make more whenever you want.")
                    .font(.body).foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(AccentButtonStyle())
                .padding(.horizontal, 24).padding(.bottom, 48)
        }
        .background(Theme.background.ignoresSafeArea())
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
