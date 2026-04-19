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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header
                startTonightCard
                supportCard
                secondaryActions
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showTonightStateCheck) {
            TonightStateCheckView { state in
                showTonightStateCheck = false
                activeTonightState = state
                showTonightFlow = true
            }
            .presentationDetents([.medium])
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
        .background(SleepBackdrop())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Sleep Assistant")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(SleepTheme.ink)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("晚安助手")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(SleepTheme.ink)
            Text("别把它做成工具堆。它应该像一盏柔和的夜灯，只把你带回睡眠。")
                .font(.subheadline)
                .foregroundColor(SleepTheme.mutedInk)
            Text(store.profileStatusLine)
                .font(.caption.weight(.semibold))
                .foregroundColor(SleepTheme.accent)
        }
        .padding(.top, 6)
    }

    private var startTonightCard: some View {
        let plan = store.tonightPlan
        return Button {
            showTonightStateCheck = true
        } label: {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("START TONIGHT")
                            .font(.caption.weight(.bold))
                            .tracking(1.8)
                            .foregroundColor(Color.white.opacity(0.74))
                        Text("开始今晚助眠")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("先回答一个问题，我会立刻给你今晚的降速路径。目标是更快放下手机，不是继续停留在 app 里。")
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.78))
                    }
                    Spacer()
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color.white.opacity(0.9))
                }

                HStack(spacing: 10) {
                    PlanBadge(text: "1 个状态问题", color: Color.white.opacity(0.18), foreground: .white)
                    PlanBadge(text: "1 条今晚路径", color: Color.white.opacity(0.18), foreground: .white)
                    PlanBadge(text: "目标是放下手机", color: Color.white.opacity(0.18), foreground: .white)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("今晚主线")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.68))
                        Text(plan.insight)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("开始")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                }
            }
            .padding(22)
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
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: SleepTheme.indigo.opacity(0.18), radius: 24, x: 0, y: 16)
        }
        .buttonStyle(.plain)
    }

    private var summaryCard: some View {
        let summary = store.summary
        return VStack(alignment: .leading, spacing: 16) {
            SleepSectionHeader(
                eyebrow: "Support",
                title: "今晚只保留一个动作",
                detail: "先开始流程，其他信息只用来帮你少做判断。"
            )

            HStack(spacing: 12) {
                StatTile(title: "推荐呼吸", value: store.tonightPlan.recommendedBreathing.displayName)
                StatTile(title: "渐弱时长", value: "\(store.tonightPlan.fadeMinutes) 分钟")
            }

            if let last = summary.lastEntry {
                VStack(alignment: .leading, spacing: 10) {
                    Text("昨晚反馈")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(SleepTheme.ink)

                    if let settleFeedback = last.settleFeedback {
                        MetricPill(text: settleFeedback.title, icon: "checkmark.bubble")
                    }

                    Text("入睡 \(last.latencyMinutes) 分钟 · 醒来 \(last.wakeCount) 次 · 睡了 \(String(format: "%.1f", last.sleepDurationHours)) 小时")
                        .font(.footnote)
                        .foregroundColor(SleepTheme.mutedInk)

                    if !last.habitTags.isEmpty {
                        Text(last.habitTags.joined(separator: " · "))
                            .font(.caption)
                            .foregroundColor(SleepTheme.accent)
                    }
                }
            } else {
                Text("明早花 20 秒做一次复盘，后面的推荐才会变得可靠。")
                    .font(.footnote)
                    .foregroundColor(SleepTheme.mutedInk)
            }

            HStack(spacing: 12) {
                TrendTile(title: "平均入睡", value: String(format: "%.0f 分", summary.averageLatency), accent: SleepTheme.accent)
                TrendTile(title: "更快安静下来", value: "\(Int(summary.positiveSettleRate * 100))%", accent: SleepTheme.teal)
            }
        }
        .sleepCardStyle()
    }

    private var supportCard: some View {
        summaryCard
    }

    private var secondaryActions: some View {
        HStack(spacing: 12) {
            NavigationLink {
                ReflectionView()
            } label: {
                SecondaryActionTile(
                    title: "次晨复盘",
                    detail: "记录昨晚是否更快安静下来",
                    icon: "sun.max"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                RoutineView()
            } label: {
                SecondaryActionTile(
                    title: "编辑流程",
                    detail: store.routineProgressText,
                    icon: "list.bullet.clipboard"
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct PlanBadge: View {
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

private struct MetricPill: View {
    let text: String
    let icon: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(SleepTheme.cream)
            .foregroundColor(SleepTheme.ink)
            .clipShape(Capsule())
    }
}

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(SleepTheme.mutedInk)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(SleepTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.52))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct TrendTile: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Circle()
                .fill(accent.opacity(0.2))
                .frame(width: 12, height: 12)
            Text(title)
                .font(.caption)
                .foregroundColor(SleepTheme.mutedInk)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(SleepTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.52))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SecondaryActionTile: View {
    let title: String
    let detail: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(SleepTheme.accent)
            Text(title)
                .font(.headline)
                .foregroundColor(SleepTheme.ink)
            Text(detail)
                .font(.caption)
                .foregroundColor(SleepTheme.mutedInk)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.45))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(SleepTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ContentView()
            .environmentObject(SleepStore())
    }
}
