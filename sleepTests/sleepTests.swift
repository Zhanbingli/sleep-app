//
//  sleepTests.swift
//  sleepTests
//
//  Created by lizhanbing12 on 17/11/25.
//

import Testing
import Foundation
@testable import sleep

@MainActor
struct sleepTests {

    // MARK: - Helpers

    private func makeStore(
        profile: SleepProfile? = nil,
        entries: [SleepEntry] = []
    ) -> SleepStore {
        let store = SleepStore()
        store.entries = entries
        store.routineSteps = []
        store.profile = profile
        return store
    }

    private func detailedEntry(
        daysAgo: Int = 1,
        latencyMinutes: Int? = 15,
        wakeCount: Int? = 1,
        usedPhone: Bool = false,
        caffeine: Bool = false,
        alcohol: Bool = false,
        stress: StressLevel = .moderate,
        settle: SettleFeedback? = .yes
    ) -> SleepEntry {
        let day: TimeInterval = 86_400
        let date = Date().addingTimeInterval(-Double(daysAgo) * day)
        return SleepEntry(
            kind: .detailed,
            date: date,
            mood: .okay,
            latencyMinutes: latencyMinutes,
            wakeCount: wakeCount,
            notes: "",
            bedtime: date.addingTimeInterval(-8 * 3_600),
            wakeTime: date,
            stressLevel: stress,
            usedPhoneBeforeBed: usedPhone,
            hadLateCaffeine: caffeine,
            hadAlcohol: alcohol,
            settleFeedback: settle
        )
    }

    private func quickEntry(daysAgo: Int, settle: SettleFeedback? = .yes) -> SleepEntry {
        let day: TimeInterval = 86_400
        return SleepEntry(
            kind: .quickCheck,
            date: Date().addingTimeInterval(-Double(daysAgo) * day),
            mood: .okay,
            latencyMinutes: nil,
            wakeCount: nil,
            settleFeedback: settle
        )
    }

    // MARK: - tonightPlan: no profile

    @Test func tonightPlanWithoutProfileUsesFallback() {
        let store = makeStore(profile: nil)
        let plan = store.tonightPlan(for: nil)
        #expect(plan.recommendedBreathing == .coherent)
        #expect(plan.recommendedSoundKind == .pinkNoise)
        #expect(plan.fadeMinutes == 30)
    }

    // MARK: - tonightPlan: profile defaults when no signals

    @Test func tonightPlanUsesProfileDefaultsWithoutSignals() {
        let profile = SleepProfile(
            primaryChallenge: .mindRacing,
            preferredSound: .rain,
            preferredWindDownMinutes: 10
        )
        let store = makeStore(profile: profile, entries: [])
        let plan = store.tonightPlan(for: nil)
        #expect(plan.recommendedBreathing == .fourSevenEight)
        #expect(plan.recommendedSoundKind == .rain)
    }

    // MARK: - tonightPlan: tonightState overrides profile

    @Test func tonightStateOverridesProfileDefaults() {
        let profile = SleepProfile(
            primaryChallenge: .mindRacing,
            preferredSound: .pinkNoise,
            preferredWindDownMinutes: 5
        )
        let store = makeStore(profile: profile)
        let plan = store.tonightPlan(for: .scrolling)
        #expect(plan.recommendedBreathing == .box)
        #expect(plan.recommendedSoundKind == .fireplace)
    }

    // MARK: - tonightPlan: high phone-use forces box breathing

    @Test func highPhoneUseRateRedirectsToBoxBreathing() {
        let profile = SleepProfile(
            primaryChallenge: .stressLoad,
            preferredSound: .fireplace,
            preferredWindDownMinutes: 10
        )
        let entries = (0..<4).map { i in
            detailedEntry(daysAgo: i + 1, latencyMinutes: 15, wakeCount: 1, usedPhone: true)
        }
        let store = makeStore(profile: profile, entries: entries)
        let plan = store.tonightPlan(for: nil)
        #expect(plan.recommendedBreathing == .box)
    }

    // MARK: - tonightPlan: high latency triggers slow-down plan

    @Test func highLatencyTriggersSlowDownPlan() {
        let profile = SleepProfile(
            primaryChallenge: .mindRacing,
            preferredSound: .pinkNoise,
            preferredWindDownMinutes: 5
        )
        let entries = (0..<3).map { i in
            detailedEntry(daysAgo: i + 1, latencyMinutes: 45, wakeCount: 0)
        }
        let store = makeStore(profile: profile, entries: entries)
        let plan = store.tonightPlan(for: nil)
        #expect(plan.recommendedBreathing == .fourSevenEight)
        #expect(plan.recommendedSoundKind == .rain)
        #expect(plan.fadeMinutes >= 35)
    }

    // MARK: - tonightPlan: high wake count triggers stability plan

    @Test func highWakeCountTriggersStabilityPlan() {
        let profile = SleepProfile(
            primaryChallenge: .mindRacing,
            preferredSound: .rain,
            preferredWindDownMinutes: 5
        )
        let entries = (0..<3).map { i in
            detailedEntry(daysAgo: i + 1, latencyMinutes: 10, wakeCount: 3)
        }
        let store = makeStore(profile: profile, entries: entries)
        let plan = store.tonightPlan(for: nil)
        #expect(plan.recommendedBreathing == .coherent)
        #expect(plan.recommendedSoundKind == .pinkNoise)
        #expect(plan.fadeMinutes >= 45)
    }

    // MARK: - tonightPlan: low settle rate pads fade, capped at 50

    @Test func lowPositiveSettleRatePadsFadeCappedAt50() {
        let profile = SleepProfile(
            primaryChallenge: .stressLoad,
            preferredSound: .rain,
            preferredWindDownMinutes: 5
        )
        let entries = (0..<3).map { i in
            detailedEntry(daysAgo: i + 1, latencyMinutes: 15, wakeCount: 1, settle: .no)
        }
        let store = makeStore(profile: profile, entries: entries)
        let plan = store.tonightPlan(for: nil)
        #expect(plan.fadeMinutes == 50)
    }

    // MARK: - Summary: empty

    @Test func summaryIsEmptyWithoutEntries() {
        let store = makeStore()
        let summary = store.summary
        #expect(summary.detailedEntryCount == 0)
        #expect(summary.averageLatency == 0)
        #expect(summary.averageWakeCount == 0)
        #expect(summary.averageSleepHours == 0)
        #expect(summary.phoneUseRate == 0)
        #expect(summary.caffeineRate == 0)
        #expect(summary.alcoholRate == 0)
        #expect(summary.highStressRate == 0)
        #expect(summary.positiveSettleRate == 0)
        #expect(summary.lastEntry == nil)
    }

    // MARK: - Summary: quick-checks do not pollute averages

    @Test func summaryAveragesIgnoreQuickChecks() {
        let store = makeStore(entries: [
            detailedEntry(daysAgo: 1, latencyMinutes: 20, wakeCount: 1),
            quickEntry(daysAgo: 2)
        ])
        let summary = store.summary
        #expect(summary.detailedEntryCount == 1)
        #expect(summary.averageLatency == 20)
        #expect(summary.averageWakeCount == 1)
    }

    // MARK: - Summary: only last seven entries

    @Test func summaryLimitsToLastSevenEntries() {
        let entries = (0..<10).map { i in
            detailedEntry(daysAgo: i + 1, latencyMinutes: 20)
        }
        let store = makeStore(entries: entries)
        #expect(store.summary.detailedEntryCount == 7)
    }

    // MARK: - Summary: positive settle rate counts quick + detailed

    @Test func positiveSettleRateCountsAcrossAllRecentEntries() {
        let store = makeStore(entries: [
            detailedEntry(daysAgo: 1, settle: .yes),
            quickEntry(daysAgo: 2, settle: .somewhat),
            quickEntry(daysAgo: 3, settle: .no)
        ])
        // 2 of 3 recent entries are yes/somewhat
        #expect(abs(store.summary.positiveSettleRate - (2.0 / 3.0)) < 0.001)
    }

    // MARK: - planConfidenceLine: progression across data states

    @Test func planConfidenceLineReflectsDetailedEntryCount() {
        // No entries at all -> profile-only phrasing
        let empty = makeStore()
        #expect(empty.planConfidenceLine.contains("画像") ||
                empty.planConfidenceLine.contains("profile") ||
                empty.planConfidenceLine.contains("Profile"))

        // Detailed count >= 5 -> line should include that count
        let entries = (0..<5).map { detailedEntry(daysAgo: $0 + 1) }
        let withFive = makeStore(entries: entries)
        #expect(withFive.planConfidenceLine.contains("5"))
    }

    // MARK: - Adaptive: yesterday's "no" settle bumps to 4-7-8

    @Test func yesterdayNegativeSettleBumpsToFourSevenEight() {
        let profile = SleepProfile(
            primaryChallenge: .lightSleep, // would normally pick coherent
            preferredSound: .pinkNoise,
            preferredWindDownMinutes: 10
        )
        let yesterday = SleepEntry(
            kind: .quickCheck,
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            mood: .okay,
            settleFeedback: .no
        )
        let store = makeStore(profile: profile, entries: [yesterday])
        let plan = store.tonightPlan(for: nil)
        #expect(plan.recommendedBreathing == .fourSevenEight)
    }

    // MARK: - Adaptive: stale negative feedback (week-old) does NOT trigger bump

    @Test func staleNegativeSettleDoesNotBump() {
        let profile = SleepProfile(
            primaryChallenge: .lightSleep,
            preferredSound: .pinkNoise,
            preferredWindDownMinutes: 10
        )
        let weekAgo = SleepEntry(
            kind: .quickCheck,
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            mood: .okay,
            settleFeedback: .no
        )
        let store = makeStore(profile: profile, entries: [weekAgo])
        let plan = store.tonightPlan(for: nil)
        // .lightSleep default is coherent and should not be overridden by a 7-day-old "no"
        #expect(plan.recommendedBreathing == .coherent)
    }

    // MARK: - Profile minimal default

    @Test func minimalDefaultProfileHasSafeFallbacks() {
        let profile = SleepProfile.minimalDefault
        #expect(profile.preferredWindDownMinutes >= 5)
        #expect(profile.preferredWindDownMinutes <= 30)
    }

    // MARK: - Entry storage round-trip

    @Test func entryStorageRoundTripsViaFile() {
        SleepEntryStorage.clearForTesting()
        defer { SleepEntryStorage.clearForTesting() }

        let entries = [detailedEntry(daysAgo: 1, latencyMinutes: 22)]
        SleepEntryStorage.save(entries)
        let loaded = SleepEntryStorage.load() ?? []
        #expect(loaded.count == 1)
        #expect(loaded.first?.latencyMinutes == 22)
    }
}
