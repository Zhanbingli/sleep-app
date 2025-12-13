//
//  SoundscapeViewModel.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import SwiftUI
import Combine

@MainActor
final class SoundscapeViewModel: ObservableObject {
    @Published private(set) var tracks: [SoundscapeTrack]
    @Published var fadeMinutes: Double
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isFadingOut: Bool = false

    private let store: SleepStore
    private let engine: SoundscapeEngine
    private var cancellables: Set<AnyCancellable> = []

    init(store: SleepStore, engine: SoundscapeEngine, fadeMinutes: Double = 30) {
        self.store = store
        self.engine = engine
        self.tracks = store.soundscapeTracks
        self.fadeMinutes = fadeMinutes
        bind()
        engine.configureTracks(store.soundscapeTracks)
    }

    private func bind() {
        store.$soundscapeTracks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tracks in
                self?.tracks = tracks
                self?.engine.configureTracks(tracks)
            }
            .store(in: &cancellables)

        engine.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isPlaying = $0 }
            .store(in: &cancellables)

        engine.$isFadingOut
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isFadingOut = $0 }
            .store(in: &cancellables)
    }

    func setEnabled(for track: SoundscapeTrack, enabled: Bool) {
        store.setSoundscapeEnabled(id: track.id, enabled: enabled)
        engine.setEnabled(for: track.id, enabled: enabled)
        if let index = tracks.firstIndex(where: { $0.id == track.id }) {
            tracks[index].isEnabled = enabled
        }
    }

    func updateVolume(for track: SoundscapeTrack, volume: Double) {
        store.updateSoundscapeVolume(id: track.id, volume: volume)
        engine.setVolume(for: track.id, volume: volume)
        if let index = tracks.firstIndex(where: { $0.id == track.id }) {
            tracks[index].volume = volume
        }
    }

    func togglePlayback() {
        isPlaying ? stop() : startPlayback()
    }

    func startPlayback() {
        ensureDefaultTrackIfNeeded()
        engine.configureTracks(tracks)
        engine.start()
    }

    func stop() {
        engine.stop()
    }

    func startFadeOut() {
        guard isPlaying else { return }
        engine.fadeOut(duration: fadeMinutes * 60)
    }

    private func ensureDefaultTrackIfNeeded() {
        guard !tracks.contains(where: { $0.isEnabled }) else { return }
        guard let first = tracks.first else { return }
        setEnabled(for: first, enabled: true)
    }

    var statusText: String {
        if isFadingOut {
            return "渐弱进行中..."
        }
        if isPlaying { return "建议搭配 20-40 分钟渐弱，减少夜间惊醒。" }
        let hasEnabled = tracks.contains(where: { $0.isEnabled })
        return hasEnabled ? "选择开启的音景后点击开始。" : "先开启至少一个音景，再开始播放。"
    }
}
