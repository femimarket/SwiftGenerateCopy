# Feature: Iterate

Knowledge transfer doc for the LLM implementing this feature.

## Goal

Add a fast in-place exploration loop for refining a specific image. User stays on one working surface, regenerates rapidly with a fast model, picks the keeper, everything else discards. Picked image goes to the grid.

## Why this exists

Founder observation from dogfooding: **90% of the time spent on image work is in the iteration loop** — generate, not quite right, regenerate, closer, regenerate, perfect, accept. The current flow forces this loop to round-trip through the grid (tap image → DeriveView → submit → back to grid → tap new image → DeriveView → repeat). That round-trip is friction multiplied by the 90% frequency, so it dominates the UX.

Iterate eliminates the round-trip: stay on one screen, regenerate in place, commit when satisfied.

## Architecture decision: three screens, three intents

Each screen does one thing well. Do NOT collapse these.

1. **Grid** = curated final library. Only accepted images. No drafts, no rejects.
2. **DeriveView (existing "Change it" screen)** = **deliberate prompt-driven derivation**. User has a vision in words, types a prompt change, commits one image. Slow, considered, high-quality model. Already implemented; do not modify the existing screen's role.
3. **Iterate (new)** = **fast visual exploration**. User regenerates rapidly, compares variants, picks the keeper. Fast model, low cost per iteration, high cadence.

Generate-from-+ menu is unchanged: still auto-fires the first batch from song context.

## Where the Iterate trigger lives

**Inside DeriveView, as a topBarTrailing toolbar item.**

Not in the + menu, because Iterate operates on a SPECIFIC image — and the only way to reach a specific image is by tapping it in the grid, which opens DeriveView for that image. Iterate is therefore a per-image operation, not a "create new" intent. Its logical home is the working screen for that image.

Trigger style — drop this into `DeriveView`'s `.toolbar { ... }` block alongside the existing items:

```swift
ToolbarItem(placement: .topBarTrailing) {
    Button {
        viewModel.openIterate(from: image)
    } label: {
        HStack(spacing: 4) {
            Image(systemName: "wand.and.stars")
            Text("Iterate")
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Theme.accentMagenta)
    }
}
```

`Theme.accentMagenta` signals "secondary action that's still important" — the accent magenta-blue gradient already used elsewhere in the app for branded affordances. Subheadline-weight-semibold keeps it readable without competing with the navigation title for visual hierarchy.

DeriveView's existing bottom "Make new ones" CTA stays — it remains the deliberate commit path. Iterate is the peer for exploration.

## Iterate screen behavior

When user taps the Iterate trigger in DeriveView, push a new screen (full-screen). Behavior:

- **Source image** is the image from DeriveView. Iterate runs over it.
- **Variant grid**: show 4 variants generated in parallel (Midjourney pattern — visual comparison is faster than verbal description).
- **Fast model** for variant generation. Currently the cheapest of `zimageturbo / nanoBanana2 / flux2Pro` — pick one as the iterate-loop model and document the choice.
- **Tap a variant** = accept it (commits to the project grid). All other variants from this iteration discard. Screen pops back to grid.
- **"Try again" CTA** at the bottom = regenerate 4 new variants with the same prompt context. No state cleanup needed; variants are ephemeral until accepted.
- **Long-press a variant** = "more like this" — uses that variant as a new seed for the next round of 4. Pivot mid-loop without losing the thread.
- **Dismiss** (swipe down / back) = discard everything, return to DeriveView with no commit.

State the user works with is exactly one source + 4 ephemeral variants. No history, no undo, no save-for-later. Everything except the accepted variant evaporates.

## What this feature explicitly does NOT do

These are deliberate omissions to preserve the blackbox vision (see related design decisions in conversation history):

- No metadata editing surface. Ever.
- No multi-intensity ratings. Heart stays binary; iteration intensity is inferred from behavior.
- No "save all variants" option. Accepted variant goes to grid, rest die.
- No in-app prompt editing on iterate. The prompt is inherited from DeriveView; the user's signal in iterate is purely visual (tap to pick, long-press to pivot, try again to refresh).
- No undo of the discard. Once you accept one variant, the others are gone. Treat as cheap; iterate runs are inexpensive.

## Open questions for the implementer

These are not blocked; pick a default and document it in the PR.

1. **Iterate model**: which of `zimageturbo / nanoBanana2 / flux2Pro` is the fastest? Use that one for iterate-loop variants. The commit model (when an image is accepted) can be the same or upgraded — defer to whichever ships clean.
2. **Variant count**: 4 is the Midjourney default and the recommended starting point. If 4 doesn't fit cleanly on iPhone screens, try 3 with larger cells, never go above 4.
3. **Layout of variants**: 2x2 grid filling most of the screen. Each cell square, no bleed, generous spacing. Tap target = whole cell.
4. **"Try again" position**: bottom safeAreaInset, single CTA. Same visual treatment as DeriveView's "Make new ones" CTA but with the iterate icon.
5. **Loading state**: when variants are regenerating, show 4 placeholder cells with the existing shimmer pattern from `pendingGenerationCell` in the grid. Reuse, don't reinvent.

## Out of scope for this implementation

- Persistent variant history (don't store rejected variants anywhere)
- "Compare last two iterations" — single-iteration only
- Editing the seed prompt from within iterate (user goes back to DeriveView for prompt changes)
- Sharing or saving individual variants outside the accept-to-grid flow

## Integration with existing flows

- **Grid → tap image → DeriveView**: unchanged.
- **DeriveView "Make new ones" CTA**: unchanged. Still commits a deliberate derivation directly to grid.
- **DeriveView toolbar trailing → Iterate**: new. Pushes Iterate screen with current image as source.
- **Iterate → accept variant**: commits to grid, pops all the way back to grid (skip DeriveView in the pop stack — the user is done with that image).
- **Iterate → dismiss without accepting**: pops back to DeriveView, image unchanged.

## Why this is Apple-pattern correct

- One screen, one purpose (Photos: edit ≠ browse ≠ share)
- Per-context actions live in the context (toolbar trailing of DeriveView ≠ + menu)
- Discard-on-dismiss matches iOS modal hygiene (composing an email and dismissing discards the draft unless explicitly saved)
- Visual variant grid mirrors Midjourney (the only AI tool that's truly nailed this loop)
- Binary accept (tap a variant) keeps cognitive load minimal — no rating dials, no slider intensity

## Tone of the final UX

Fast, ephemeral, visual. The user should feel like they're scrubbing through possibilities, not curating a deck. Each iteration is cheap; the only durable artifact is the accepted variant. Treat iterate as a creative scratchpad, not a save-everything gallery.
