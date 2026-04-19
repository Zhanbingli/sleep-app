//
//  BreathingView.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import SwiftUI
import UIKit

struct BreathingView: View {
    private let initialPreset: BreathingPatternPreset

    @State private var selectedPreset: BreathingPatternPreset
    @State private var phaseIndex = 0
    @State private var remaining: Int
    @State private var completedCycles = 0
    @State private var isRunning = false
    @State private var animationScale: CGFloat = 1.0
    @State private var hapticsEnabled = true

    private let ticker = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    init(initialPreset: BreathingPatternPreset = .fourSevenEight) {
        self.initialPreset = initialPreset
        _selectedPreset = State(initialValue: initialPreset)
        _remaining = State(initialValue: initialPreset.pattern.phases.first?.duration ?? 4)
    }

    private var pattern: BreathingPattern {
        selectedPreset.pattern
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
                presetPicker
                breathingStage
                controlPanel
                tipsCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(breathingBackdrop)
        .navigationTitle("呼吸引导")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            reset(for: initialPreset)
        }
        .onDisappear {
            stop()
        }
        .onReceive(ticker) { _ in
            guard isRunning else { return }
            advancePhase()
        }
        .onChange(of: selectedPreset, perform: { newValue in
            reset(for: newValue)
        })
    }

    private var breathingBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [SleepTheme.indigo, Color(red: 0.18, green: 0.22, blue: 0.30), SleepTheme.teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 10)
                .offset(x: 120, y: -260)

            Circle()
                .fill(SleepTheme.accent.opacity(0.14))
                .frame(width: 220, height: 220)
                .blur(radius: 18)
                .offset(x: -150, y: 220)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("先让身体降速")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(selectedPreset.shortDescription)
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.74))

            HStack(spacing: 10) {
                BreathingStatusPill(text: selectedPreset.displayName, color: Color.white.opacity(0.14), foreground: .white)
                BreathingStatusPill(text: isRunning ? "进行中" : "待开始", color: isRunning ? SleepTheme.teal.opacity(0.28) : Color.white.opacity(0.12), foreground: .white)
                if completedCycles > 0 {
                    BreathingStatusPill(text: "已完成 \(completedCycles) 轮", color: SleepTheme.accent.opacity(0.24), foreground: .white)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var presetPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BreathingPatternPreset.allCases) { preset in
                    Button {
                        selectedPreset = preset
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(preset.displayName)
                                .font(.headline)
                            Text(preset.shortDescription)
                                .font(.caption)
                                .foregroundColor(selectedPreset == preset ? Color.white.opacity(0.76) : Color.white.opacity(0.62))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(16)
                        .frame(width: 190, alignment: .leading)
                        .background(selectedPreset == preset ? Color.white.opacity(0.16) : Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(selectedPreset == preset ? Color.white.opacity(0.36) : Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var breathingStage: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    .frame(width: 282, height: 282)
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 22)
                    .frame(width: 244, height: 244)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.92), SleepTheme.cream, SleepTheme.accent.opacity(0.58)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 160
                        )
                    )
                    .frame(width: 214, height: 214)
                    .scaleEffect(animationScale)
                    .animation(.easeInOut(duration: 1.0), value: animationScale)

                VStack(spacing: 8) {
                    Text(currentPhase.title)
                        .font(.title.weight(.bold))
                        .foregroundColor(SleepTheme.ink)
                    Text("\(remaining)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(SleepTheme.indigo)
                }
            }
            .frame(maxWidth: .infinity)

            Text(pattern.description)
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.72))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("当前步骤")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Color.white.opacity(0.64))
                Text(selectedPreset.bedtimeBenefit)
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.82))
            }

            HStack(spacing: 12) {
                Button(action: toggle) {
                    Label(isRunning ? "暂停" : "开始", systemImage: isRunning ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(SleepTheme.accent)

                Button(action: { reset(for: selectedPreset) }) {
                    Label("重置", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }

            Toggle(isOn: $hapticsEnabled) {
                Label("节拍提示（触觉）", systemImage: "waveform.circle")
                    .foregroundColor(.white)
            }
            .toggleStyle(SwitchToggleStyle(tint: SleepTheme.accent))
        }
        .padding(20)
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今晚建议")
                .font(.headline)
                .foregroundColor(.white)
            Text("练习 3 到 5 分钟即可。呼吸结束后立刻切到音景渐弱，比停下来重新思考更重要。")
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.72))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var currentPhase: BreathingPattern.Phase {
        let phases = pattern.phases
        guard phaseIndex < phases.count else { return phases.first! }
        return phases[phaseIndex]
    }

    private func toggle() {
        isRunning.toggle()
        if isRunning {
            animateForCurrentPhase()
            sendHaptic(.start)
        }
    }

    private func stop() {
        isRunning = false
    }

    private func advancePhase() {
        if remaining > 1 {
            remaining -= 1
        } else {
            let phases = pattern.phases
            let nextIndex = (phaseIndex + 1) % phases.count
            if nextIndex == 0 {
                completedCycles += 1
            }
            phaseIndex = nextIndex
            remaining = phases[phaseIndex].duration
            sendHaptic(.phaseChange)
        }
        animateForCurrentPhase()
    }

    private func reset(for preset: BreathingPatternPreset) {
        stop()
        selectedPreset = preset
        phaseIndex = 0
        completedCycles = 0
        remaining = preset.pattern.phases.first?.duration ?? 4
        animateForCurrentPhase()
    }

    private func animateForCurrentPhase() {
        let scale = targetScale(for: currentPhase)
        withAnimation(.easeInOut(duration: 1.0)) {
            animationScale = scale
        }
    }

    private func targetScale(for phase: BreathingPattern.Phase) -> CGFloat {
        switch phase.title {
        case "吸气":
            return 1.14
        case "屏息":
            return 1.02
        case "呼气":
            return 0.88
        case "停顿":
            return 0.94
        default:
            return 1.0
        }
    }

    private enum HapticKind {
        case start
        case phaseChange
    }

    private func sendHaptic(_ kind: HapticKind) {
        guard hapticsEnabled else { return }
        switch kind {
        case .start:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .phaseChange:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

private struct BreathingStatusPill: View {
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

#Preview {
    NavigationStack {
        BreathingView()
    }
}
