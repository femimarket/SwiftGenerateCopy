# DemoGenerate — the whole journey, without the backend

## The mission

The Generate journey — *picture arrives, pick the one you love, remake it, save it, make a video* — is the moment that makes this app what it is. It has to be experienceable before there's a backend at all: in onboarding tutorials, in app review builds, in marketing demos, on a phone with no network. The picture has to land. The video has to play. The pleasure of "I made this" has to be real, even when the bytes were already on the device the whole time.

## The goal

Every visible beat of the production Generate journey plays in the demo path. Pictures arrive in a grid. The user taps to remake one. New pictures arrive. They tap a heart. They tap Make Video. A video appears. The shimmer settles. They watch it. The grid is sectioned by lyric line once lyrics are pasted. The cost breakdown shows numbers that match the real pricing. The credit chip ticks down. None of it touches the network.

## The vision

The demo is not a stripped-down preview. It is not a video walkthrough. It is not a static gallery with placeholder labels. It is the production journey, running through the production view code, with one seam: the service that calls the model backend is replaced with one that hands back bundled assets after the same dwell the real generation would have taken. The user's experience of *making* is identical — the only thing they don't get is the byte-level surprise of a new image. Everything else, including the wait, is real.

## What this is not

It is not a marketing render. It is not "demo mode" stamped over the UI. It is not a separate set of screens with watered-down behaviour. It is not a static slideshow. It is the same ContentView, the same view model, the same animations, the same toolbar, the same coach marks — bound to a different service.

---

## Tech

The Generate journey is a single view hierarchy backed by a single view model that talks to a **single service contract** for everything that crosses the network: credit, pricing, projects, image generation across each model, image registration, audio trim, video generation, and balance refreshes. The view doesn't care which implementation it's bound to.

Two conforming implementations exist: a real one that calls the production API for each contract method, and a demo one that returns **bundled assets after a dwell that matches the real generation timing**. Image generations return PNG filenames that exist in the demo bundle. Video generations return an MP4 filename that exists in the demo bundle. Credit and pricing return canned values that match the production payment surface so the cost breakdown reads honestly. Submitted-poll-done cycles become time-based fakes whose durations match what the real backend takes — the user waits for the same beats, sees the same shimmer, gets the same satisfaction at the end.

The bundled assets used by the demo path **are the same assets** the production build already ships (the loose PNGs that drive the song-pick strips), so no demo-specific asset directory accumulates. The video asset is a single short MP4 bundled in the demo build alone.

The seam between demo and real lives behind the service contract. Below it: nothing in the view code, the view model, the grid sectioning, the make-video selector, the cost breakdown sheet, the topup sheet, or the dev-seed code paths cares which side is running. The journey is one journey; the byte path differs.

### Swift

This project is written in Swift on Apple platforms. The agnostic terms above map to:

- **Single view hierarchy** → `ContentView` plus its child views in `ContentView.swift`. One source of truth for layout, phase machine, grid sectioning, toolbar, animations.
- **Single view model** → `GenerateViewModel` (`@Observable`), unchanged across demo and real. Owns `phase`, `images`, `videos`, `project`, `audiolines`, `pricing`, `credit`, `pendingImages`, `pendingVideos`, `pendingGenerations`.
- **Service contract** → a Swift `protocol GenerateService` exposing the method set the view model currently calls on the existing `private struct GenerateService` — `currentCredit`, `currentPricing`, `allProjects`, `generateLyra`, `generateVega`, `generateLuna`, `generateSpica`, `registerImageForVideo`, `trimAndUploadAudioClip`, `generateVideo`, etc.
- **Real implementation** → `RealGenerateService` containing the current `GenerateService` body verbatim — multipart uploads, `ApiAPIConfiguration`, polling loops, `Media.url` for download bridges.
- **Demo implementation** → `DemoGenerateService` whose every method `try await Task.sleep(for:)` matching the production p50 of that call (image gen ~6s, video gen ~60s, credit fetch ~150ms), then returns a value pointing at a bundled asset. Pricing returns a canned `Pricing` whose values mirror production's published rates.
- **Host-injected selection** → `GenerateViewModel` initialized with a service instance; the real `Generate` target injects `RealGenerateService()`, a demo / tutorial / app-review build injects `DemoGenerateService()`.
- **Asset reuse** → the demo image returns cycle through the bundled PNGs already shipping in the Generate target (`img1.png`...`img4.png`, the `019e7f3d-*` triplet, `90.png`, `91.png`, `93.png`). No demo-only asset directory.
- **Video asset** → a single short bundled MP4 returned by `DemoGenerateService.generateVideo`. Audio conditioning is skipped in the demo path; the video plays its own track.
- **Audio bridge for demo** → `DemoGenerateService.trimAndUploadAudioClip` skips the `AVAssetExportSession` trim and returns the original audio filename unchanged. Real path keeps the trim.
- **Dev-seed compatibility** → `devSeed()` in `GenerateViewModel` continues to populate `project`, `images`, `phase = .grid`, `hasGivenConsent = true` regardless of which service is injected — it pre-seeds local state, not network state.
- **Credit gating in demo** → `gateOnCredit(cost:retry:)` and the topup sheet still fire so the user experiences the credit-cost moment. Demo `currentCredit` returns a balance that's enough for one full generation cycle, then drops; the topup sheet's purchase flow short-circuits to "completed" without StoreKit if running in demo.
