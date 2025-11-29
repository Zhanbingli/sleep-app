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

    private struct EngineSnapshot {
        var trackStates: [UUID: TrackState]
        var masterVolume: Float
    }

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isFadingOut: Bool = false

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var trackStates: [UUID: TrackState] = [:]
    private var masterVolume: Float = 1.0
    private var fadeTimer: Timer?
    private let stateQueue = DispatchQueue(label: "soundscape.state.queue", qos: .userInitiated, attributes: .concurrent)
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
    private var shouldResumeAfterInterruption = false

    init() {
        configureAudioSession()
        observeAudioSession()
    }

    func configureTracks(_ tracks: [SoundscapeTrack]) {
        stateQueue.sync(flags: .barrier) {
            var newStates: [UUID: TrackState] = [:]
            for track in tracks {
                newStates[track.id] = TrackState(kind: track.kind, volume: Float(track.volume), enabled: track.isEnabled, filterValue: 0)
            }
            self.trackStates = newStates
        }
        if isPlaying { // apply new mix immediately
            rebuildSource()
        }
    }

    func setVolume(for trackID: UUID, volume: Double) {
        stateQueue.async(flags: .barrier) {
            guard self.trackStates[trackID] != nil else { return }
            self.trackStates[trackID]?.volume = Float(volume)
        }
    }

    func setEnabled(for trackID: UUID, enabled: Bool) {
        stateQueue.async(flags: .barrier) {
            guard self.trackStates[trackID] != nil else { return }
            self.trackStates[trackID]?.enabled = enabled
        }
    }

    func start() {
        guard !isPlaying else { return }
        rebuildSource()
        do {
            try engine.start()
            isPlaying = true
            isFadingOut = false
            setMasterVolume(1.0)
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
            setMasterVolume(max(0, 1.0 - progress))
            if currentStep >= steps {
                timer.invalidate()
                fadeTimer = nil
                stop()
            }
        })
    }

    private func setMasterVolume(_ volume: Float) {
        stateQueue.async(flags: .barrier) {
            self.masterVolume = volume
        }
    }

    private func snapshotState() -> EngineSnapshot {
        stateQueue.sync {
            EngineSnapshot(trackStates: self.trackStates, masterVolume: self.masterVolume)
        }
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    private func observeAudioSession() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main,
            using: { [weak self] in self?.handleInterruption($0) }
        )
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main,
            using: { [weak self] in self?.handleRouteChange($0) }
        )
    }

    private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            shouldResumeAfterInterruption = isPlaying
            stop()
        case .ended:
            let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if shouldResumeAfterInterruption && options.contains(.shouldResume) {
                start()
            }
            shouldResumeAfterInterruption = false
        @unknown default:
            shouldResumeAfterInterruption = false
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else { return }

        if reason == .oldDeviceUnavailable || reason == .categoryChange {
            shouldResumeAfterInterruption = isPlaying
            stop()
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

            let snapshot = strongSelf.snapshotState()
            var localStates = snapshot.trackStates
            let masterVolume = snapshot.masterVolume

            for frame in 0..<Int(frameCount) {
                var mixedSample: Float = 0
                for (id, var state) in localStates {
                    guard state.enabled else { continue }
                    let sample = strongSelf.sample(for: state.kind, state: &state)
                    mixedSample += sample * state.volume
                    localStates[id] = state // persist filter value
                }
                mixedSample = tanh(mixedSample) * masterVolume
                for buffer in ablPointer {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = mixedSample
                }
            }

            // Write back updated filter values once per render pass.
            strongSelf.stateQueue.async(flags: .barrier) {
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

    deinit {
        if let token = interruptionObserver {
            NotificationCenter.default.removeObserver(token)
        }
        if let token = routeChangeObserver {
            NotificationCenter.default.removeObserver(token)
        }
    }
}

private extension Bool {
    /// Returns true with the given probability (0...1).
    init(probability: Double) {
        self = Double.random(in: 0...1) < probability
    }
}
