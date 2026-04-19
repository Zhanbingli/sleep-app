//
//  ReflectionView.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import SwiftUI

// MARK: - Morning quick log (3 taps max)

struct ReflectionView: View {
    @EnvironmentObject private var store: SleepStore
    @State private var didLog = false
    @State private var loggedFeedback: SettleFeedback?

    var body: some View {
        ZStack {
            SleepBackdrop()

            if didLog, let feedback = loggedFeedback {
                ConfirmationView(feedback: feedback) {
                    didLog = false
                    loggedFeedback = nil
                }
            } else {
                MorningPrompt(onLog: log)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("次晨")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SleepTheme.mutedInk)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    ReflectionDetailView()
                } label: {
                    Text("详细")
                        .font(.caption)
                        .foregroundColor(SleepTheme.mutedInk)
                }
            }
        }
    }

    private func log(feedback: SettleFeedback, issue: MorningIssue?) {
        var entry = SleepEntry(
            kind: .quickCheck,
            mood: .okay,
            settleFeedback: feedback
        )
        if let issue {
            switch issue {
            case .racingThoughts:
                entry.stressLevel = .high
                entry.notes = issue.title
            case .wokeUp:
                entry.wakeCount = 2
                entry.notes = issue.title
            case .usedPhone:
                entry.usedPhoneBeforeBed = true
                entry.notes = issue.title
            case .notTired:
                entry.mood = .tired
                entry.notes = issue.title
            }
        }
        store.addEntry(entry)
        loggedFeedback = feedback
        withAnimation(.easeInOut(duration: 0.4)) {
            didLog = true
        }
    }
}

private enum MorningIssue: String, CaseIterable, Identifiable {
    case racingThoughts, wokeUp, usedPhone, notTired

    var id: String { rawValue }

    var title: String {
        switch self {
        case .racingThoughts: return L10n.tr("脑子停不下来")
        case .wokeUp: return L10n.tr("醒了")
        case .usedPhone: return L10n.tr("又用手机")
        case .notTired: return L10n.tr("不困")
        }
    }
}

private struct MorningPrompt: View {
    let onLog: (SettleFeedback, MorningIssue?) -> Void

    @State private var selectedIssue: MorningIssue?

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 8) {
                Text("昨晚")
                    .font(.subheadline.weight(.medium))
                    .tracking(2)
                    .foregroundColor(SleepTheme.mutedInk)
                Text("有更快安静下来吗？")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundColor(SleepTheme.ink)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                FeedbackChip(title: "有") { onLog(.yes, selectedIssue) }
                FeedbackChip(title: "有一点") { onLog(.somewhat, selectedIssue) }
                FeedbackChip(title: "没有") { onLog(.no, selectedIssue) }
            }

            VStack(spacing: 10) {
                Text("可选 · 主要原因")
                    .font(.caption)
                    .foregroundColor(SleepTheme.mutedInk)
                FlowingChips(items: MorningIssue.allCases) { issue in
                    IssueChip(issue: issue, isSelected: selectedIssue == issue) {
                        if selectedIssue == issue {
                            selectedIssue = nil
                        } else {
                            selectedIssue = issue
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

private struct FeedbackChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(L10n.tr(title))
                .font(.headline.weight(.semibold))
                .foregroundColor(SleepTheme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(SleepTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(SleepTheme.line, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct IssueChip: View {
    let issue: MorningIssue
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(issue.title)
                .font(.caption)
                .foregroundColor(isSelected ? SleepTheme.ink : SleepTheme.mutedInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? SleepTheme.accent.opacity(0.25) : SleepTheme.card)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? SleepTheme.accent.opacity(0.55) : SleepTheme.line, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct FlowingChips<Item: Identifiable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        // Two rows of two for compact display on small phones.
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}

private struct ConfirmationView: View {
    let feedback: SettleFeedback
    let onChange: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(SleepTheme.accent)
                .frame(width: 56, height: 56)
                .background(SleepTheme.card)
                .clipShape(Circle())
            Text("已记录")
                .font(.title3.weight(.semibold))
                .foregroundColor(SleepTheme.ink)
            Text(L10n.format("昨晚 · %@", feedback.title))
                .font(.subheadline)
                .foregroundColor(SleepTheme.mutedInk)
            Text("这次只记录了主观反馈，补一条详细复盘后趋势会更准。")
                .font(.footnote)
                .foregroundColor(SleepTheme.mutedInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button(action: onChange) {
                Text("再选一次")
                    .font(.caption)
                    .foregroundColor(SleepTheme.mutedInk)
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Detailed editor (used for editing past entries from history)

struct ReflectionDetailView: View {
    @EnvironmentObject private var store: SleepStore
    @Environment(\.dismiss) private var dismiss

    private let existingEntry: SleepEntry?

    @State private var date: Date
    @State private var mood: Mood
    @State private var latency: Double
    @State private var wakeCount: Int
    @State private var notes: String
    @State private var bedtime: Date
    @State private var wakeTime: Date
    @State private var stressLevel: StressLevel
    @State private var usedPhoneBeforeBed: Bool
    @State private var hadLateCaffeine: Bool
    @State private var hadAlcohol: Bool
    @State private var settleFeedback: SettleFeedback

    init(existingEntry: SleepEntry? = nil) {
        self.existingEntry = existingEntry
        _date = State(initialValue: existingEntry?.date ?? Date())
        _mood = State(initialValue: existingEntry?.mood ?? .okay)
        _latency = State(initialValue: Double(existingEntry?.latencyMinutes ?? 20))
        _wakeCount = State(initialValue: existingEntry?.wakeCount ?? 1)
        _notes = State(initialValue: existingEntry?.notes ?? "")
        _bedtime = State(initialValue: existingEntry?.bedtime ?? Date().addingTimeInterval(-8 * 3_600))
        _wakeTime = State(initialValue: existingEntry?.wakeTime ?? Date())
        _stressLevel = State(initialValue: existingEntry?.stressLevel ?? .moderate)
        _usedPhoneBeforeBed = State(initialValue: existingEntry?.usedPhoneBeforeBed ?? false)
        _hadLateCaffeine = State(initialValue: existingEntry?.hadLateCaffeine ?? false)
        _hadAlcohol = State(initialValue: existingEntry?.hadAlcohol ?? false)
        _settleFeedback = State(initialValue: existingEntry?.settleFeedback ?? .somewhat)
    }

    var body: some View {
        Form {
            Section {
                Text("详细复盘会进入趋势统计，并直接影响今晚推荐。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Section("昨夜节律") {
                DatePicker("醒来日期", selection: $date, displayedComponents: .date)
                DatePicker("上床时间", selection: $bedtime, displayedComponents: .hourAndMinute)
                DatePicker("起床时间", selection: $wakeTime, displayedComponents: .hourAndMinute)
            }

            Section("睡眠结果") {
                Picker("睡醒感受", selection: $mood) {
                    ForEach(Mood.allCases) { mood in
                        Text(mood.title).tag(mood)
                    }
                }

                HStack {
                    Text("入睡时长")
                    Spacer()
                    Slider(value: $latency, in: 5...90, step: 5)
                        .frame(width: 170)
                    Text(L10n.format("%d 分", Int(latency)))
                        .foregroundColor(.secondary)
                }

                Stepper(L10n.format("夜间醒来：%d 次", wakeCount), value: $wakeCount, in: 0...8)

                Picker("睡前压力", selection: $stressLevel) {
                    ForEach(StressLevel.allCases) { level in
                        Text(L10n.format("%@ · %@", level.title, level.subtitle)).tag(level)
                    }
                }
            }

            Section("睡前行为") {
                Toggle("睡前刷了手机", isOn: $usedPhoneBeforeBed)
                Toggle("晚上喝了咖啡/浓茶", isOn: $hadLateCaffeine)
                Toggle("晚上喝了酒", isOn: $hadAlcohol)
            }

            Section("主观效果") {
                Picker("这套流程有没有帮你更快安静下来？", selection: $settleFeedback) {
                    ForEach(SettleFeedback.allCases) { feedback in
                        Text(feedback.title).tag(feedback)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("备注") {
                TextEditor(text: $notes)
                    .frame(minHeight: 110)
                Text("只写你觉得会影响今晚判断的信息，比如晚饭太晚、工作压力或房间太吵。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Section {
                Button {
                    saveEntry()
                } label: {
                    Text("保存复盘")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle(L10n.tr(isEditing ? "编辑复盘" : "详细复盘"))
        .scrollContentBackground(.hidden)
        .background(SleepBackdrop())
    }

    private func saveEntry() {
        let wakeDate = merge(date: date, time: wakeTime)
        var bedtimeDate = merge(date: date, time: bedtime)

        if bedtimeDate > wakeDate {
            bedtimeDate = Calendar.current.date(byAdding: .day, value: -1, to: bedtimeDate) ?? bedtimeDate
        }

        let entry = SleepEntry(
            id: existingEntry?.id ?? UUID(),
            kind: .detailed,
            date: wakeDate,
            mood: mood,
            latencyMinutes: Int(latency),
            wakeCount: wakeCount,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            bedtime: bedtimeDate,
            wakeTime: wakeDate,
            stressLevel: stressLevel,
            usedPhoneBeforeBed: usedPhoneBeforeBed,
            hadLateCaffeine: hadLateCaffeine,
            hadAlcohol: hadAlcohol,
            settleFeedback: settleFeedback
        )

        if isEditing {
            store.updateEntry(entry)
        } else {
            store.addEntry(entry)
        }
        dismiss()
    }

    private func merge(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let day = calendar.dateComponents([.year, .month, .day], from: date)
        let clock = calendar.dateComponents([.hour, .minute], from: time)
        var merged = DateComponents()
        merged.year = day.year
        merged.month = day.month
        merged.day = day.day
        merged.hour = clock.hour
        merged.minute = clock.minute
        return calendar.date(from: merged) ?? date
    }

    private var isEditing: Bool {
        existingEntry != nil
    }
}

#Preview("Quick log") {
    NavigationStack {
        ReflectionView()
            .environmentObject(SleepStore())
    }
    .preferredColorScheme(.dark)
}

#Preview("Detail") {
    NavigationStack {
        ReflectionDetailView()
            .environmentObject(SleepStore())
    }
    .preferredColorScheme(.dark)
}
