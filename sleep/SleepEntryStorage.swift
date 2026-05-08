import Foundation

/// File-based atomic storage for `SleepEntry` records.
///
/// Lives separately from `UserDefaults` because the entry list is the only
/// collection that grows unboundedly with use; the per-record JSON also tends
/// to be the largest blob the app persists. Other small settings (profile,
/// routine, soundscape, fade) stay in `UserDefaults` where size and write
/// frequency are negligible.
///
/// On first use the loader migrates any pre-existing `UserDefaults` blob (key
/// `sleep.entries`) into the file, then clears the legacy key so writes don't
/// double up afterwards.
enum SleepEntryStorage {
    private static let fileName = "sleep-entries.json"
    private static let legacyUserDefaultsKey = "sleep.entries"

    private static var fileURL: URL? {
        let fm = FileManager.default
        guard let baseDir = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        return baseDir.appendingPathComponent(fileName, isDirectory: false)
    }

    static func load() -> [SleepEntry]? {
        guard let url = fileURL else {
            return loadFromLegacyUserDefaults()
        }

        if FileManager.default.fileExists(atPath: url.path) {
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode([SleepEntry].self, from: data)
        }

        // First launch on this storage version: pull anything left in
        // UserDefaults forward, then delete the legacy key.
        if let migrated = loadFromLegacyUserDefaults() {
            try? saveSync(migrated)
            UserDefaults.standard.removeObject(forKey: legacyUserDefaultsKey)
            return migrated
        }

        return nil
    }

    static func save(_ entries: [SleepEntry]) {
        guard let url = fileURL else { return }
        let data: Data
        do {
            data = try JSONEncoder().encode(entries)
        } catch {
            print("Warning: failed to encode entries: \(error)")
            return
        }
        // Atomic write avoids partial files if the app is killed mid-write.
        do {
            try data.write(to: url, options: [.atomic])
        } catch {
            print("Warning: failed to persist entries: \(error)")
        }
    }

    private static func saveSync(_ entries: [SleepEntry]) throws {
        guard let url = fileURL else { return }
        let data = try JSONEncoder().encode(entries)
        try data.write(to: url, options: [.atomic])
    }

    private static func loadFromLegacyUserDefaults() -> [SleepEntry]? {
        guard let data = UserDefaults.standard.data(forKey: legacyUserDefaultsKey) else {
            return nil
        }
        return try? JSONDecoder().decode([SleepEntry].self, from: data)
    }

    /// Test-only hook for resetting state between unit tests.
    static func clearForTesting() {
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        UserDefaults.standard.removeObject(forKey: legacyUserDefaultsKey)
    }
}
