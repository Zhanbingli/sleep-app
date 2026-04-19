//
//  BreathingView.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import SwiftUI
import UIKit

struct BreathingView: View {
    private let preset: BreathingPatternPreset

    @State private var phaseIndex = 0
    @State private var remaining: Int
    @State private var isRunning = false
    @State private var animationScale: CGFloat = 0.92

    private let ticker = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    init(initialPreset: BreathingPatternPreset = .coherent) {
        self.preset = initialPreset
        _remaining = State(initialValue: initialPreset.pattern.phases.first?.duration ?? 4)
    }

    private var pattern: BreathingPattern { preset.pattern }
    private var currentPhase: BreathingPattern.Phase {
        pattern.phases[phaseIndex % pattern.phases.count]
    }

    var body: some View {
        ZStack {
            SleepBackdrop()

            VStack {
                Text(currentPhase.title)
                    .font(.subheadline.weight(.medium))
                    .tracking(2)
                    .foregroundColor(SleepTheme.mutedInk)
                    .padding(.top, 16)

                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.16), SleepTheme.indigo.opacity(0.45)],
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

                Button {
                    isRunning.toggle()
                    if isRunning {
                        animateForCurrentPhase()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(SleepTheme.ink)
                        .frame(width: 64, height: 64)
                        .background(SleepTheme.card)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("呼吸")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { animateForCurrentPhase() }
        .onDisappear { isRunning = false }
        .onReceive(ticker) { _ in
            guard isRunning else { return }
            tick()
        }
    }

    private func tick() {
        if remaining > 1 {
            remaining -= 1
        } else {
            phaseIndex = (phaseIndex + 1) % pattern.phases.count
            remaining = pattern.phases[phaseIndex % pattern.phases.count].duration
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

#Preview {
    NavigationStack {
        BreathingView()
    }
    .preferredColorScheme(.dark)
}
