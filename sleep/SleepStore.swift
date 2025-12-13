//
//  SleepStore.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import Foundation

@MainActor
final class SleepStore: ObservableObject {
    @Published var entries: [SleepEntry] = [] {
        didSet { persist(entries, forKey: entriesKey) }
    }
    @Published var routineSteps: [RoutineStep] = [] {
        didSet { persist(routineSteps, forKey: routineKey) }
    }
    @Published var soundscapeTracks: [SoundscapeTrack] = [] {
        didSet { persist(soundscapeTracks, forKey: soundscapeKey) }
    }

    private let entriesKey = "sleep.entries"
    private let routineKey = "sleep.routine"
    private let soundscapeKey = "sleep.soundscape"
    private let persistenceQueue = DispatchQueue(label: "sleep.store.persistence", qos: .utility)

    init() {
        entries = Self.load([SleepEntry].self, forKey: entriesKey) ?? SleepStore.sampleEntries
        routineSteps = Self.load([RoutineStep].self, forKey: routineKey) ?? SleepStore.sampleRoutine
        soundscapeTracks = Self.load([SoundscapeTrack].self, forKey: soundscapeKey) ?? SleepStore.sampleSoundscape
    }

    func addEntry(_ entry: SleepEntry) {
        entries.insert(entry, at: 0)
    }

    func updateEntry(_ entry: SleepEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
    }

    func deleteEntry(id: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries.remove(at: index)
    }

    func toggleRoutineStep(id: UUID) {
        guard let index = routineSteps.firstIndex(where: { $0.id == id }) else { return }
        routineSteps[index].completed.toggle()
    }

    func resetRoutine() {
        routineSteps = routineSteps.map { step in
            var updated = step
            updated.completed = false
            return updated
        }
    }

    func updateSoundscapeVolume(id: UUID, volume: Double) {
        guard let index = soundscapeTracks.firstIndex(where: { $0.id == id }) else { return }
        soundscapeTracks[index].volume = volume
    }

    func setSoundscapeEnabled(id: UUID, enabled: Bool) {
        guard let index = soundscapeTracks.firstIndex(where: { $0.id == id }) else { return }
        guard soundscapeTracks[index].isEnabled != enabled else { return }
        soundscapeTracks[index].isEnabled = enabled
    }

    func toggleSoundscape(id: UUID) {
        guard let track = soundscapeTracks.first(where: { $0.id == id }) else { return }
        setSoundscapeEnabled(id: id, enabled: !track.isEnabled)
    }

    var sortedEntries: [SleepEntry] {
        entries.sorted(by: { $0.date > $1.date })
    }

    var summary: SleepSummary {
        let sorted = sortedEntries
        let recent = Array(sorted.prefix(7))
        let latencyAvg = recent.isEmpty ? 0 : Double(recent.map { $0.latencyMinutes }.reduce(0, +)) / Double(recent.count)
        let wakeAvg = recent.isEmpty ? 0 : Double(recent.map { $0.wakeCount }.reduce(0, +)) / Double(recent.count)
        return SleepSummary(
            averageLatency: latencyAvg,
            averageWakeCount: wakeAvg,
            recentMood: sorted.first?.mood,
            lastEntry: sorted.first
        )
    }
}

// MARK: - Persistence helpers
private extension SleepStore {
    func persist<T: Encodable>(_ items: T, forKey key: String) {
        persistenceQueue.async {
            guard let data = try? JSONEncoder().encode(items) else {
                print("Warning: failed to encode data for key \(key)")
                return
            }
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Sample data
extension SleepStore {
    static let sampleEntries: [SleepEntry] = [
        SleepEntry(date: Date().addingTimeInterval(-86_400), mood: .refreshed, latencyMinutes: 18, wakeCount: 1, notes: "呼吸+粉噪声效果不错"),
        SleepEntry(date: Date().addingTimeInterval(-2 * 86_400), mood: .okay, latencyMinutes: 28, wakeCount: 2, notes: "晚饭有点晚"),
        SleepEntry(date: Date().addingTimeInterval(-3 * 86_400), mood: .tired, latencyMinutes: 35, wakeCount: 3, notes: "睡前刷手机太久")
    ]

    static let sampleRoutine: [RoutineStep] = [
        RoutineStep(title: "放下屏幕", icon: "iphone.slash", durationMinutes: 5),
        RoutineStep(title: "洗漱/拉窗帘", icon: "moon.stars", durationMinutes: 10),
        RoutineStep(title: "4-7-8 呼吸", icon: "lungs.fill", durationMinutes: 4),
        RoutineStep(title: "音景渐弱", icon: "waveform", durationMinutes: 30)
    ]

    static let sampleSoundscape: [SoundscapeTrack] = [
        SoundscapeTrack(title: "粉噪声", description: "平稳遮挡环境噪音", kind: .pinkNoise, volume: 0.7, isEnabled: true),
        SoundscapeTrack(title: "雨声", description: "轻柔雨幕，帮助放松", kind: .rain, volume: 0.65, isEnabled: false),
        SoundscapeTrack(title: "壁炉", description: "噼啪火光，营造安全感", kind: .fireplace, volume: 0.55, isEnabled: false)
    ]
}
