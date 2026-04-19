//
//  ReflectionView.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import SwiftUI

struct ReflectionView: View {
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
            Section("昨夜节律") {
                DatePicker("醒来日期", selection: $date, displayedComponents: .date)
                DatePicker("上床时间", selection: $bedtime, displayedComponents: .hourAndMinute)
                DatePicker("起床时间", selection: $wakeTime, displayedComponents: .hourAndMinute)
            }

            Section("睡眠结果") {
                Picker("睡醒感受", selection: $mood) {
                    ForEach(Mood.allCases) { mood in
                        Text(mood.rawValue).tag(mood)
                    }
                }

                HStack {
                    Text("入睡时长")
                    Spacer()
                    Slider(value: $latency, in: 5...90, step: 5)
                        .frame(width: 170)
                    Text("\(Int(latency)) 分")
                        .foregroundColor(.secondary)
                }

                Stepper("夜间醒来：\(wakeCount) 次", value: $wakeCount, in: 0...8)

                Picker("睡前压力", selection: $stressLevel) {
                    ForEach(StressLevel.allCases) { level in
                        Text("\(level.rawValue) · \(level.subtitle)").tag(level)
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
                    Label("保存复盘", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle(isEditing ? "编辑复盘" : "次晨复盘")
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

#Preview {
    NavigationStack {
        ReflectionView()
            .environmentObject(SleepStore())
    }
}
