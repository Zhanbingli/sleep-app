import Foundation

enum AppMetadata {
    // Replace these placeholders before submitting to App Store Connect.
    static let privacyPolicyURL: URL? = nil
    static let supportURL: URL? = nil
    static let supportEmail: String? = nil

    static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "sleep"
    }

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }

    static var privacyDestination: String? {
        privacyPolicyURL?.absoluteString
    }

    static var supportDestination: String? {
        if let supportURL {
            return supportURL.absoluteString
        }
        return supportEmail
    }

    static var supportLink: URL? {
        if let supportURL {
            return supportURL
        }
        guard let supportEmail else { return nil }
        return URL(string: "mailto:\(supportEmail)")
    }
}
