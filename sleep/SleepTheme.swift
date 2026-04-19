import SwiftUI

enum SleepTheme {
    static let ink = Color(red: 0.17, green: 0.22, blue: 0.32)
    static let mutedInk = Color(red: 0.39, green: 0.44, blue: 0.53)
    static let cream = Color(red: 0.97, green: 0.94, blue: 0.89)
    static let haze = Color(red: 0.87, green: 0.91, blue: 0.93)
    static let dusk = Color(red: 0.50, green: 0.61, blue: 0.69)
    static let accent = Color(red: 0.77, green: 0.49, blue: 0.32)
    static let teal = Color(red: 0.35, green: 0.52, blue: 0.53)
    static let indigo = Color(red: 0.28, green: 0.35, blue: 0.52)
    static let line = Color.white.opacity(0.55)
    static let card = Color.white.opacity(0.7)
    static let softCard = Color.white.opacity(0.52)
}

struct SleepBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SleepTheme.cream, SleepTheme.haze, Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(SleepTheme.accent.opacity(0.17))
                .frame(width: 220, height: 220)
                .blur(radius: 18)
                .offset(x: 120, y: -260)

            Circle()
                .fill(SleepTheme.teal.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 26)
                .offset(x: -150, y: 300)

            Circle()
                .fill(SleepTheme.indigo.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 34)
                .offset(x: 120, y: 360)
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
            .shadow(color: SleepTheme.indigo.opacity(0.08), radius: 18, x: 0, y: 12)
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
            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundColor(SleepTheme.accent)
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundColor(SleepTheme.ink)
            Text(detail)
                .font(.subheadline)
                .foregroundColor(SleepTheme.mutedInk)
        }
    }
}
