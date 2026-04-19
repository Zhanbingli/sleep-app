import SwiftUI
import UIKit

struct TonightFlowView: View {
    @EnvironmentObject private var store: SleepStore
    @EnvironmentObject private var engine: SoundscapeEngine
    @Environment(\.dismiss) private var dismiss

    let tonightState: TonightState

    @State private var phase: Phase = .commitment

    private enum Phase {
        case commitment, breathing, audio, phoneDown
    }

    private var plan: TonightPlan {
        store.tonightPlan(for: tonightState)
    }

    var body: some View {
        ZStack {
            SleepBackdrop()

            switch phase {
            case .commitment:
                CommitmentScreen(plan: plan, onStart: advanceToBreathing)
            case .breathing:
                TunnelBreathingScreen(
                    preset: plan.recommendedBreathing,
                    onComplete: advanceToAudio
                )
                .transition(.opacity)
            case .audio:
                AudioDescentScreen(plan: plan, onPhoneDown: advanceToPhoneDown)
                    .transition(.opacity)
            case .phoneDown:
                PhoneDownScreen(onEnd: { dismiss() })
                    .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(phase == .commitment ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            if phase == .commitment {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(SleepTheme.mutedInk)
                    }
                }
            }
        }
    }

    private func advanceToBreathing() {
        withAnimation(.easeInOut(duration: 0.6)) { phase = .breathing }
    }

    private func advanceToAudio() {
        startSoundscape()
        withAnimation(.easeInOut(duration: 0.8)) { phase = .audio }
    }

    private func advanceToPhoneDown() {
        withAnimation(.easeInOut(duration: 0.8)) { phase = .phoneDown }
    }

    private func startSoundscape() {
        if engine.isPlaying || engine.isFadingOut {
            engine.stop()
        }
        store.applyRecommendedSoundscape(kind: plan.recommendedSoundKind)
        engine.configureTracks(store.soundscapeTracks)
        engine.start()
        engine.fadeOut(duration: Double(plan.fadeMinutes) * 60)
    }
}

// MARK: - Commitment

private struct CommitmentScreen: View {
    let plan: TonightPlan
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Text("今晚 8 分钟")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundColor(SleepTheme.ink)
                Text(plan.title)
                    .font(.subheadline)
                    .foregroundColor(SleepTheme.mutedInk)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                CommitmentStep(text: "呼吸 · \(plan.recommendedBreathing.displayName)")
                CommitmentStep(text: "音景 · \(plan.recommendedSoundKind.displayName)")
                CommitmentStep(text: "把手机放下")
            }

            Spacer()

            Button(action: onStart) {
                Text("开始")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(SleepTheme.indigo)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 40)
    }
}

private struct CommitmentStep: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(SleepTheme.ink.opacity(0.85))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(SleepTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(SleepTheme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Breathing tunnel

private struct TunnelBreathingScreen: View {
    let preset: BreathingPatternPreset
    let onComplete: () -> Void

    private let totalDuration: Int = 240 // 4 minutes

    @State private var phaseIndex = 0
    @State private var remaining: Int
    @State private var elapsed: Int = 0
    @State private var isPaused = false
    @State private var animationScale: CGFloat = 0.92

    private let ticker = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    init(preset: BreathingPatternPreset, onComplete: @escaping () -> Void) {
        self.preset = preset
        self.onComplete = onComplete
        _remaining = State(initialValue: preset.pattern.phases.first?.duration ?? 4)
    }

    private var currentPhase: BreathingPattern.Phase {
        let phases = preset.pattern.phases
        return phases[phaseIndex % phases.count]
    }

    var body: some View {
        VStack {
            Text(currentPhase.title)
                .font(.subheadline.weight(.medium))
                .tracking(2)
                .foregroundColor(SleepTheme.mutedInk)
                .padding(.top, 24)

            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.18), SleepTheme.indigo.opacity(0.45)],
                            center: .center,
                            startRadius: 4,
                            endRadius: 180
                        )
                    )
                    .frame(width: 280, height: 280)
                    .scaleEffect(animationScale)
                    .animation(.easeInOut(duration: 1.0), value: animationScale)

                Text("\(remaining)")
                    .font(.system(size: 56, weight: .light, design: .rounded))
                    .foregroundColor(SleepTheme.ink)
            }

            Spacer()

            VStack(spacing: 18) {
                ProgressView(value: Double(elapsed), total: Double(totalDuration))
                    .progressViewStyle(.linear)
                    .tint(SleepTheme.accent)
                    .frame(maxWidth: 200)

                ZStack {
                    HStack {
                        Button(action: onComplete) {
                            Text("跳过")
                                .font(.caption)
                                .foregroundColor(SleepTheme.mutedInk.opacity(0.6))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 36)

                    Button { isPaused.toggle() } label: {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.title3)
                            .foregroundColor(SleepTheme.ink)
                            .frame(width: 56, height: 56)
                            .background(SleepTheme.card)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 40)
        }
        .onAppear { animateForCurrentPhase() }
        .onReceive(ticker) { _ in
            guard !isPaused else { return }
            tick()
        }
    }

    private func tick() {
        elapsed += 1
        if elapsed >= totalDuration {
            onComplete()
            return
        }
        if remaining > 1 {
            remaining -= 1
        } else {
            phaseIndex = (phaseIndex + 1) % preset.pattern.phases.count
            remaining = preset.pattern.phases[phaseIndex % preset.pattern.phases.count].duration
            UISelectionFeedbackGenerator().selectionChanged()
        }
        animateForCurrentPhase()
    }

    private func animateForCurrentPhase() {
        let scale: CGFloat = {
            switch currentPhase.title {
            case "吸气": return 1.18
            case "屏息": return 1.06
            case "呼气": return 0.82
            case "停顿": return 0.92
            default: return 1.0
            }
        }()
        withAnimation(.easeInOut(duration: 1.0)) {
            animationScale = scale
        }
    }
}

// MARK: - Audio descent

private struct AudioDescentScreen: View {
    let plan: TonightPlan
    let onPhoneDown: () -> Void

    @State private var pulse: CGFloat = 1.0

    var body: some View {
        VStack {
            Text("音景渐弱中")
                .font(.subheadline.weight(.medium))
                .tracking(2)
                .foregroundColor(SleepTheme.mutedInk)
                .padding(.top, 24)

            Spacer()

            ZStack {
                Circle()
                    .stroke(SleepTheme.indigo.opacity(0.20), lineWidth: 1)
                    .frame(width: 260, height: 260)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [SleepTheme.indigo.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 4,
                            endRadius: 180
                        )
                    )
                    .frame(width: 220, height: 220)
                    .scaleEffect(pulse)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: pulse)
            }
            .onAppear { pulse = 1.08 }

            Spacer()

            VStack(spacing: 14) {
                Text("\(plan.fadeMinutes) 分钟内自动停止")
                    .font(.footnote)
                    .foregroundColor(SleepTheme.mutedInk)

                Button(action: onPhoneDown) {
                    Text("现在放下手机")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(SleepTheme.accent.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Phone down end-state

private struct PhoneDownScreen: View {
    let onEnd: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 48))
                .foregroundColor(SleepTheme.mutedInk)
            Text("把手机放下")
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundColor(SleepTheme.ink)
            Text("音景会继续。闭眼。")
                .font(.subheadline)
                .foregroundColor(SleepTheme.mutedInk)
            Spacer()
            Button(action: onEnd) {
                Text("结束")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(SleepTheme.mutedInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(SleepTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(SleepTheme.line, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    NavigationStack {
        TonightFlowView(tonightState: .racingThoughts)
            .environmentObject(SleepStore())
            .environmentObject(SoundscapeEngine())
    }
    .preferredColorScheme(.dark)
}
