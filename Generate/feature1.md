# Feature 1 — Pre-primed splash audio

## The mission

The first beat of the song should land the moment the splash lands. Not a frame later. The user shouldn't ever feel the app *fetching* its own intro music — they should feel it *land*.

## The goal

Zero perceptible delay between the tap that ends the song-picking moment and the first audible beat of the splash. The animation and the sound arrive together, like a cut in a film.

## The vision

Heavy work doesn't get to live in the interactive moment. The app spends its quiet launch seconds quietly readying the things it knows it will need. By the time the user actually reaches for the door, it's already open.

Specifically: the onboarding WAV is decoded, prepared, and waiting in memory from the second the app starts. When the splash appears, the audio engine has nothing to fetch, decode, or set up — it has only to press play.

## What this is not

It is not a louder splash. It is not a longer splash. It is not an animation tweak. It is the absence of a delay nobody should ever have to feel.

---

## Tech

The audio asset for the splash is decoded and prepared at **application start**, not at the moment the splash mounts. Disk lookup, file decode, and codec preroll run on a background priority task and produce a *primed* player. The primed player is owned by an **app-scoped singleton** so it survives across screen transitions and is reachable from whichever view eventually starts it.

The view that needs to play the asset never blocks on I/O. Its only work is to **activate the audio session and call play()** — both of which are constant-time on a primed player. Prepare is **idempotent**: redundant calls are no-ops after the first.

### Swift

This project is written in Swift on Apple platforms. The agnostic terms above map to:

- **Application start hook** → `App.init` on the `@main` `struct` conforming to `App`.
- **App-scoped singleton owner** → `@MainActor @Observable final class` with `static let shared`.
- **Background decode + preroll** → `Task.detached(priority: .userInitiated)` running `AVAudioPlayer(contentsOf:)` and `prepareToPlay()` off the main actor.
- **Primed player** → an instance of `AVAudioPlayer` retained on the singleton after `prepareToPlay()` returns.
- **Hop to main for handoff** → `await MainActor.run { ... }` to assign the player and update observable state.
- **Idempotent prepare** → a `preparing` / `player == nil` guard on the singleton.
- **Audio session activation** → `AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])` + `setActive(true)`.
- **View-side trigger** → SwiftUI `.task { ... }` modifier on the splash, calling `start(...)` on the singleton.
- **Play on primed player** → `setCategory` + `setActive` + `play()` on main, no I/O.
- **Fade in** → `setVolume(_:fadeDuration:)` after `play()`.

