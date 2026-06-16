//
//  LyricExtractor.swift
//  Generate2
//
//  SYLT extraction via AudioMarker. Lives in its own file so `import
//  AudioMarker`'s top-level `Configuration` type doesn't collide with
//  SwiftUI's `ButtonStyle.Configuration` associated-type lookup inside
//  ContentView.swift.
//

import Foundation
import AudioMarker

/// Reads timestamped lyric lines from an audio file's ID3 SYLT / m4a chapter
/// metadata. SYLT carries start times only — blank lines (empty text) act as
/// sentinels marking the end of the previous line. We compute duration from
/// neighbors and drop sentinels from the output.
enum LyricExtractor {
    nonisolated static func read(audioURL: URL) -> [FemiSongLine] {
        let engine = AudioMarkerEngine()
        guard let info = try? engine.read(from: audioURL),
              let raw = info.metadata.synchronizedLyrics.first?.lines,
              !raw.isEmpty
        else { return [] }
        var out: [FemiSongLine] = []
        var visibleIndex = 0
        for i in raw.indices {
            let line = raw[i]
            let startMs = ms(line.time)
            let endMs = i + 1 < raw.count ? ms(raw[i + 1].time) : startMs
            if line.text.isEmpty { continue }
            out.append(FemiSongLine(
                id: UUID(),
                index: visibleIndex,
                text: line.text,
                startMs: startMs,
                durationMs: max(0, endMs - startMs)
            ))
            visibleIndex += 1
        }
        return out
    }

    /// `AudioTimestamp.timeInterval` is seconds (Double). Convert to integer
    /// milliseconds for `FemiSongLine.startMs`.
    nonisolated private static func ms(_ t: AudioTimestamp) -> Int {
        Int(t.timeInterval * 1000)
    }
}
