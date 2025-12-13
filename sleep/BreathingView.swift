//
//  BreathingView.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import SwiftUI
import UIKit

struct BreathingView: View {
    private let pattern = BreathingPattern(
        name: "4-7-8",
        description: "经典入睡放松，呼气更长帮助镇静",
        phases: [
            .init(title: "吸气", duration: 4),
            .init(title: "屏息", duration: 7),
            .init(title: "呼气", duration: 8)
        ]
    )

    @State private var phaseIndex: Int = 0
    @State private var remaining: Int = 4
    @State private var isRunning = false
    @State private var animationScale: CGFloat = 1.0
    @State private var hapticsEnabled = true
    private let ticker = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.teal.opacity(0.15), Color.blue.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    header()

                    breathingCircle()

                    infoPanel()

                    controlButtons()

                    Toggle(isOn: $hapticsEnabled) {
                        Label("节拍提示（触觉）", systemImage: "waveform.circle")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .teal))
                    .padding(.horizontal)

                    tipsCard()
                }
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("呼吸引导")
        .onAppear {
            reset()
        }
        .onDisappear {
            stop()
        }
        .onReceive(ticker) { _ in
            guard isRunning else { return }
            advancePhase()
        }
    }
    
    private func header() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("4-7-8 放松呼吸")
                .font(.largeTitle).bold()
            Text("呼气更长，降低紧张感，助眠入睡")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 10) {
                StatusPill(text: pattern.name, color: .teal)
                StatusPill(text: isRunning ? "进行中" : "待开始", color: isRunning ? .green : .secondary)
            }
        }
        .padding(.horizontal)
    }

    private func infoPanel() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("当前步骤", systemImage: "lungs.fill")
                    .font(.headline)
                Spacer()
                StatusPill(text: currentPhase().title, color: .teal)
            }
            Text("剩余 \(remaining) 秒")
                .font(.title2).bold()
            Text(pattern.description)
                .foregroundColor(.secondary)
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }

    private func controlButtons() -> some View {
        HStack(spacing: 16) {
            Button(action: toggle) {
                Label(isRunning ? "暂停" : "开始", systemImage: isRunning ? "pause.circle.fill" : "play.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button(action: { reset() }) {
                Label("重置", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }

    private func tipsCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("小贴士")
                .font(.headline)
            Text("呼气略长于吸气有助于让交感神经降下来。建议连续练习 3-5 分钟，并搭配音景渐弱。")
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal)
    }

    private func breathingCircle() -> some View {
        let phase = currentPhase()
        return ZStack {
            Circle()
                .stroke(Color.teal.opacity(0.25), lineWidth: 18)
                .frame(width: 260, height: 260)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.teal.opacity(0.9), Color.cyan.opacity(0.7)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 160
                    )
                )
                .frame(width: 230, height: 230)
                .scaleEffect(animationScale)
                .animation(.easeInOut(duration: 1.0), value: animationScale)
            VStack(spacing: 6) {
                Text(phase.title)
                    .font(.title2).bold()
                    .foregroundColor(.white)
                Text("请跟随节奏")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    private func targetScale(for phase: BreathingPattern.Phase) -> CGFloat {
        switch phase.title {
        case "吸气": return 1.14
        case "屏息": return 1.02
        case "呼气": return 0.9
        default: return 1.0
        }
    }

    private func currentPhase() -> BreathingPattern.Phase {
        let phases = pattern.phases
        if phaseIndex >= phases.count { return phases.first! }
        return phases[phaseIndex]
    }

    private func toggle() {
        isRunning.toggle()
        if isRunning {
            start()
        } else {
            stop()
        }
    }

    private func start() {
        phaseIndex = 0
        remaining = pattern.phases.first?.duration ?? 4
        isRunning = true
        // Start immediately to give feedback.
        animateForCurrentPhase()
        sendHaptic(.start)
    }

    private func stop() {
        isRunning = false
    }

    private func advancePhase() {
        if remaining > 1 {
            remaining -= 1
        } else {
            let phases = pattern.phases
            phaseIndex = (phaseIndex + 1) % phases.count
            remaining = phases[phaseIndex].duration
            sendHaptic(.phaseChange)
        }
        animateForCurrentPhase()
    }

    private func reset() {
        stop()
        phaseIndex = 0
        remaining = pattern.phases.first?.duration ?? 4
        animateForCurrentPhase()
    }

    private func animateForCurrentPhase() {
        let scale = targetScale(for: currentPhase())
        withAnimation(.easeInOut(duration: 1.0)) {
            animationScale = scale
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

private struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        BreathingView()
    }
}
