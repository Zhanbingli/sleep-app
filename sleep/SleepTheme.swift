import SwiftUI

enum SleepTheme {
    // Dark base — quiet, low-cognitive-load
    static let base = Color(red: 0.05, green: 0.07, blue: 0.12)
    static let surface = Color(red: 0.08, green: 0.10, blue: 0.16)
    static let surfaceHigh = Color(red: 0.11, green: 0.14, blue: 0.21)

    // Text
    static let ink = Color(red: 0.92, green: 0.94, blue: 0.97)
    static let mutedInk = Color(red: 0.56, green: 0.60, blue: 0.69)

    // Single muted accent + supporting tints (desaturated)
    static let accent = Color(red: 0.82, green: 0.65, blue: 0.45)
    static let teal = Color(red: 0.30, green: 0.50, blue: 0.55)
    static let indigo = Color(red: 0.22, green: 0.28, blue: 0.46)
    static let dusk = Color(red: 0.32, green: 0.39, blue: 0.52)

    // Legacy tokens retained so existing screens keep compiling.
    // `cream` stays a warm light beige because BreathingView's circle uses it
    // as a radial-gradient stop — the warm light center is intentional.
    static let cream = Color(red: 0.88, green: 0.84, blue: 0.78)
    static let haze = Color(red: 0.10, green: 0.13, blue: 0.20)

    // Subtle elevations + dividers on dark base
    static let line = Color.white.opacity(0.08)
    static let card = Color.white.opacity(0.05)
    static let softCard = Color.white.opacity(0.035)
}

struct SleepBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SleepTheme.base, SleepTheme.surface, SleepTheme.base],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(SleepTheme.indigo.opacity(0.22))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(x: -140, y: -280)

            Circle()
                .fill(SleepTheme.teal.opacity(0.14))
                .frame(width: 320, height: 320)
                .blur(radius: 100)
                .offset(x: 160, y: 320)
        }
        .ignoresSafeArea()
    }
}

struct SleepCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(SleepTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(SleepTheme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

extension View {
    func sleepCardStyle() -> some View {
        modifier(SleepCardModifier())
    }
}

struct SleepSectionHeader: View {
    let eyebrow: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.tr(eyebrow).uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundColor(SleepTheme.accent)
            Text(L10n.tr(title))
                .font(.title3.weight(.bold))
                .foregroundColor(SleepTheme.ink)
            Text(L10n.tr(detail))
                .font(.subheadline)
                .foregroundColor(SleepTheme.mutedInk)
        }
    }
}
