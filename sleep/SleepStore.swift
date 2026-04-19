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
    @Published var soundscapeFadeMinutes: Double = 30 {
        didSet { persist(soundscapeFadeMinutes, forKey: soundscapeFadeKey) }
    }
    @Published var profile: SleepProfile? {
        didSet { persist(profile, forKey: profileKey) }
    }

    private let entriesKey = "sleep.entries"
    private let routineKey = "sleep.routine"
    private let soundscapeKey = "sleep.soundscape"
    private let soundscapeFadeKey = "sleep.soundscape.fadeMinutes"
    private let profileKey = "sleep.profile"
    private let persistenceQueue = DispatchQueue(label: "sleep.store.persistence", qos: .utility)

    init() {
        entries = Self.load([SleepEntry].self, forKey: entriesKey) ?? SleepStore.sampleEntries
        routineSteps = Self.load([RoutineStep].self, forKey: routineKey) ?? SleepStore.sampleRoutine
        soundscapeTracks = Self.load([SoundscapeTrack].self, forKey: soundscapeKey) ?? SleepStore.sampleSoundscape
        soundscapeFadeMinutes = Self.load(Double.self, forKey: soundscapeFadeKey) ?? 30
        profile = Self.load(SleepProfile.self, forKey: profileKey)

        if let previewScreen = AppLaunchPreview.current {
            entries = Self.sampleEntries
            routineSteps = Self.sampleRoutine
            soundscapeTracks = Self.sampleSoundscape
            soundscapeFadeMinutes = 30
            profile = previewScreen == .onboarding ? nil : Self.sampleProfile
        }

        migrateLocalizedContentIfNeeded()
    }

    var hasCompletedOnboarding: Bool {
        profile != nil
    }

    func completeOnboarding(with profile: SleepProfile) {
        self.profile = profile
        applyRecommendedSoundscape(kind: profile.preferredSound)
    }

    func updateProfile(_ profile: SleepProfile) {
        completeOnboarding(with: profile)
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

    func addRoutineStep(_ step: RoutineStep) {
        routineSteps.append(step)
    }

    func updateRoutineStep(_ step: RoutineStep) {
        guard let index = routineSteps.firstIndex(where: { $0.id == step.id }) else { return }
        routineSteps[index] = step
    }

    func deleteRoutineStep(id: UUID) {
        guard let index = routineSteps.firstIndex(where: { $0.id == id }) else { return }
        routineSteps.remove(at: index)
    }

    func deleteRoutineSteps(atOffsets offsets: IndexSet) {
        for offset in offsets.sorted(by: >) {
            routineSteps.remove(at: offset)
        }
    }

    func moveRoutineSteps(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        let movingSteps = offsets.sorted().map { routineSteps[$0] }
        for offset in offsets.sorted(by: >) {
            routineSteps.remove(at: offset)
        }

        let adjustedDestination = destination - offsets.filter { $0 < destination }.count
        routineSteps.insert(contentsOf: movingSteps, at: adjustedDestination)
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

    func updateSoundscapeFadeMinutes(_ minutes: Double) {
        soundscapeFadeMinutes = minutes
    }

    func resetLocalData() {
        entries = []
        routineSteps = Self.sampleRoutine
        soundscapeTracks = Self.sampleSoundscape
        soundscapeFadeMinutes = 30
        profile = nil
    }

    func setSoundscapeEnabled(id: UUID, enabled: Bool) {
        guard let index = soundscapeTracks.firstIndex(where: { $0.id == id }) else { return }
        guard soundscapeTracks[index].isEnabled != enabled else { return }
        soundscapeTracks[index].isEnabled = enabled
    }

    func applyRecommendedSoundscape(kind: SoundKind) {
        soundscapeTracks = soundscapeTracks.map { track in
            var updated = track
            updated.isEnabled = track.kind == kind
            if track.kind == kind {
                updated.volume = max(updated.volume, 0.65)
            }
            return updated
        }
    }

    var sortedEntries: [SleepEntry] {
        entries.sorted(by: { $0.date > $1.date })
    }

    var summary: SleepSummary {
        let recent = Array(sortedEntries.prefix(7))
        let detailedRecent = recent.filter(\.isDetailed)

        func rate(for predicate: (SleepEntry) -> Bool) -> Double {
            guard !detailedRecent.isEmpty else { return 0 }
            return Double(detailedRecent.filter(predicate).count) / Double(detailedRecent.count)
        }

        let latencies = detailedRecent.compactMap(\.latencyMinutes)
        let wakeCounts = detailedRecent.compactMap(\.wakeCount)
        let latencyAvg = latencies.isEmpty ? 0 : Double(latencies.reduce(0, +)) / Double(latencies.count)
        let wakeAvg = wakeCounts.isEmpty ? 0 : Double(wakeCounts.reduce(0, +)) / Double(wakeCounts.count)
        let sleepAvg = detailedRecent.isEmpty ? 0 : detailedRecent.map(\.sleepDurationHours).reduce(0, +) / Double(detailedRecent.count)
        let settleEntries = recent.compactMap(\.settleFeedback)
        let positiveSettleRate = settleEntries.isEmpty ? 0 : Double(settleEntries.filter { $0 == .yes || $0 == .somewhat }.count) / Double(settleEntries.count)

        return SleepSummary(
            detailedEntryCount: detailedRecent.count,
            averageLatency: latencyAvg,
            averageWakeCount: wakeAvg,
            averageSleepHours: sleepAvg,
            phoneUseRate: rate { $0.usedPhoneBeforeBed },
            caffeineRate: rate { $0.hadLateCaffeine },
            alcoholRate: rate { $0.hadAlcohol },
            highStressRate: rate { $0.stressLevel == .high },
            positiveSettleRate: positiveSettleRate,
            recentMood: sortedEntries.first?.mood,
            lastEntry: sortedEntries.first
        )
    }

    var routineCompletedCount: Int {
        routineSteps.filter(\.completed).count
    }

    var routineProgressText: String {
        guard !routineSteps.isEmpty else { return L10n.tr("先添加 2-3 个固定睡前动作") }
        return L10n.format("已完成 %d/%d 个睡前动作", routineCompletedCount, routineSteps.count)
    }

    var profileStatusLine: String {
        guard let profile else {
            return L10n.tr("先告诉我你最常见的睡前问题，我再帮你定今晚计划。")
        }
        return L10n.format("当前聚焦：%@", profile.primaryChallenge.title)
    }

    var planConfidenceLine: String {
        if summary.detailedEntryCount >= 5 {
            return L10n.format("已基于近 7 天 %d 条详细复盘给出今晚判断。", summary.detailedEntryCount)
        }
        if summary.detailedEntryCount > 0 {
            return L10n.format("已参考近 7 天 %d 条详细复盘，继续补充会让推荐更稳。", summary.detailedEntryCount)
        }
        if !sortedEntries.isEmpty {
            return L10n.tr("目前主要基于你的睡前画像和晨间反馈，补 1 条详细复盘后会更准。")
        }
        return L10n.tr("目前主要基于你的睡前画像，补 1 条详细复盘后会开始形成趋势。")
    }

    var historyTrustLine: String {
        if summary.detailedEntryCount > 0 {
            return L10n.tr("趋势只统计详细复盘；晨间快记会保留在列表里，但不会拉偏平均值。")
        }
        return L10n.tr("趋势只统计详细复盘；现在的晨间快记不会被拿来伪造平均值。")
    }

    var tonightPlan: TonightPlan {
        tonightPlan(for: nil)
    }

    func tonightPlan(for tonightState: TonightState?) -> TonightPlan {
        guard let profile else {
            return TonightPlan(
                title: L10n.tr("先建立你的睡前画像"),
                detail: L10n.tr("做完首次引导后，我会根据你的主要问题和最近 7 天反馈给出更具体的今晚方案。"),
                recommendedBreathing: .coherent,
                fadeMinutes: 30,
                focusLabel: L10n.tr("先设定"),
                recommendedSoundKind: .pinkNoise,
                insight: L10n.tr("还没有个性化依据。"),
                stateTitle: L10n.tr("先完成首次引导")
            )
        }

        var recommendedBreathing = profile.primaryChallenge.defaultBreathing
        var recommendedSound = profile.preferredSound
        var fadeMinutes = max(profile.preferredWindDownMinutes * 3, profile.primaryChallenge.defaultFadeMinutes)
        var title = titleForChallenge(profile.primaryChallenge)
        var focus = profile.primaryChallenge.focusLabel
        var reasons = [baseReason(for: profile.primaryChallenge)]
        var stateTitle = tonightState?.title ?? profile.primaryChallenge.title

        if let tonightState {
            recommendedBreathing = tonightState.recommendedBreathing
            recommendedSound = tonightState.recommendedSoundKind
            focus = tonightState.focusLabel
            title = titleForState(tonightState)
            reasons = [tonightState.detail]
            stateTitle = tonightState.title
        }

        if summary.phoneUseRate >= 0.5 {
            recommendedBreathing = .box
            title = L10n.tr("今晚先把注意力从屏幕拉回来")
            focus = L10n.tr("断开刺激")
            reasons.append(L10n.tr("最近睡前刷手机出现得比较频繁"))
        }

        if summary.averageLatency >= 30 || summary.highStressRate >= 0.4 {
            recommendedBreathing = .fourSevenEight
            recommendedSound = .rain
            fadeMinutes = max(fadeMinutes, 35)
            title = L10n.tr("今晚先把速度慢下来")
            focus = L10n.tr("先降速")
            reasons.append(L10n.tr("最近入睡偏慢，或者压力值偏高"))
        }

        if summary.averageWakeCount >= 2 || profile.primaryChallenge == .lightSleep || profile.primaryChallenge == .noiseSensitive {
            recommendedBreathing = .coherent
            recommendedSound = .pinkNoise
            fadeMinutes = max(fadeMinutes, 45)
            title = L10n.tr("今晚以稳定感为主")
            focus = L10n.tr("更平稳")
            reasons.append(L10n.tr("最近夜醒偏多，先把外界干扰降下来"))
        }

        if summary.caffeineRate >= 0.3 {
            reasons.append(L10n.tr("最近晚咖啡也在拖慢入睡"))
        }

        if summary.alcoholRate >= 0.3 {
            reasons.append(L10n.tr("最近酒精摄入可能在拉低后半夜睡眠稳定性"))
        }

        if summary.positiveSettleRate < 0.4 && !sortedEntries.isEmpty {
            fadeMinutes = min(fadeMinutes + 10, 50)
            reasons.append(L10n.tr("最近主观反馈显示，当前流程还没有足够快地帮你安静下来"))
        }

        let detail = reasons.joined(separator: L10n.tr("，")) + L10n.tr("。")
        let insight = reasons.last ?? reasons.first ?? L10n.tr("今晚先按推荐流程走一遍。")

        return TonightPlan(
            title: title,
            detail: detail,
            recommendedBreathing: recommendedBreathing,
            fadeMinutes: fadeMinutes,
            focusLabel: focus,
            recommendedSoundKind: recommendedSound,
            insight: insight,
            stateTitle: stateTitle
        )
    }
}

private extension SleepStore {
    func titleForChallenge(_ challenge: SleepChallenge) -> String {
        switch challenge {
        case .mindRacing:
            return L10n.tr("今晚先把脑子里的速度放下来")
        case .phoneScrolling:
            return L10n.tr("今晚先从屏幕里退出来")
        case .stressLoad:
            return L10n.tr("今晚先让身体松下来")
        case .lightSleep:
            return L10n.tr("今晚优先做稳定感")
        case .noiseSensitive:
            return L10n.tr("今晚先把环境声盖住")
        }
    }

    func baseReason(for challenge: SleepChallenge) -> String {
        switch challenge {
        case .mindRacing:
            return L10n.tr("你的主要问题是睡前思绪太满")
        case .phoneScrolling:
            return L10n.tr("你的主要问题是睡前容易被手机拖走")
        case .stressLoad:
            return L10n.tr("你的主要问题是压力把身体留在兴奋状态")
        case .lightSleep:
            return L10n.tr("你的主要问题是睡眠稳定感不足")
        case .noiseSensitive:
            return L10n.tr("你的主要问题是对外界声音过于敏感")
        }
    }

    func titleForState(_ state: TonightState) -> String {
        switch state {
        case .racingThoughts:
            return L10n.tr("今晚先把脑内速度放下来")
        case .stressed:
            return L10n.tr("今晚先把紧绷感卸下来")
        case .scrolling:
            return L10n.tr("今晚先从屏幕刺激里退出来")
        case .mentallyAlert:
            return L10n.tr("今晚先切进睡眠准备状态")
        }
    }

    func migrateLocalizedContentIfNeeded() {
        let migratedEntries = entries.map { entry in
            var updated = entry
            updated.notes = localizedSeededNoteIfNeeded(entry.notes)
            return updated
        }

        let migratedRoutine = routineSteps.map { step in
            var updated = step
            updated.title = localizedRoutineTitleIfNeeded(step.title, icon: step.icon)
            return updated
        }

        let migratedTracks = soundscapeTracks.map { track in
            var updated = track
            updated.title = track.kind.displayName
            updated.description = track.kind.trackDescription
            return updated
        }

        if migratedEntries != entries {
            entries = migratedEntries
        }
        if migratedRoutine != routineSteps {
            routineSteps = migratedRoutine
        }
        if migratedTracks != soundscapeTracks {
            soundscapeTracks = migratedTracks
        }
    }

    func localizedSeededNoteIfNeeded(_ note: String) -> String {
        let mappings = [
            "呼吸+粉噪声效果不错",
            "晚饭有点晚",
            "睡前刷手机太久"
        ]
        guard mappings.contains(note) || mappings.map({ L10n.tr($0) }).contains(note) else {
            return note
        }
        return L10n.tr(note)
    }

    func localizedRoutineTitleIfNeeded(_ title: String, icon: String) -> String {
        let key: String?
        switch icon {
        case "iphone.slash":
            key = "放下屏幕"
        case "moon.stars":
            key = "洗漱/拉窗帘"
        case "lungs.fill":
            key = "4-7-8 呼吸"
        case "waveform":
            key = "音景渐弱"
        default:
            key = nil
        }

        guard let key else { return title }
        let candidates = [key, L10n.tr(key)]
        guard candidates.contains(title) else { return title }
        return L10n.tr(key)
    }

    func persist<T: Encodable>(_ value: T?, forKey key: String) {
        persistenceQueue.async {
            guard let value else {
                UserDefaults.standard.removeObject(forKey: key)
                return
            }

            guard let data = try? JSONEncoder().encode(value) else {
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

extension SleepStore {
    static let sampleEntries: [SleepEntry] = [
        SleepEntry(
            date: Date().addingTimeInterval(-86_400),
            mood: .refreshed,
            latencyMinutes: 18,
            wakeCount: 1,
            notes: L10n.tr("呼吸+粉噪声效果不错"),
            bedtime: Date().addingTimeInterval(-86_400 - 7.5 * 3_600),
            wakeTime: Date().addingTimeInterval(-86_400),
            stressLevel: .moderate,
            usedPhoneBeforeBed: false,
            hadLateCaffeine: false,
            hadAlcohol: false,
            settleFeedback: .yes
        ),
        SleepEntry(
            date: Date().addingTimeInterval(-2 * 86_400),
            mood: .okay,
            latencyMinutes: 28,
            wakeCount: 2,
            notes: L10n.tr("晚饭有点晚"),
            bedtime: Date().addingTimeInterval(-2 * 86_400 - 7 * 3_600),
            wakeTime: Date().addingTimeInterval(-2 * 86_400),
            stressLevel: .moderate,
            usedPhoneBeforeBed: true,
            hadLateCaffeine: false,
            hadAlcohol: false,
            settleFeedback: .somewhat
        ),
        SleepEntry(
            date: Date().addingTimeInterval(-3 * 86_400),
            mood: .tired,
            latencyMinutes: 35,
            wakeCount: 3,
            notes: L10n.tr("睡前刷手机太久"),
            bedtime: Date().addingTimeInterval(-3 * 86_400 - 6.5 * 3_600),
            wakeTime: Date().addingTimeInterval(-3 * 86_400),
            stressLevel: .high,
            usedPhoneBeforeBed: true,
            hadLateCaffeine: true,
            hadAlcohol: false,
            settleFeedback: .no
        )
    ]

    static let sampleRoutine: [RoutineStep] = [
        RoutineStep(title: L10n.tr("放下屏幕"), icon: "iphone.slash", durationMinutes: 5),
        RoutineStep(title: L10n.tr("洗漱/拉窗帘"), icon: "moon.stars", durationMinutes: 10),
        RoutineStep(title: L10n.tr("4-7-8 呼吸"), icon: "lungs.fill", durationMinutes: 4),
        RoutineStep(title: L10n.tr("音景渐弱"), icon: "waveform", durationMinutes: 30)
    ]

    static let sampleSoundscape: [SoundscapeTrack] = [
        SoundscapeTrack(title: L10n.tr("粉噪声"), description: L10n.tr("平稳遮挡环境噪音"), kind: .pinkNoise, volume: 0.7, isEnabled: true),
        SoundscapeTrack(title: L10n.tr("雨声"), description: L10n.tr("轻柔雨幕，帮助放松"), kind: .rain, volume: 0.65, isEnabled: false),
        SoundscapeTrack(title: L10n.tr("壁炉"), description: L10n.tr("噼啪火光，营造安全感"), kind: .fireplace, volume: 0.55, isEnabled: false)
    ]

    static let sampleProfile = SleepProfile(
        primaryChallenge: .stressLoad,
        preferredSound: .rain,
        preferredWindDownMinutes: 10
    )
}
