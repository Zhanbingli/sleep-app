import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: SleepStore

    @State private var selectedChallenge: SleepChallenge = .mindRacing
    @State private var selectedSound: SoundKind = .pinkNoise
    @State private var selectedWindDown = 10

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                hero
                challengeSection
                soundSection
                durationSection
                finishButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(SleepBackdrop())
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("先定你的睡前问题")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(SleepTheme.ink)
            Text("我不想做一个泛助眠工具。先告诉我你最常见的阻力，我再把今晚流程收窄到真正有用的样子。")
                .font(.subheadline)
                .foregroundColor(SleepTheme.mutedInk)
        }
        .padding(.top, 6)
    }

    private var challengeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SleepSectionHeader(
                eyebrow: "Profile",
                title: "你最常见的睡前问题是哪个？",
                detail: "只选一个最像你的主问题，先把核心路径做准。"
            )

            ForEach(SleepChallenge.allCases) { challenge in
                Button {
                    selectedChallenge = challenge
                } label: {
                    HStack(alignment: .top, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(challenge.title)
                                .font(.headline)
                                .foregroundColor(SleepTheme.ink)
                            Text(challenge.description)
                                .font(.caption)
                                .foregroundColor(SleepTheme.mutedInk)
                        }
                        Spacer()
                        Image(systemName: selectedChallenge == challenge ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedChallenge == challenge ? SleepTheme.accent : SleepTheme.mutedInk)
                    }
                    .padding(18)
                    .background(selectedChallenge == challenge ? Color.white.opacity(0.76) : SleepTheme.softCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(selectedChallenge == challenge ? SleepTheme.accent.opacity(0.45) : SleepTheme.line, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SleepSectionHeader(
                eyebrow: "Sound",
                title: "哪种声音更容易让你安静下来？",
                detail: "这会决定默认音景预设。"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SoundKind.allCases) { sound in
                        Button {
                            selectedSound = sound
                        } label: {
                            OnboardingSoundCard(
                                sound: sound,
                                isSelected: selectedSound == sound
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SleepSectionHeader(
                eyebrow: "Routine",
                title: "你愿意接受多长的睡前引导？",
                detail: "不要选理想值，选你真的愿意连续做 7 天的长度。"
            )

            HStack(spacing: 12) {
                ForEach([5, 10, 15], id: \.self) { minutes in
                    Button {
                        selectedWindDown = minutes
                    } label: {
                        Text("\(minutes) 分钟")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedWindDown == minutes ? SleepTheme.indigo : Color.white.opacity(0.56))
                            .foregroundColor(selectedWindDown == minutes ? .white : SleepTheme.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var finishButton: some View {
        Button {
            store.completeOnboarding(
                with: SleepProfile(
                    primaryChallenge: selectedChallenge,
                    preferredSound: selectedSound,
                    preferredWindDownMinutes: selectedWindDown
                )
            )
        } label: {
            VStack(spacing: 4) {
                Text("生成今晚方案")
                    .font(.headline)
                Text("之后我会根据你的复盘继续微调推荐")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.76))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [SleepTheme.indigo, SleepTheme.dusk, SleepTheme.teal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: SleepTheme.indigo.opacity(0.18), radius: 18, x: 0, y: 12)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}

private struct OnboardingSoundCard: View {
    let sound: SoundKind
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: sound.icon)
                .font(.title3.weight(.bold))
            Text(sound.displayName)
                .font(.headline)
            Text(sound.onboardingDescription)
                .font(.caption)
                .foregroundColor(SleepTheme.mutedInk)
        }
        .frame(width: 180, alignment: .topLeading)
        .frame(minHeight: 132, alignment: .topLeading)
        .padding(16)
        .background(isSelected ? Color.white.opacity(0.78) : SleepTheme.softCard)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isSelected ? SleepTheme.indigo.opacity(0.4) : SleepTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

#Preview {
    OnboardingView()
        .environmentObject(SleepStore())
}
