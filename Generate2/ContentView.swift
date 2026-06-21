//
//  ContentView.swift
//  Generate
//
//  Single-file flagship Generate screen.
//  Grid → derive → like → compose video → done.
//

import SwiftUI
import AVKit
import AVFoundation
import PhotosUI
import Observation
import FoundationModels
import Api
import UIKit
import ProjectService
import ImageIO
import UniformTypeIdentifiers


// MARK: - App root

/// Root view of the Generate2 library. Shows the grid + chrome.
/// Generate2 does not own a NavigationStack and emits no internal routes.
public struct ContentView: View {
    /// Parent app's topup handler. Awaited by the credit gate when balance
    /// runs dry — parent shows its purchase UI, resolves true on success.
    let onTopupNeeded: () async -> Bool
    /// Fired when the user taps the song-title slot in the toolbar. Parent
    /// presents its own song picker; returns `(audio bytes, suggested
    /// filename)` on success or `nil` on cancel. Generate2 writes the bytes
    /// to disk and uses the filename as the toolbar display title.
    let onUploadSong: () async -> Void
    /// Display label for an extra entry the parent wants in the "+" menu.
    let menuItemName1: String
    /// SF Symbol name for the extra menu entry's icon.
    let menuItemIcon1: String
    /// Fired when the user taps the extra menu entry. Parent owns whatever
    /// happens next (typically navigation away).
    let onMenuItemTapped1: () -> Void

    /// Pass `idToken` to override the auto-IDFV bearer (e.g. simulator runs,
    /// dev tokens). When nil, falls back to `UIDevice.current.identifierForVendor`.
    public init(
        onTopupNeeded: @escaping () async -> Bool,
        onUploadSong: @escaping () async -> Void,
        menuItemName1: String,
        menuItemIcon1: String,
        onMenuItemTapped1: @escaping () -> Void,
        idToken: String? = nil
    ) {
        self.onTopupNeeded = onTopupNeeded
        self.onUploadSong = onUploadSong
        self.menuItemName1 = menuItemName1
        self.menuItemIcon1 = menuItemIcon1
        self.onMenuItemTapped1 = onMenuItemTapped1
         Self.installBearer(idToken)
    }

    /// Bearer token. When `override` is nil, uses IDFV
    /// (`UIDevice.current.identifierForVendor`) — stable per app+vendor+device.
    /// Override when running on simulator or with a pinned dev token.
     private static func installBearer(_ override: String?) {
         let tokenid: String
         if let override {
             tokenid = override
         } else {
             guard let idfv = UIDevice.current.identifierForVendor?.uuidString else {
                 preconditionFailure("identifierForVendor returned nil")
             }
             tokenid = idfv
         }
         UserDefaults.standard.set(tokenid, forKey: "idToken")
         ApiAPIConfiguration.shared.customHeaders["Authorization"] = "Bearer \(tokenid)"
     }

    public var body: some View {
        Generate(
            onTopupNeeded: onTopupNeeded,
            onUploadSong: onUploadSong,
            menuItemName1: menuItemName1,
            menuItemIcon1: menuItemIcon1,
            onMenuItemTapped1: onMenuItemTapped1
        )
    }
}

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

// FemiGeneratedImage removed. The on-disk file IS the source of truth:
//   prompt + model live in xmp (ProjectService.getPrompt / .getModel),
//   like state lives in xmp:Rating (ProjectService.getLike),
//   lineIndex is presumed to live in xmp too (ProjectService.getLineIndex
//   when the accessor exists; until then, a sidecar dict on the view model).
// Grid item type is now `String` (server filename).

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
    let sourceImageIds: [String]
}

/// A video that's being generated in the background. The grid renders this as a
/// shimmer cell so the user can keep doing other things while it cooks.
struct FemiPendingVideo: Identifiable, Hashable, Sendable {
    enum State: Hashable, Sendable { case working, failed }
    let id: UUID
    let sourceImageIds: [String]
    let posterFile: String
    var state: State = .working
}

/// Drag payload for moving an image between lyric line sections. The
/// `Transferable` conformance + Codable encoding means external (e.g. Photos)
/// drags don't decode to this type and are silently rejected by the drop
/// destination's type filter.
struct DraggedImage: Codable, Transferable {
    let filename: String
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
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


// MARK: - Like store (client-only, UserDefaults)

@MainActor @Observable
final class FemiLikeStore {
    /// In-memory likes — image keys are filenames; video keys are UUID
    /// strings (sessions only — videos don't persist yet).
    var liked: Set<String> = []
     func isLiked(_ key: String) -> Bool { liked.contains(key) }
     func toggle(_ key: String) {
         if liked.contains(key) { liked.remove(key) }
         else { liked.insert(key) }
     }
     func setLiked(_ key: String, _ value: Bool) {
         if value { liked.insert(key) }
         else { liked.remove(key) }
     }
}

// MARK: - View model

@MainActor @Observable
final class FemiGenerateViewModel {

    enum GenerationKind: Hashable { case initial, derived, video }

    enum Phase: Hashable {
        case generating(GenerationKind)
        case grid
        case complete
    }

    enum GridFilter: Hashable, CaseIterable {
        case all, liked, videos
        var label: String {
            switch self { case .all: "All"; case .liked: "Liked"; case .videos: "Videos" }
        }
    }

    var phase: Phase = .grid
    var filter: GridFilter = .all

    // In-grid Photos-style select-for-video mode.
    var isSelectingForVideo: Bool = false
    /// Selection by filename. Used by the in-grid "select for video" mode.
    var selectedImageIds: [String] = []

    // Video detail playback (with sound).
    var viewingVideo: FemiGeneratedVideo? = nil

    var images: [String] = []
    /// Sidecar dict for line-index. Filename → audiolines.index. Will move
    /// into xmp once ProjectService exposes a getLineIndex / setLineIndex.
    var imageLineIndex: [String: Int] = [:]
    /// Sidecar dict for video line-index. Filename → audiolines.index. Populated
    /// from xmp:Subject on disk rehydration and at video-creation time.
    var videoLineIndex: [String: Int] = [:]
    var videos: [FemiGeneratedVideo] = []
    var pendingVideos: [FemiPendingVideo] = []
    var pendingImages: [FemiPendingImage] = []
    var pendingGenerations: [FemiPendingGeneration] = []

    var errorMessage: String?

    /// Parent-supplied async topup handler. Set by `Generate` on appear from
    /// the `onTopupNeeded` arg threaded down from `ContentView`. The gate
    /// awaits this when credits run dry — parent shows its own sheet, resolves
    /// the closure when its purchase flow completes (success or cancel).
    var onTopupNeeded: (() async -> Bool)?

    /// Pasted lyrics text. Nil until the user pastes via the scene-player
    /// affordance. Once set, the grid switches from flat to sectioned-by-line.
    var lyrics: String?
    /// Timed lyric lines. Populated by `pasteLyrics`. Nil before paste.
    var audiolines: [FemiSongLine]?

    let likeStore = FemiLikeStore()

    init() {
         // if devSeedEnabled { devSeed() }
    }



    // Derived

    var filteredImages: [String] {
        switch filter {
        case .all, .videos: images
        case .liked: images.filter { likeStore.isLiked($0) }
        }
    }
    var likedImages: [String] { images.filter { likeStore.isLiked($0) } }
//
    // generationCost / videoCost removed — cost is server-side, surfaced as 402.

    /// Off-main SYLT read via AudioMarker. No-op when the audio has no
    /// embedded lyrics.
     fileprivate func extractAudiolines(filename: String) {
         let url = ProjectService.getUrl(for: filename)
         Task.detached { [weak self] in
             let lines = LyricExtractor.read(audioURL: url)
             guard !lines.isEmpty, let self else { return }
             await MainActor.run {
                 withAnimation(.spring(duration: 0.5)) {
                     self.audiolines = lines
                     var nextLine = 0
                     for i in self.images.indices where self.imageLineIndex[self.images[i]] == nil {
                         self.imageLineIndex[self.images[i]] = lines[nextLine % lines.count].index
                         nextLine += 1
                     }
                 }
             }
         }
     }

    // MARK: - User-triggered generations

     /// Build the 3-model fan-out of text-to-image APIs for a given prompt.
     /// Each `API` wraps a distinct model action; the server returns the same
     /// shape with `file` populated by the result base64 / filename.
     fileprivate static func textToImageAPIs(prompt: String) -> [API] {
         let actions: [ApiAction] = [
             .typeFlux2Pro(Flux2Pro(falRequestId: "", file: "", prompt: prompt, type: .flux2Pro)),
             .typeNanoBanana2(NanoBanana2(falRequestId: "", file: "", prompt: prompt, type: .nanoBanana2)),
             .typeZImageTurbo(ZImageTurbo(falRequestId: "", file: "", prompt: prompt, type: .zimageturbo)),
         ]
         return actions.map { Self.wrap($0) }
     }

     fileprivate static func wrap(_ action: ApiAction) -> API {
         API(action: action, credit: 0, id: UUID(), status: .pending, userId: "")
     }

     /// Extract the result `file` from the server's response action.
     fileprivate static func resultFile(of api: API) -> String {
         switch api.action {
         case .typeFlux2Pro(let f): return f.file
         case .typeNanoBanana2(let f): return f.file
         case .typeZImageTurbo(let f): return f.file
         case .typeLtx23A2V(let f): return f.file
         default: preconditionFailure("resultFile: response action has no file field — \(api.action)")
         }
     }

     /// Name of the model that produced the response — written to xmp:Model.
     fileprivate static func resultModel(of api: API) -> String {
         switch api.action {
         case .typeFlux2Pro: return "Flux2Pro"
         case .typeNanoBanana2: return "NanoBanana2"
         case .typeZImageTurbo: return "ZImageTurbo"
         case .typeLtx23A2V: return "Ltx23A2V"
         default: preconditionFailure("resultModel: unexpected response action — \(api.action)")
         }
     }

    var canMakeVideo: Bool { !likedImages.isEmpty }

    /// Fire-and-forget. Adds a FemiPendingVideo immediately, kicks off the long generation
    /// in a background Task, mutates `videos` when it completes. The grid stays
    /// interactive the entire time — user can derive, like, browse, even queue more
    /// videos while the first is cooking.
    // Credit / topup gate

    /// Minimum wallet balance required before generate/video; at or below → topup.

    /// Pre-flight credit check. Called on every user action (generate /
    /// Decode the base64 returned by the API and persist to the project folder
    /// under a fresh local filename. `ext` is sniffed from the bytes via ImageIO
    /// when not supplied (video callers pass `"mp4"` since ImageIO doesn't
    /// cover video). Returns the new filename for grid wiring.
    fileprivate static func saveBase64(_ b64: String, ext: String? = nil, prompt: String? = nil, model: String? = nil, subject: [String]? = nil) -> String {
        let data = Data(base64Encoded: b64)!
        let finalExt: String
        if let ext {
            finalExt = ext
        } else {
            guard let src = CGImageSourceCreateWithData(data as CFData, nil),
                  let uti = CGImageSourceGetType(src) as? String,
                  let sniffed = UTType(uti)?.preferredFilenameExtension
            else { preconditionFailure("saveBase64: response bytes aren't a recognized image format") }
            finalExt = sniffed
        }
        let name = "gen-\(UUID().uuidString).\(finalExt)"
        ProjectService.saveFile(data, named: name, prompt: prompt, model: model, subject: subject)
        return name
    }

    /// Read a project file from disk and return its raw base64 — the API
    /// contract for `image` / `audio` fields.
    fileprivate static func base64(of file: String) -> String {
        let url = ProjectService.getUrl(for: file)
        return (try! Data(contentsOf: url)).base64EncodedString()
    }

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
            }
        }
        .task {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
            let asset = AVURLAsset(url: ProjectService.getUrl(for: video.file))
            let item = AVPlayerItem(asset: asset)
            let p = AVPlayer(playerItem: item)
            p.isMuted = false
            self.player = p
            p.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
            try? AVAudioSession.sharedInstance().setCategory(
                .ambient, mode: .default, options: [.mixWithOthers]
            )
        }
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

// MARK: - ContentView

struct Generate: View {
    /// Parent app's topup handler — installed on the view model on appear so
    /// `gateOnCredit` can await it when credits run dry.
    let onTopupNeeded: () async -> Bool
    /// Fired when the user taps the song-title slot. Returns (bytes,
    /// suggested filename) on pick, nil on cancel.
    let onUploadSong: () async -> Void
    /// Display label for the parent-supplied "+" menu entry.
    let menuItemName1: String
    /// SF Symbol name for the parent-supplied menu entry.
    let menuItemIcon1: String
    /// Fired when the user taps the parent-supplied menu entry.
    let onMenuItemTapped1: () -> Void
    @State private var viewModel = FemiGenerateViewModel()
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false
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
        .environment(viewModel)
        .preferredColorScheme(.dark)
        .task {
            viewModel.onTopupNeeded = onTopupNeeded
            let existingImages = Set(viewModel.images)
            let existingVideos = Set(viewModel.videos.map(\.file))
            for url in ProjectService.getAllGenerations() {
                let filename = url.lastPathComponent
                let ext = url.pathExtension.lowercased()
                switch ext {
                case "png", "jpg", "jpeg", "webp", "gif", "heic", "heif":
                    if !existingImages.contains(filename) {
                        viewModel.images.append(filename)
                        if let subject = ProjectService.getSubject(filename),
                           let idx = subject.compactMap(Int.init).first {
                            viewModel.imageLineIndex[filename] = idx
                        }
                    }
                case "mp4":
                    if !existingVideos.contains(filename) {
                        viewModel.videos.append(FemiGeneratedVideo(
                            id: UUID(), file: filename, posterFile: "", sourceImageIds: []
                        ))
                        if let subject = ProjectService.getSubject(filename),
                           let idx = subject.compactMap(Int.init).first {
                            viewModel.videoLineIndex[filename] = idx
                        }
                    }
                default: break
                }
            }
            for image in viewModel.images where ProjectService.getLike(image) {
                viewModel.likeStore.setLiked(image, true)
            }
            if let song = ProjectService.getAudio()?.lastPathComponent {
                viewModel.extractAudiolines(filename: song)
            }
        }
        .photosPicker(isPresented: $showingPhotoPicker,
                      selection: $photoPickerItem,
                      matching: .images)
        // Photo picker bridge: user picks → load Data → hand off to view model.
        .onChange(of: photoPickerItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    let name = "upload-\(UUID().uuidString).jpg"
                    ProjectService.saveFile(data, named: name, prompt: nil, model: nil, subject: nil)
                    withAnimation(.spring(duration: 0.4)) {
                        viewModel.images.append(name)
                    }
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
        case .generating(let kind):
            GeneratingOverlay(kind: kind)
        case .grid:
            gridLayer
        case .complete:
            CompletionView(onDone: { viewModel.phase = .grid })
        }
    }

    private var gridLayer: some View {
        GridView(viewModel: viewModel)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if viewModel.isSelectingForVideo {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.isSelectingForVideo = false
                        viewModel.selectedImageIds = []
                    }
                }
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
                            Task {
                                let pendings = (0..<3).map { _ in
                                    FemiPendingGeneration(id: UUID(), lineIndex: nil)
                                }
                                var queue = pendings.map(\.id)
                                withAnimation(.spring(duration: 0.4)) {
                                    viewModel.pendingGenerations.append(contentsOf: pendings)
                                    viewModel.phase = .grid
                                }
                                let prompt = "cinematic music video still, vivid color grade, dramatic lighting, expressive performer mid-motion, shallow depth of field, 35mm film grain, emotional and atmospheric"
                                var topupNeeded = false
                                await withTaskGroup(of: Result<API, Error>.self) { group in
                                    for api in FemiGenerateViewModel.textToImageAPIs(prompt: prompt) {
                                        group.addTask {
                                            do { return .success(try await ApiHandlerAPI.apiHandler(API: api)) }
                                            catch { return .failure(error) }
                                        }
                                    }
                                    for await result in group {
                                        switch result {
                                        case .success(let row):
                                            let file = FemiGenerateViewModel.saveBase64(FemiGenerateViewModel.resultFile(of: row), model: FemiGenerateViewModel.resultModel(of: row))
                                            guard !queue.isEmpty else { continue }
                                            let pid = queue.removeFirst()
                                            withAnimation(.spring(duration: 0.35)) {
                                                viewModel.pendingGenerations.removeAll { $0.id == pid }
                                                viewModel.images.append(file)
                                            }
                                        case .failure(let error):
                                            if case ErrorResponse.error(402, _, _, _) = error {
                                                topupNeeded = true
                                            } else {
                                                print("← generate FAIL: \(error)")
                                            }
                                        }
                                    }
                                }
                                if topupNeeded { _ = await viewModel.onTopupNeeded?() }
                                for pid in queue {
                                    if let i = viewModel.pendingGenerations.firstIndex(where: { $0.id == pid }) {
                                        viewModel.pendingGenerations[i].state = .failed
                                    }
                                }
                            }
                        } label: {
                            Label("Generate", systemImage: "sparkles")
                        }
                        Button {
                            showingPhotoPicker = true
                        } label: {
                            Label("Upload from Photos", systemImage: "photo")
                        }
                        Button {
                            onMenuItemTapped1()
                        } label: {
                            Label(menuItemName1, systemImage: menuItemIcon1)
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(FemiTheme.onSurface)
                    }
                }
            }
            // Title tap → parent's song picker (common, discoverable).
            // Title long-press → parent's project picker (rare, hidden moat).
            ToolbarItem(placement: .principal) {
                Button {
                    Task {
                        await onUploadSong()
                        viewModel.lyrics = nil
                        viewModel.audiolines = nil
                        if let file = ProjectService.getAudio()?.lastPathComponent {
                            viewModel.extractAudiolines(filename: file)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if let song = ProjectService.getAudio()?.lastPathComponent {
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
            }
            ToolbarItem(placement: .topBarTrailing) {
                if shouldShowMakeVideoButton {
                    Button {
                        guard viewModel.canMakeVideo else { return }
                        viewModel.selectedImageIds = []
                        withAnimation(.spring(duration: 0.3)) { viewModel.isSelectingForVideo = true }
                    } label: {
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

    /// Only show Make Video in the toolbar when the user is on the grid (not derive, etc.).
    private var shouldShowMakeVideoButton: Bool {
        if case .grid = viewModel.phase { return true }
        return false
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
 func femiHeartButton(isLiked: Bool, action: @escaping @MainActor () -> Void) -> some View {
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

/// Commit shelf while picking pictures for a video (Photos pattern).
private struct FemiMakeVideoShelf: View {
    @Bindable var viewModel: FemiGenerateViewModel

    var body: some View {
        Button("Make video") {
            Task {
                let ids = viewModel.selectedImageIds
                let firstId = ids.first!
                let primary = viewModel.images.first(where: { $0 == firstId })!
                viewModel.isSelectingForVideo = false
                viewModel.selectedImageIds = []
                let pending = FemiPendingVideo(
                    id: UUID(), sourceImageIds: ids, posterFile: primary
                )
                withAnimation(.spring(duration: 0.3)) {
                    viewModel.pendingVideos.append(pending)
                }
                let audioFile = ProjectService.getAudio()!.lastPathComponent
                let imagePrompts = ids.compactMap { ProjectService.getPrompt($0) }
                let imageB64 = FemiGenerateViewModel.base64(of: primary)
                let lineRange: (start: Int, duration: Int)? = {
                    guard let lineIndex = viewModel.imageLineIndex[primary],
                          let line = viewModel.audiolines?.first(where: { $0.index == lineIndex })
                    else { return nil }
                    return (line.startMs, 10_000)
                }()
                let audioB64: String
                if let lineRange {
                    let inURL = ProjectService.getUrl(for: audioFile)
                    let outURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent("\(UUID().uuidString).m4a")
                    let asset = AVURLAsset(url: inURL)
                    let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)!
                    exporter.outputURL = outURL
                    exporter.outputFileType = .m4a
                    exporter.timeRange = CMTimeRange(
                        start: CMTime(value: Int64(lineRange.start), timescale: 1000),
                        duration: CMTime(value: Int64(lineRange.duration), timescale: 1000)
                    )
                    try! await exporter.export(to: outURL, as: .m4a)
                    defer { try? FileManager.default.removeItem(at: outURL) }
                    audioB64 = try! Data(contentsOf: outURL).base64EncodedString()
                } else {
                    audioB64 = FemiGenerateViewModel.base64(of: audioFile)
                }
                let instruction = "Convert these \(imagePrompts.count) image prompts into a timestamped music-video prompt with exactly \(imagePrompts.count) multishot timestamps. Under 100 words. Return only the prompt itself — no title, no preamble, no commentary, no trailing notes, no markdown.\n\n\(imagePrompts.joined(separator: "\n---\n"))"
                let prompt: String
                do {
                    let claudeRow = try await ApiHandlerAPI.apiHandler(API: FemiGenerateViewModel.wrap(.typeClaudeSonnet46(ClaudeSonnet46(
                        messages: [ApiChatMessage(content: instruction, role: .user)],
                        type: .claudesonnet46
                    ))))
                    guard case .typeClaudeSonnet46(let claudeAction) = claudeRow.action,
                          let reply = claudeAction.messages.last?.content
                    else {
                        print("← claude FAIL: unexpected action shape \(claudeRow.action)")
                        if let idx = viewModel.pendingVideos.firstIndex(where: { $0.id == pending.id }) {
                            viewModel.pendingVideos[idx].state = .failed
                        }
                        return
                    }
                    prompt = reply
                } catch ErrorResponse.error(402, _, _, _) {
                    print("← claude FAIL: 402 payment required")
                    if let idx = viewModel.pendingVideos.firstIndex(where: { $0.id == pending.id }) {
                        viewModel.pendingVideos[idx].state = .failed
                    }
                    _ = await viewModel.onTopupNeeded?()
                    return
                } catch {
                    print("← claude FAIL: \(error)")
                    if let idx = viewModel.pendingVideos.firstIndex(where: { $0.id == pending.id }) {
                        viewModel.pendingVideos[idx].state = .failed
                    }
                    return
                }
                do {
                    let row = try await ApiHandlerAPI.apiHandler(API: FemiGenerateViewModel.wrap(.typeLtx23A2V(Ltx23A2V(
                        audio: audioB64, comfyRequestId: "", file: "", image: imageB64,
                        prompt: prompt, type: .ltx23a2v
                    ))))
                    let lineSubject: [String]? = {
                        guard let idx = viewModel.imageLineIndex[primary],
                              let text = viewModel.audiolines?.first(where: { $0.index == idx })?.text
                        else { return nil }
                        return ["\(idx)", text]
                    }()
                    let file = FemiGenerateViewModel.saveBase64(
                        FemiGenerateViewModel.resultFile(of: row), ext: "mp4",
                        prompt: prompt, model: FemiGenerateViewModel.resultModel(of: row), subject: lineSubject
                    )
                    withAnimation(.spring(duration: 0.4)) {
                        viewModel.pendingVideos.removeAll { $0.id == pending.id }
                        viewModel.videos.append(FemiGeneratedVideo(
                            id: UUID(), file: file, posterFile: primary, sourceImageIds: ids
                        ))
                        if let idx = viewModel.imageLineIndex[primary] {
                            viewModel.videoLineIndex[file] = idx
                        }
                    }
                } catch ErrorResponse.error(402, _, _, _) {
                    print("← video FAIL: 402 payment required")
                    if let idx = viewModel.pendingVideos.firstIndex(where: { $0.id == pending.id }) {
                        viewModel.pendingVideos[idx].state = .failed
                    }
                    _ = await viewModel.onTopupNeeded?()
                } catch {
                    print("← video FAIL: \(error)")
                    if let idx = viewModel.pendingVideos.firstIndex(where: { $0.id == pending.id }) {
                        viewModel.pendingVideos[idx].state = .failed
                    }
                }
            }
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
        case .liked: return viewModel.videos.filter { viewModel.likeStore.isLiked($0.id.uuidString) }
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
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        if !visibleFemiPendingImages.isEmpty || !visibleFemiPendingVideos.isEmpty {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(visibleFemiPendingImages) { PendingImageCell(pending: $0, viewModel: viewModel) }
                                ForEach(visibleFemiPendingVideos) { PendingVideoCell(pending: $0, viewModel: viewModel) }
                            }
                            .padding(.horizontal, 2)
                            .padding(.top, 6)
                        }
                        ForEach(audiolines) { line in
                            let imagesForLine = viewModel.filteredImages.filter { viewModel.imageLineIndex[$0] == line.index }
                            let pendingsForLine = visibleFemiPendingGenerations.filter { $0.lineIndex == line.index }
                            let videosForLine = visibleVideos.filter { viewModel.videoLineIndex[$0.file] == line.index }
                            let count = imagesForLine.count + pendingsForLine.count + videosForLine.count
                            Section {
                                if !pendingsForLine.isEmpty || !imagesForLine.isEmpty || !videosForLine.isEmpty {
                                    LazyVGrid(columns: columns, spacing: 2) {
                                        ForEach(pendingsForLine) { PendingGenerationCell(pending: $0, viewModel: viewModel) }
                                        ForEach(imagesForLine, id: \.self) { FemiImageCell(image: $0, viewModel: viewModel) }
                                        ForEach(videosForLine) { VideoCell(video: $0, viewModel: viewModel) }
                                    }
                                    .padding(.horizontal, 2)
                                    .padding(.top, 4)
                                    .dropDestination(for: DraggedImage.self) { items, _ in
                                        withAnimation(.spring(duration: 0.25)) {
                                            for item in items {
                                                viewModel.imageLineIndex[item.filename] = line.index
                                                if let data = try? Data(contentsOf: ProjectService.getUrl(for: item.filename)) {
                                                    ProjectService.saveFile(
                                                        data,
                                                        named: item.filename,
                                                        prompt: ProjectService.getPrompt(item.filename),
                                                        model: ProjectService.getModel(item.filename),
                                                        subject: ["\(line.index)", line.text]
                                                    )
                                                }
                                            }
                                        }
                                        return !items.isEmpty
                                    }
                                }
                            } header: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(line.text)
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(FemiTheme.onSurface)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    Text(count == 0 ? "No pictures yet"
                                                    : "\(count) \(count == 1 ? "picture" : "pictures")")
                                        .font(.subheadline)
                                        .foregroundStyle(FemiTheme.muted)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.top, 28)
                                .padding(.bottom, 10)
                                .background(FemiTheme.background)
                                .dropDestination(for: DraggedImage.self) { items, _ in
                                    withAnimation(.spring(duration: 0.25)) {
                                        for item in items {
                                            viewModel.imageLineIndex[item.filename] = line.index
                                            if let data = try? Data(contentsOf: ProjectService.getUrl(for: item.filename)) {
                                                ProjectService.saveFile(
                                                    data,
                                                    named: item.filename,
                                                    prompt: ProjectService.getPrompt(item.filename),
                                                    model: ProjectService.getModel(item.filename),
                                                    subject: ["\(line.index)", line.text]
                                                )
                                            }
                                        }
                                    }
                                    return !items.isEmpty
                                }
                                .contextMenu {
                                    Button {
                                        Task {
                                            let lineIndex = line.index
                                            guard let lyricLine = viewModel.audiolines?.first(where: { $0.index == lineIndex }) else { return }
                                            let prompt = lyricLine.text
                                            let pendings = (0..<3).map { _ in
                                                FemiPendingGeneration(id: UUID(), lineIndex: lineIndex)
                                            }
                                            var queue = pendings.map(\.id)
                                            withAnimation(.spring(duration: 0.3)) {
                                                viewModel.pendingGenerations.append(contentsOf: pendings)
                                            }
                                            var topupNeeded = false
                                            await withTaskGroup(of: Result<API, Error>.self) { group in
                                                for api in FemiGenerateViewModel.textToImageAPIs(prompt: prompt) {
                                                    group.addTask {
                                                        do { return .success(try await ApiHandlerAPI.apiHandler(API: api)) }
                                                        catch { return .failure(error) }
                                                    }
                                                }
                                                for await result in group {
                                                    switch result {
                                                    case .success(let row):
                                                        let file = FemiGenerateViewModel.saveBase64(FemiGenerateViewModel.resultFile(of: row), prompt: prompt, model: FemiGenerateViewModel.resultModel(of: row), subject: ["line:\(lineIndex)"])
                                                        guard !queue.isEmpty else { continue }
                                                        let pid = queue.removeFirst()
                                                        withAnimation(.spring(duration: 0.35)) {
                                                            viewModel.pendingGenerations.removeAll { $0.id == pid }
                                                            viewModel.images.append(file)
                                                            viewModel.imageLineIndex[file] = lineIndex
                                                        }
                                                    case .failure(let error):
                                                        if case ErrorResponse.error(402, _, _, _) = error {
                                                            topupNeeded = true
                                                        } else {
                                                            print("← fillLine FAIL: \(error)")
                                                        }
                                                    }
                                                }
                                            }
                                            if topupNeeded { _ = await viewModel.onTopupNeeded?() }
                                            for pid in queue {
                                                if let i = viewModel.pendingGenerations.firstIndex(where: { $0.id == pid }) {
                                                    viewModel.pendingGenerations[i].state = .failed
                                                }
                                            }
                                        }
                                    } label: {
                                        Label("Make pictures for this line", systemImage: "sparkles")
                                    }
                                }
                                .accessibilityLabel(line.text)
                            }
                        }
                        let orphanVideos = visibleVideos.filter { viewModel.videoLineIndex[$0.file] == nil }
                        if !orphanVideos.isEmpty {
                            LazyVGrid(columns: columns, spacing: 2) {
                                ForEach(orphanVideos) { VideoCell(video: $0, viewModel: viewModel) }
                            }
                            .padding(.horizontal, 2)
                            .padding(.top, 12)
                        }
                    }
                }
                .contentMargins(.bottom, bottomChromeMargin, for: .scrollContent)
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
                    ForEach(visibleFemiPendingImages) { PendingImageCell(pending: $0, viewModel: viewModel) }
                    ForEach(visibleFemiPendingGenerations) { PendingGenerationCell(pending: $0, viewModel: viewModel) }
                    ForEach(viewModel.filteredImages, id: \.self) { FemiImageCell(image: $0, viewModel: viewModel) }
                }
                ForEach(visibleFemiPendingVideos) { PendingVideoCell(pending: $0, viewModel: viewModel) }
                ForEach(visibleVideos) { VideoCell(video: $0, viewModel: viewModel) }
            }
            .padding(.horizontal, 2)
            .padding(.top, 6)
        }
        .contentMargins(.bottom, bottomChromeMargin, for: .scrollContent)
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


