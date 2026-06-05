# Engine — key architectural decisions

## The mission

A music video shouldn't drift. The drums on screen should hit the drums in your ears at the same instant. The lyrics should land on the singer's syllable. The viewer should never notice playback exists.

## The one rule

Audio is the only clock. Not the system, not the framerate, not the UI framework's invalidation graph. Every consumer asks the audio *what time is it?* and decides what to be from the answer. Nothing else owns a clock; nothing can fall out of sync.

## The key decisions

**Sample, don't observe.** The audio clock's current time and the flags derived from it (current scene, current lyric line, sequel and feedback windows) live in shared atomic memory. There is no publish/subscribe cascade between the producer of that state and its consumers. Three consumers — the audio tick that advances the state, the render thread that paints pixels, the UI that draws chrome — read the same atomic truth without locks. The audio tick writes; the others sample.

**The audio tick runs on a dedicated timer, not a display loop.** A display loop is chained to the system's render server and stalls when the render server stalls. Reading an audio clock through it would couple the audio's truth to the UI's busyness. An independent timer on its own queue stays honest.

**Video renders off the main thread.** A dedicated thread owns its own display loop, fires at the display refresh rate, and reads the current millisecond from the shared atomic state (the audio clock's truth, written by the audio tick). Main-thread work — touch events, UI invalidation, modal presentation — cannot stall the next frame because the next frame isn't drawn there.

**Frames live on the GPU.** Each clip is decoded once into a frame stack uploaded as a single texture. The renderer indexes the stack by the current millisecond. The CPU never touches pixels during playback.

**Transitions are one stateless effect.** Every transition is a single fragment function branched by a kind tag, running normalised time `t = 0 → 1` over its scheduled window. Adding a transition is one branch and one timeline kind — nothing else changes.

**The UI samples on a fixed cadence; modifiers stay outside it.** The polling view wraps only the visual content. Sheets, full-screen covers, and other presentation modifiers live *above* the sampling boundary so they don't re-attach every time the polling view re-samples the atomic state.

**The timeline is a flat row list.** Each row is `{kind, resourceId, start, duration}`. Kind is a tagged union covering every track type — audio, video, text, character reveals, transitions, fades. No nesting, no branching, no time inside time. The whole performance is a list.

**Heavy work runs detached, then hands off.** File decoding, asset upload, audio mixing run on a background task. The main thread sees only the final state assignments and the call that starts the audio playback. The interactive moment never blocks on I/O.

**Teardown is explicit.** The audio engine, the tick timer, and all observers are stopped by name when the screen goes away. No process holds a sound after dismiss.

## What we're deferring

Streaming frames instead of loading the whole clip. Variable framerate within one clip. Stateful effects that need a history of past frames. Authoring the timeline inside the app. Sample-accurate joins between two audio buffers without drift.

## The vibe

When it's working, you don't think about it. The drum hits, the screen pulses, the word lights up under the singer's syllable, and the only thing you notice is the song.

When something feels off, the answer is never to dress it up. The answer is to find the clock and ask *why didn't this read from the audio?*

---

## The timeline, as shipped

This is the feed-level timeline the engine actually plays — one JSON array, each element a row in the shape described above. Three scenes of audio + video, a question window (Text + Feedback), and an outro:

```json
[
  { "id": "A0000001-0000-0000-0000-000000000001", "user_id": "femi",
    "track": "Audio", "resource_id": "11111111-0000-0000-0000-000000000001",
    "timeline_start_ms": 0, "duration": 8000 },
  { "id": "A0000001-0000-0000-0000-000000000002", "user_id": "femi",
    "track": "Video", "resource_id": "11111111-0000-0000-0000-000000000002",
    "timeline_start_ms": 0, "duration": 8000 },

  { "id": "A0000001-0000-0000-0000-000000000003", "user_id": "femi",
    "track": "Audio", "resource_id": "11111111-0000-0000-0000-000000000003",
    "timeline_start_ms": 8000, "duration": 8000 },
  { "id": "A0000001-0000-0000-0000-000000000004", "user_id": "femi",
    "track": "Video", "resource_id": "11111111-0000-0000-0000-000000000004",
    "timeline_start_ms": 8000, "duration": 8000 },

  { "id": "A0000001-0000-0000-0000-000000000005", "user_id": "femi",
    "track": "Audio", "resource_id": "11111111-0000-0000-0000-000000000005",
    "timeline_start_ms": 16000, "duration": 28608 },
  { "id": "A0000001-0000-0000-0000-000000000006", "user_id": "femi",
    "track": "Video", "resource_id": "11111111-0000-0000-0000-000000000006",
    "timeline_start_ms": 16000, "duration": 28608 },

  { "id": "A0000001-0000-0000-0000-000000000009", "user_id": "femi",
    "track": "Text", "resource_id": "22222222-0000-0000-0000-000000000001",
    "timeline_start_ms": 44608, "duration": 8000 },
  { "id": "A0000001-0000-0000-0000-00000000000A", "user_id": "femi",
    "track": "Feedback", "resource_id": "22222222-0000-0000-0000-000000000001",
    "timeline_start_ms": 44608, "duration": 8000 },

  { "id": "A0000001-0000-0000-0000-000000000007", "user_id": "femi",
    "track": "Audio", "resource_id": "11111111-0000-0000-0000-000000000007",
    "timeline_start_ms": 52608, "duration": 2735 },
  { "id": "A0000001-0000-0000-0000-000000000008", "user_id": "femi",
    "track": "Video", "resource_id": "11111111-0000-0000-0000-000000000008",
    "timeline_start_ms": 52608, "duration": 2735 }
]
```

Resources referenced by `resource_id` are resolved through a per-track registry. The engine never branches on what a resource *is* — only on what track it belongs to.

---

## Swift

This project is written in Swift on Apple platforms. The agnostic terms above map to:

- **Shared atomic memory** → `Atomic<Int>`, `Atomic<Int64>`, `Atomic<Bool>` from the `Synchronization` framework, with `.relaxed` ordering.
- **Dedicated audio tick timer** → `DispatchSourceTimer` on a serial `DispatchQueue` with `qos: .userInteractive`.
- **Off-main render thread** → a `Thread(target:selector:object:)` running `CFRunLoopRun()` in `.default` mode and hosting a display link.
- **Display loop** → `CAMetalDisplayLink`. Explicitly *not* `CADisplayLink` for the audio tick (chained to the render server). Explicitly *not* `MTKView` for the render target (`MTKView.draw(in:)` is `@MainActor`).
- **Render target** → a `UIView` whose `layerClass` is `CAMetalLayer.self`. The layer is captured at init so the render thread never touches `UIView.layer` off-main.
- **Audio clock** → `AVAudioEngine` + `AVAudioPlayerNode` playing an `AVAudioPCMBuffer`. Current time = the player node's sample time corrected by `AVAudioSession.outputLatency`.
- **Frame stack on the GPU** → an `MTLTexture` of type `texture2DArray` populated from an ASTC byte stream, sampled by a single fragment shader.
- **Stateless effect shader** → one MSL fragment function branching on a `kind` uniform.
- **Polling view** → `TimelineView(.animation(minimumInterval:))`. Modifiers (`.sheet`, `.fullScreenCover`, etc.) stay outside the `TimelineView`'s closure.
- **Tagged-union timeline kind** → a Swift `enum` with associated values, decoded from JSON.
- **Detached load** → `Task.detached(priority: .userInitiated)`.
- **Off-main shared reference** → `nonisolated(unsafe)` stored properties for the captured Metal layer and similar single-write-many-read state.
- **Explicit teardown** → `deinit` that stops the player node, stops the engine, cancels the timer, removes notification observers.

