import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: SleepStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedChallenge: SleepChallenge = .mindRacing
    @State private var selectedSound: SoundKind = .pinkNoise
    @State private var selectedWindDown = 10

    private let isEditingProfile: Bool

    init(initialProfile: SleepProfile? = nil) {
        self.isEditingProfile = initialProfile != nil
        _selectedChallenge = State(initialValue: initialProfile?.primaryChallenge ?? .mindRacing)
        _selectedSound = State(initialValue: initialProfile?.preferredSound ?? .pinkNoise)
        _selectedWindDown = State(initialValue: initialProfile?.preferredWindDownMinutes ?? 10)
    }

    var body: some View {
        ZStack {
            SleepBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    hero
                    challengeSection
                    soundSection
                    durationSection
                    finishButton
                    if !isEditingProfile {
                        skipForNowButton
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 36)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isEditingProfile ? "更新你的睡前画像" : "先告诉我你的睡前问题")
                .font(.system(size: 30, weight: .semibold, design: .rounded))
                .foregroundColor(SleepTheme.ink)
            Text(isEditingProfile ? "改完后，今晚流程和推荐音景会一起更新。" : "我会据此把今晚流程收窄到最有用的样子。")
                .font(.subheadline)
                .foregroundColor(SleepTheme.mutedInk)
        }
    }

    private var challengeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "你的主要问题")
            VStack(spacing: 10) {
                ForEach(SleepChallenge.allCases) { challenge in
                    SelectableRow(
                        title: challenge.title,
                        isSelected: selectedChallenge == challenge,
                        action: { selectedChallenge = challenge }
                    )
                }
            }
        }
    }

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "你更容易在哪种声音里安静下来")
            HStack(spacing: 10) {
                ForEach(SoundKind.allCases) { sound in
                    SoundChip(
                        sound: sound,
                        isSelected: selectedSound == sound,
                        action: { selectedSound = sound }
                    )
                }
            }
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "每晚愿意做多久")
            HStack(spacing: 10) {
                ForEach([5, 10, 15], id: \.self) { minutes in
                    DurationChip(
                        minutes: minutes,
                        isSelected: selectedWindDown == minutes,
                        action: { selectedWindDown = minutes }
                    )
                }
            }
        }
    }

    private var finishButton: some View {
        Button {
            let profile = SleepProfile(
                primaryChallenge: selectedChallenge,
                preferredSound: selectedSound,
                preferredWindDownMinutes: selectedWindDown
            )
            if isEditingProfile {
                store.updateProfile(profile)
                dismiss()
            } else {
                store.completeOnboarding(with: profile)
            }
        } label: {
            Text(isEditingProfile ? "保存偏好" : "生成今晚方案")
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(SleepTheme.indigo)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    private var skipForNowButton: some View {
        Button {
            store.completeOnboarding(with: SleepProfile.minimalDefault)
        } label: {
            Text("先用默认设置开始")
                .font(.footnote)
                .foregroundColor(SleepTheme.mutedInk)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

private struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(L10n.tr(text))
            .font(.caption.weight(.semibold))
            .tracking(1.4)
            .foregroundColor(SleepTheme.mutedInk)
    }
}

private struct SelectableRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(L10n.tr(title))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(isSelected ? SleepTheme.ink : SleepTheme.ink.opacity(0.78))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(SleepTheme.accent)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(isSelected ? SleepTheme.accent.opacity(0.18) : SleepTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? SleepTheme.accent.opacity(0.55) : SleepTheme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SoundChip: View {
    let sound: SoundKind
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: sound.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? SleepTheme.accent : SleepTheme.mutedInk)
                Text(sound.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SleepTheme.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(isSelected ? SleepTheme.accent.opacity(0.18) : SleepTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? SleepTheme.accent.opacity(0.55) : SleepTheme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct DurationChip: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(L10n.format("%d 分钟", minutes))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(SleepTheme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? SleepTheme.accent.opacity(0.18) : SleepTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? SleepTheme.accent.opacity(0.55) : SleepTheme.line, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(SleepStore())
        .preferredColorScheme(.dark)
}
