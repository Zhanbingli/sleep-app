//
//  BreathingView.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import SwiftUI
import UIKit

struct BreathingView: View {
    private let patterns: [BreathingPattern] = [
        BreathingPattern(
            name: "4-7-8",
            description: "经典入睡放松，呼气更长帮助镇静",
            phases: [
                .init(title: "吸气", duration: 4),
                .init(title: "屏息", duration: 7),
                .init(title: "呼气", duration: 8)
            ]
        ),
        BreathingPattern(
            name: "盒式呼吸",
            description: "平衡情绪，强调均匀节奏",
            phases: [
                .init(title: "吸气", duration: 4),
                .init(title: "屏息", duration: 4),
                .init(title: "呼气", duration: 4),
                .init(title: "屏息", duration: 4)
            ]
        ),
        BreathingPattern(
            name: "共振呼吸",
            description: "5-5 节奏，提升心率变异性",
            phases: [
                .init(title: "吸气", duration: 5),
                .init(title: "呼气", duration: 5)
            ]
        )
    ]

    @State private var selectedPatternIndex: Int = 0
    @State private var phaseIndex: Int = 0
    @State private var remaining: Int = 4
    @State private var isRunning = false
    @State private var animationScale: CGFloat = 1.0
    @State private var hapticsEnabled = true
    private let ticker = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        let pattern = patterns[selectedPatternIndex]

        ScrollView {
            VStack(spacing: 24) {
                header(pattern: pattern)
                
                Picker("模式", selection: $selectedPatternIndex) {
                    ForEach(patterns.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text(patterns[index].name)
                                .font(.headline)
                            Text(patterns[index].description)
                                .font(.caption)
                        }
                        .tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedPatternIndex) { _ in
                    reset(pattern: patterns[selectedPatternIndex])
                }

                breathingCircle(pattern: pattern)

                VStack(alignment: .leading, spacing: 12) {
                    Text("当前步骤：\(currentPhase(for: pattern).title)")
                        .font(.headline)
                    Text("剩余 \(remaining) 秒")
                        .font(.title2).bold()
                        .foregroundColor(.primary)
                    Text(pattern.description)
                        .foregroundColor(.secondary)
                        .font(.body)
                }

                HStack(spacing: 16) {
                    Button(action: toggle) {
                        Label(isRunning ? "暂停" : "开始", systemImage: isRunning ? "pause.circle.fill" : "play.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: { reset(pattern: pattern) }) {
                        Label("重置", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Toggle(isOn: $hapticsEnabled) {
                    Label("节拍提示（触觉）", systemImage: "waveform.circle")
                }
                .toggleStyle(SwitchToggleStyle(tint: .teal))

                VStack(alignment: .leading, spacing: 8) {
                    Text("小贴士")
                        .font(.headline)
                    Text("呼气略长于吸气有助于让交感神经降下来。建议连续练习 3-5 分钟，并搭配音景渐弱。")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle("呼吸引导")
        .onAppear {
            reset(pattern: pattern)
        }
        .onDisappear {
            stop()
        }
        .onReceive(ticker) { _ in
            guard isRunning else { return }
            advancePhase()
        }
    }
    
    private func header(pattern: BreathingPattern) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("放松呼吸")
                .font(.largeTitle).bold()
            Text("跟随节奏，呼气比吸气略长，帮助平稳入睡")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 10) {
                Label(pattern.name, systemImage: "lungs.fill")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.teal.opacity(0.15))
                    .clipShape(Capsule())
                Label(isRunning ? "进行中" : "待开始", systemImage: isRunning ? "play.fill" : "pause")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((isRunning ? Color.green : Color.secondary).opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    private func breathingCircle(pattern: BreathingPattern) -> some View {
        let phase = currentPhase(for: pattern)
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

    private func currentPhase(for pattern: BreathingPattern) -> BreathingPattern.Phase {
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
        // ensure from the first phase when starting
        phaseIndex = 0
        remaining = patterns[selectedPatternIndex].phases.first?.duration ?? 4
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
            let phases = patterns[selectedPatternIndex].phases
            phaseIndex = (phaseIndex + 1) % phases.count
            remaining = phases[phaseIndex].duration
            sendHaptic(.phaseChange)
        }
        animateForCurrentPhase()
    }

    private func reset(pattern: BreathingPattern) {
        stop()
        phaseIndex = 0
        remaining = pattern.phases.first?.duration ?? 4
        animateForCurrentPhase()
    }

    private func animateForCurrentPhase() {
        let scale = targetScale(for: currentPhase(for: patterns[selectedPatternIndex]))
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

#Preview {
    NavigationStack {
        BreathingView()
    }
}
