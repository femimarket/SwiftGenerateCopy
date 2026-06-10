# DemoUploadSong — the upload moment, without the upload

## The mission

The song-pick moment is where the user first feels the app is theirs. The vinyl. The strips. The hush as a song they love lands in the centerpiece. That moment has to *exist* before there's a backend to ship to, before app review will let a stranger tap upload, before a tutorial-runner has any business committing bytes to a server. DemoUploadSong is the same moment, the same screen, the same hush — minus the part the user never sees.

## The goal

Indistinguishable from the real flow in every frame the user actually experiences. Same vinyl, same strips, same upload progress, same preview with the song looping under their finger, same "Use this song" button. The only thing different is what doesn't happen behind the curtain — no bytes leave the device.

## The vision

A demo isn't a sketch. It isn't a static screenshot. It isn't a video walkthrough with arrows. It's the real screen, with the real gestures, returning a real-looking handoff. The user's experience of *picked a song, song is mine, song loops, ready to make a video* is identical to production — because the production screen IS the demo screen, with the network call swapped for an animation-shaped pause.

## What this is not

It is not a watered-down preview. It is not a placeholder UI. It is not a marketing render. It is not a separate visual identity. It is the production view, running in production-quality, with a single seam: the upload work that lives outside the user's field of vision is faked.

---

## Tech

The song-pick screen is a single view hierarchy. Whether it ships as the real path or the demo path is determined by **which service it talks to**, not by which view code it runs. The view doesn't know the difference.

The service responsible for moving the bytes implements a **single `uploadAudio(local: URL) → ServerFile` contract**. Two conforming implementations exist: a real one that POSTs to the server and reads back the canonical server filename, and a demo one that sleeps for the visible upload duration and synthesizes a server-shaped filename from the user's local file. The view binds to the contract; the host decides which implementation to inject.

The "uploading" phase has a deliberate visible duration regardless of which implementation runs. Real uploads of small audio files often complete in milliseconds, which would feel like nothing happened — losing the moment. The view holds the uploading state for a minimum dwell so the animation can resolve and the user can register that something concrete happened. The demo path matches that dwell exactly; the real path uses `max(actualUploadTime, minimumDwell)`.

The handoff out of the screen is a value type carrying a **displayName** (the user's original filename, sans extension) and a **serverFile** (the canonical filename the rest of the app references). Demo and real both produce this value; downstream code can't tell them apart. The seam between demo and real lives entirely behind this value's construction.

### Swift

This project is written in Swift on Apple platforms. The agnostic terms above map to:

- **Single view hierarchy** → `SongView` in `Song.swift`. One source of truth for layout, animation, state machine, audio preview, file picker.
- **Upload service contract** → a Swift `protocol AudioUploadService { func uploadAudio(local: URL) async throws -> String }` exposing the canonical server filename returned by the upload.
- **Real implementation** → `RealAudioUploadService` posting multipart bytes via `URLSession` to the `/audio` endpoint, reading the response, returning the server-assigned filename.
- **Demo implementation** → `DemoAudioUploadService` running `try await Task.sleep(for: .milliseconds(1500))` and returning `"audio/\(name).m4a"` constructed from the user's local filename (sans extension).
- **Host-injected selection** → `SongView` initialized with a service instance; the `Generate` target injects the real one, a hypothetical `Demo` build / tutorial target / app-review build injects the demo one.
- **Visible upload dwell** → the `phase = .uploading(name:)` state is held for a minimum interval regardless of which service runs. Real path: `await max(uploadTask, sleepTask)`. Demo path: the sleep IS the dwell.
- **Looping audio preview** → `AVAudioPlayer(contentsOf:)` against the security-scoped local URL the user picked. No network. Identical in both demo and real.
- **PickedSong handoff** → `PickedSong { displayName: String, serverFile: String }`. Demo and real both return this; downstream `handleSongPicked` is service-agnostic.
- **Security scope discipline** → `startAccessingSecurityScopedResource()` on pick, released on confirm or cancel. Unchanged between demo and real.
- **Audio session** → `setCategory(.ambient, mode: .default, options: [.mixWithOthers])` + `setActive(true)` during preview, deactivated on dismissal. Identical in both.
