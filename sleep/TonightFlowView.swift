import SwiftUI

struct TonightFlowView: View {
    @EnvironmentObject private var store: SleepStore
    @EnvironmentObject private var engine: SoundscapeEngine

    let tonightState: TonightState

    @State private var showPhoneAwayOverlay = false

    private var plan: TonightPlan {
        store.tonightPlan(for: tonightState)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                heroCard
                routineCard
                breathingCard
                soundscapeCard
                putPhoneDownCard
                morningCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(SleepBackdrop())
        .navigationTitle("今晚助眠")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showPhoneAwayOverlay) {
            PhoneAwayView()
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TONIGHT STATE")
                .font(.caption.weight(.bold))
                .tracking(1.8)
                .foregroundColor(Color.white.opacity(0.75))
            Text(plan.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("当前状态：\(plan.stateTitle) · \(plan.detail)")
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.8))

            HStack(spacing: 10) {
                TonightBadge(text: plan.recommendedBreathing.displayName, color: Color.white.opacity(0.16), foreground: .white)
                TonightBadge(text: plan.recommendedSoundKind.displayName, color: Color.white.opacity(0.16), foreground: .white)
                TonightBadge(text: plan.focusLabel, color: Color.white.opacity(0.16), foreground: .white)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [SleepTheme.indigo, SleepTheme.dusk, SleepTheme.teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: SleepTheme.indigo.opacity(0.16), radius: 24, x: 0, y: 14)
    }

    private var routineCard: some View {
        TonightSectionCard(
            eyebrow: "Step 1",
            title: "先把环境和动作收拢",
            detail: store.routineProgressText
        ) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(store.routineSteps.prefix(4)) { step in
                    Button {
                        store.toggleRoutineStep(id: step.id)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: step.completed ? "checkmark.circle.fill" : step.icon)
                                .font(.title3)
                                .foregroundColor(step.completed ? .green : SleepTheme.mutedInk)
                                .frame(width: 26)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title)
                                    .font(.headline)
                                    .foregroundColor(SleepTheme.ink)
                                Text("\(step.durationMinutes) 分钟")
                                    .font(.caption)
                                    .foregroundColor(SleepTheme.mutedInk)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var breathingCard: some View {
        TonightSectionCard(
            eyebrow: "Step 2",
            title: "先让呼吸带走速度",
            detail: plan.recommendedBreathing.shortDescription
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(plan.recommendedBreathing.bedtimeBenefit)
                    .font(.subheadline)
                    .foregroundColor(SleepTheme.mutedInk)

                NavigationLink {
                    BreathingView(initialPreset: plan.recommendedBreathing)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("开始 \(plan.recommendedBreathing.displayName)")
                                .font(.headline)
                            Text("做 3 到 5 分钟就够，目标是明显降速。")
                                .font(.caption)
                                .foregroundColor(Color.white.opacity(0.74))
                        }
                        Spacer()
                        Image(systemName: "play.fill")
                            .font(.headline)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [SleepTheme.teal, SleepTheme.indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var soundscapeCard: some View {
        TonightSectionCard(
            eyebrow: "Step 3",
            title: "让声音慢慢退出",
            detail: "推荐 \(plan.fadeMinutes) 分钟渐弱，帮你从刺激切进更稳定的状态。"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(activeTrackSummary)
                    .font(.subheadline)
                    .foregroundColor(SleepTheme.mutedInk)

                Button {
                    startRecommendedSoundscape()
                } label: {
                    Label(engine.isPlaying ? "重启推荐音景" : "开始推荐音景", systemImage: "speaker.wave.2.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(SleepTheme.indigo)
            }
        }
    }

    private var putPhoneDownCard: some View {
        TonightSectionCard(
            eyebrow: "Step 4",
            title: "现在放下手机",
            detail: "这是整个流程最关键的一步。不要继续浏览，不要再做选择。"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text("音景和渐弱已经开始后，你真正要做的只有一件事：把手机翻过去，让身体接管后面的部分。")
                    .font(.subheadline)
                    .foregroundColor(SleepTheme.mutedInk)

                Button {
                    if !engine.isPlaying {
                        startRecommendedSoundscape()
                    }
                    showPhoneAwayOverlay = true
                } label: {
                    Text("我现在放下手机")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(SleepTheme.accent)
            }
        }
    }

    private var morningCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("明早只问一个关键问题")
                .font(.headline)
                .foregroundColor(SleepTheme.ink)
            Text("这套流程昨晚有没有帮你更快安静下来。这个反馈比任何装饰性的睡眠分数都更重要。")
                .font(.subheadline)
                .foregroundColor(SleepTheme.mutedInk)
        }
        .sleepCardStyle()
    }

    private var activeTrackSummary: String {
        let enabledTracks = store.soundscapeTracks.filter(\.isEnabled)
        guard !enabledTracks.isEmpty else {
            return "当前还没选音景，默认会启用\(plan.recommendedSoundKind.displayName)。"
        }
        return "当前已启用：\(enabledTracks.map(\.title).joined(separator: "、"))"
    }

    private func startRecommendedSoundscape() {
        if engine.isPlaying || engine.isFadingOut {
            engine.stop()
        }
        store.applyRecommendedSoundscape(kind: plan.recommendedSoundKind)
        engine.configureTracks(store.soundscapeTracks)
        engine.start()
        engine.fadeOut(duration: Double(plan.fadeMinutes) * 60)
    }
}

private struct TonightSectionCard<Content: View>: View {
    let eyebrow: String
    let title: String
    let detail: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SleepSectionHeader(eyebrow: eyebrow, title: title, detail: detail)
            content
        }
        .sleepCardStyle()
    }
}

private struct TonightBadge: View {
    let text: String
    let color: Color
    let foreground: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(color)
            .foregroundColor(foreground)
            .clipShape(Capsule())
    }
}

private struct PhoneAwayView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SleepTheme.indigo, Color.black, SleepTheme.teal.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(0.92))
                Text("现在把手机放下")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("别再看一眼。让音景继续，闭眼，把注意力交还给身体。")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)

                Button("我知道了") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(SleepTheme.accent)
                .padding(.top, 8)
            }
            .padding(24)
        }
    }
}

#Preview {
    NavigationStack {
        TonightFlowView(tonightState: .racingThoughts)
            .environmentObject(SleepStore())
            .environmentObject(SoundscapeEngine())
    }
}
