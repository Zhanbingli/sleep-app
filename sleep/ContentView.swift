//
//  ContentView.swift
//  sleep
//
//  Created by lizhanbing12 on 17/11/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: SleepStore
    @State private var showTonightStateCheck = false
    @State private var activeTonightState: TonightState?
    @State private var showTonightFlow = false

    var body: some View {
        ZStack(alignment: .top) {
            SleepBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    greeting
                    startTonightCTA
                    sequencePreview
                    lastNightLine
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showTonightStateCheck) {
            TonightStateCheckView { state in
                showTonightStateCheck = false
                activeTonightState = state
                showTonightFlow = true
            }
            .presentationDetents([.medium, .large])
        }
        .navigationDestination(isPresented: $showTonightFlow) {
            Group {
                if let activeTonightState {
                    TonightFlowView(tonightState: activeTonightState)
                } else {
                    EmptyView()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("今晚")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SleepTheme.mutedInk)
            }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(timeBasedGreeting)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundColor(SleepTheme.ink)
            Text("准备好慢下来了吗？")
                .font(.subheadline)
                .foregroundColor(SleepTheme.mutedInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var startTonightCTA: some View {
        let plan = store.tonightPlan
        return Button {
            showTonightStateCheck = true
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("今晚开始")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "moon.zzz.fill")
                        .font(.title3)
                        .foregroundColor(Color.white.opacity(0.72))
                }
                Text("约 \(estimatedMinutes) 分钟")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.white.opacity(0.82))
                Text(plan.insight)
                    .font(.footnote)
                    .foregroundColor(Color.white.opacity(0.64))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [SleepTheme.indigo, SleepTheme.surfaceHigh],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var sequencePreview: some View {
        let plan = store.tonightPlan
        return VStack(alignment: .leading, spacing: 10) {
            Text("今晚顺序")
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundColor(SleepTheme.mutedInk)
            SequenceRow(index: 1, title: plan.recommendedBreathing.displayName, detail: "约 4 分钟")
            SequenceRow(index: 2, title: plan.recommendedSoundKind.displayName, detail: "\(plan.fadeMinutes) 分钟渐弱")
            SequenceRow(index: 3, title: "把手机放下", detail: "结束流程")
        }
    }

    private var lastNightLine: some View {
        Group {
            if let last = store.summary.lastEntry, let feedback = last.settleFeedback {
                Text("昨晚 · \(feedback.title)")
                    .font(.footnote)
                    .foregroundColor(SleepTheme.mutedInk)
            } else {
                Text("明早花 20 秒做一次复盘。")
                    .font(.footnote)
                    .foregroundColor(SleepTheme.mutedInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 18..<24, 0..<4: return "晚安"
        case 4..<11: return "早上好"
        default: return "下午好"
        }
    }

    private var estimatedMinutes: Int {
        // Active app time before phone-down: breathing ~4 + transitions ~4.
        8
    }
}

private struct SequenceRow: View {
    let index: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            Text("\(index)")
                .font(.footnote.weight(.bold))
                .foregroundColor(SleepTheme.mutedInk)
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.05))
                .clipShape(Circle())
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(SleepTheme.ink)
            Spacer()
            Text(detail)
                .font(.caption)
                .foregroundColor(SleepTheme.mutedInk)
        }
        .padding(.vertical, 4)
    }
}

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ContentView()
            }
            .tabItem { Label("今晚", systemImage: "moon.zzz.fill") }

            NavigationStack {
                ReflectionView()
            }
            .tabItem { Label("次晨", systemImage: "sun.max.fill") }

            NavigationStack {
                LibraryView()
            }
            .tabItem { Label("更多", systemImage: "line.3.horizontal") }
        }
        .tint(SleepTheme.accent)
    }
}

private struct LibraryView: View {
    var body: some View {
        ZStack(alignment: .top) {
            SleepBackdrop()

            VStack(spacing: 12) {
                NavigationLink {
                    BreathingView()
                } label: {
                    LibraryRow(title: "呼吸", detail: "快速做一段共振呼吸", icon: "lungs.fill")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    RoutineView()
                } label: {
                    LibraryRow(title: "睡前流程", detail: "编辑固定动作", icon: "list.bullet.clipboard")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    SoundscapeView()
                } label: {
                    LibraryRow(title: "音景", detail: "切换默认音景", icon: "waveform")
                }
                .buttonStyle(.plain)

                NavigationLink {
                    SleepHistoryView()
                } label: {
                    LibraryRow(title: "历史", detail: "查看过去几晚", icon: "calendar")
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("更多")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SleepTheme.mutedInk)
            }
        }
    }
}

private struct LibraryRow: View {
    let title: String
    let detail: String
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(SleepTheme.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(SleepTheme.ink)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(SleepTheme.mutedInk)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundColor(SleepTheme.mutedInk)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(SleepTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SleepTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ContentView()
            .environmentObject(SleepStore())
    }
    .preferredColorScheme(.dark)
}
