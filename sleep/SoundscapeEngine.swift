//
//  SoundscapeEngine.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import AVFoundation
import Foundation

/// Lightweight, asset-free soundscape generator (pink noise, rain-like noise, fireplace-like noise).
/// Uses AVAudioEngine + AVAudioSourceNode to synthesize noise so it works without bundled audio files.
final class SoundscapeEngine: ObservableObject {
    struct TrackState {
        var kind: SoundKind
        var volume: Float
        var enabled: Bool
        var filterValue: Float = 0
    }

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isFadingOut: Bool = false

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var trackStates: [UUID: TrackState] = [:]
    private var masterVolume: Float = 1.0
    private var fadeTimer: Timer?
    private let stateQueue = DispatchQueue(label: "soundscape.state.queue", qos: .userInitiated)

    init() {
        configureAudioSession()
    }

    func configureTracks(_ tracks: [SoundscapeTrack]) {
        stateQueue.sync {
            var newStates: [UUID: TrackState] = [:]
            for track in tracks {
                newStates[track.id] = TrackState(kind: track.kind, volume: Float(track.volume), enabled: track.isEnabled, filterValue: 0)
            }
            trackStates = newStates
        }
        if isPlaying { // apply new mix immediately
            rebuildSource()
        }
    }

    func setVolume(for trackID: UUID, volume: Double) {
        stateQueue.sync {
            guard trackStates[trackID] != nil else { return }
            trackStates[trackID]?.volume = Float(volume)
        }
    }

    func setEnabled(for trackID: UUID, enabled: Bool) {
        stateQueue.sync {
            guard trackStates[trackID] != nil else { return }
            trackStates[trackID]?.enabled = enabled
        }
    }

    func start() {
        guard !isPlaying else { return }
        rebuildSource()
        do {
            try engine.start()
            isPlaying = true
            isFadingOut = false
            masterVolume = 1.0
        } catch {
            print("Failed to start engine: \(error)")
        }
    }

    func stop() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        engine.stop()
        isPlaying = false
        isFadingOut = false
    }

    /// Gradually fades out and stops playback.
    func fadeOut(duration: TimeInterval) {
        guard isPlaying, fadeTimer == nil else { return }
        isFadingOut = true
        let steps = 40
        let stepDuration = duration / Double(steps)
        var currentStep = 0
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true, block: { [weak self] timer in
            guard let self else { return }
            currentStep += 1
            let progress = Float(currentStep) / Float(steps)
            masterVolume = max(0, 1.0 - progress)
            if currentStep >= steps {
                timer.invalidate()
                fadeTimer = nil
                stop()
            }
        })
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    private func rebuildSource() {
        engine.stop()
        engine.reset()
        if let sourceNode {
            engine.detach(sourceNode)
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let strongSelf = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            // Grab a snapshot of states to avoid mutating shared data without synchronization.
            var localStates: [UUID: TrackState] = [:]
            strongSelf.stateQueue.sync {
                localStates = strongSelf.trackStates
            }

            for frame in 0..<Int(frameCount) {
                var mixedSample: Float = 0
                for (id, var state) in localStates {
                    guard state.enabled else { continue }
                    let sample = strongSelf.sample(for: state.kind, state: &state)
                    mixedSample += sample * state.volume
                    localStates[id] = state // persist filter value
                }
                mixedSample = tanh(mixedSample) * strongSelf.masterVolume
                for buffer in ablPointer {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = mixedSample
                }
            }

            // Write back updated filter values once per render pass.
            strongSelf.stateQueue.sync {
                strongSelf.trackStates = localStates
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        sourceNode = node
    }

    private func sample(for kind: SoundKind, state: inout TrackState) -> Float {
        let white = Float.random(in: -1...1)
        switch kind {
        case .pinkNoise:
            // Simple low-pass filtered white noise for softer texture.
            state.filterValue = 0.98 * state.filterValue + 0.02 * white
            return state.filterValue
        case .rain:
            // Slightly faster decay + subtle shimmer.
            state.filterValue = 0.92 * state.filterValue + 0.08 * white
            return state.filterValue * 0.9 + white * 0.1
        case .fireplace:
            // Slow rumble with occasional crackle.
            state.filterValue = 0.995 * state.filterValue + 0.005 * white
            let crackle = Bool(probability: 0.02) ? Float.random(in: 0.3...0.8) * white : 0
            return state.filterValue + crackle
        }
    }
}

private extension Bool {
    /// Returns true with the given probability (0...1).
    init(probability: Double) {
        self = Double.random(in: 0...1) < probability
    }
}
