//
//  ContentView.swift
//  sleep
//
//  Created by lizhanbing12 on 17/11/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: SleepStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                summaryCard
                quickActions
                routinePreview
                soundscapePreview
                breathingPreview
                trendsPreview
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .navigationTitle("Sleep Assistant")
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("晚安助手")
                .font(.largeTitle).bold()
            Text("放松、音景、复盘，一站式完成")
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
        .padding(.top, 12)
    }

    private var summaryCard: some View {
        let summary = store.summary
        return NavigationLink {
            ReflectionView()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("昨晚记录")
                            .font(.headline)
                        if let last = summary.lastEntry {
                            HStack(spacing: 12) {
                                Label("\(last.latencyMinutes) 分钟入睡", systemImage: "bed.double.fill")
                                Label("\(last.wakeCount) 次醒来", systemImage: "zzz")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            Text("感受：\(last.mood.rawValue)")
                                .font(.subheadline)
                                .foregroundColor(last.mood.color)
                            if !last.notes.isEmpty {
                                Text(last.notes)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        } else {
                            Text("还没有记录，点此添加一条复盘。")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }

                Divider()
                HStack(spacing: 16) {
                    StatPill(title: "平均入睡", value: summary.averageLatency, unit: "分钟", icon: "clock")
                    StatPill(title: "平均醒来", value: summary.averageWakeCount, unit: "次", icon: "waveform.path.ecg")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速开始")
                .font(.headline)
            HStack(spacing: 12) {
                NavigationLink {
                    BreathingView()
                } label: {
                    QuickAction(title: "呼吸放松", icon: "lungs.fill", color: .teal)
                }
                NavigationLink {
                    SoundscapeView()
                } label: {
                    QuickAction(title: "音景渐弱", icon: "music.note.waveform", color: .indigo)
                }
            }
            HStack(spacing: 12) {
                NavigationLink {
                    RoutineView()
                } label: {
                    QuickAction(title: "晚间流程", icon: "checklist", color: .orange)
                }
                NavigationLink {
                    ReflectionView()
                } label: {
                    QuickAction(title: "早晨复盘", icon: "sun.and.horizon", color: .mint)
                }
            }
        }
    }

    private var routinePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("晚间流程")
                    .font(.headline)
                Spacer()
                NavigationLink("查看") { RoutineView() }
                    .font(.subheadline)
            }
            ForEach(store.routineSteps.prefix(3)) { step in
                HStack {
                    Image(systemName: step.icon)
                        .foregroundColor(step.completed ? .green : .secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.subheadline)
                        Text("\(step.durationMinutes) 分钟 · \(step.completed ? "已完成" : "待完成")")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    Spacer()
                    if step.completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    private var soundscapePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("音景")
                    .font(.headline)
                Spacer()
                NavigationLink("调整") { SoundscapeView() }
                    .font(.subheadline)
            }
            ForEach(store.soundscapeTracks.prefix(2)) { track in
                HStack {
                    Image(systemName: track.kind.icon)
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.subheadline)
                        Text(track.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if track.isEnabled {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.accentColor)
                    } else {
                        Image(systemName: "speaker.slash")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var breathingPreview: some View {
        NavigationLink {
            BreathingView()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("呼吸引导")
                        .font(.headline)
                    Text("4-7-8、盒式呼吸、共振呼吸，引导你放松")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.teal)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var trendsPreview: some View {
        let summary = store.summary
        return VStack(alignment: .leading, spacing: 12) {
            Text("趋势 · 最近 7 天")
                .font(.headline)
            HStack(spacing: 12) {
                TrendTile(title: "入睡时长", value: String(format: "%.0f 分", summary.averageLatency), icon: "clock.arrow.circlepath")
                TrendTile(title: "醒来次数", value: String(format: "%.1f 次", summary.averageWakeCount), icon: "heart.text.square")
            }
            Text("提示：保持固定起床时间，睡前减少屏幕，有助于提升效率。")
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
}

private struct QuickAction: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text("开始")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct StatPill: View {
    let title: String
    let value: Double
    let unit: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.0f", value) + " " + unit)
                .font(.headline)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct TrendTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ContentView()
            .environmentObject(SleepStore())
    }
}
