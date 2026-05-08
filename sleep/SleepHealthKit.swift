import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

/// Read-only HealthKit bridge for prefilling the morning reflection.
///
/// Stays passive: the app never writes to HealthKit, only requests permission
/// to read `sleepAnalysis` so the bedtime / wake / wake-count fields don't
/// have to be entered manually if the user already wears a tracker.
///
/// HealthKit is gated behind `canImport(HealthKit)` so the file still compiles
/// in environments where the framework is unavailable (e.g. macOS previews).
struct ImportedSleepNight: Equatable {
    var bedtime: Date
    var wakeTime: Date
    var wakeCount: Int
}

enum HealthKitImportError: Error, LocalizedError {
    case unavailable
    case notAuthorized
    case noData

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return L10n.tr("健康 App 没有昨晚的数据")
        case .notAuthorized:
            return L10n.tr("未授权访问健康数据")
        case .noData:
            return L10n.tr("健康 App 没有昨晚的数据")
        }
    }
}

@MainActor
final class SleepHealthKit {
    static let shared = SleepHealthKit()

    #if canImport(HealthKit)
    private let store = HKHealthStore()
    private var sleepType: HKCategoryType? {
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    }
    #endif

    var isAvailable: Bool {
        #if canImport(HealthKit)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
    }

    /// Asks the user once for read access to sleep analysis.
    /// Apple guarantees the system prompt only appears the first time.
    func requestAuthorization() async throws {
        #if canImport(HealthKit)
        guard isAvailable else { throw HealthKitImportError.unavailable }
        guard let sleepType else { throw HealthKitImportError.unavailable }
        try await store.requestAuthorization(toShare: [], read: [sleepType])
        #else
        throw HealthKitImportError.unavailable
        #endif
    }

    /// Fetches an `inBed`/`asleep*` summary for the most recent night and
    /// returns bedtime, wake time, and an estimated number of wake-ups.
    /// Wake count is derived from gaps between sleep samples, which is a
    /// rough proxy but matches what users get from the Health app's UI.
    func importLastNight() async throws -> ImportedSleepNight {
        #if canImport(HealthKit)
        guard isAvailable, let sleepType else {
            throw HealthKitImportError.unavailable
        }

        let calendar = Calendar.current
        let now = Date()
        // Look at the last 18 hours so we catch a night that ended this morning,
        // even if the user opens the app early afternoon.
        let start = calendar.date(byAdding: .hour, value: -18, to: now) ?? now.addingTimeInterval(-64_800)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: [])

        let samples: [HKCategorySample] = try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let categorySamples = (results as? [HKCategorySample]) ?? []
                continuation.resume(returning: categorySamples)
            }
            store.execute(query)
        }

        guard !samples.isEmpty else {
            throw HealthKitImportError.noData
        }

        let asleepValues: Set<Int> = Self.asleepValues
        let asleepSamples = samples.filter { asleepValues.contains($0.value) }

        // Fall back to all samples if there's no explicit "asleep" value
        // (older watchOS versions only report `inBed`).
        let usable = asleepSamples.isEmpty ? samples : asleepSamples
        guard let firstStart = usable.map(\.startDate).min(),
              let lastEnd = usable.map(\.endDate).max() else {
            throw HealthKitImportError.noData
        }

        let wakeCount = Self.estimateWakeCount(in: usable)

        return ImportedSleepNight(
            bedtime: firstStart,
            wakeTime: lastEnd,
            wakeCount: wakeCount
        )
        #else
        throw HealthKitImportError.unavailable
        #endif
    }

    #if canImport(HealthKit)
    // Deployment target is iOS 16, where the legacy `.asleep` value was
    // replaced by stage-specific values plus `.asleepUnspecified`.
    private static let asleepValues: Set<Int> = [
        HKCategoryValueSleepAnalysis.asleepCore.rawValue,
        HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
        HKCategoryValueSleepAnalysis.asleepREM.rawValue,
        HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
    ]

    /// Counts gaps ≥10 minutes between consecutive asleep samples as wake-ups.
    private static func estimateWakeCount(in samples: [HKCategorySample]) -> Int {
        guard samples.count >= 2 else { return 0 }
        let sorted = samples.sorted { $0.startDate < $1.startDate }
        var wakes = 0
        for index in 1..<sorted.count {
            let gap = sorted[index].startDate.timeIntervalSince(sorted[index - 1].endDate)
            if gap >= 600 { wakes += 1 }
        }
        return wakes
    }
    #endif
}
