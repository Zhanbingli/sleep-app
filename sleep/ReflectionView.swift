//
//  ReflectionView.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import SwiftUI

struct ReflectionView: View {
    @EnvironmentObject var store: SleepStore
    @Environment(\.dismiss) private var dismiss

    private let existingEntry: SleepEntry?

    @State private var date: Date
    @State private var mood: Mood
    @State private var latency: Double
    @State private var wakeCount: Int
    @State private var notes: String

    init(existingEntry: SleepEntry? = nil) {
        self.existingEntry = existingEntry
        _date = State(initialValue: existingEntry?.date ?? Date())
        _mood = State(initialValue: existingEntry?.mood ?? .okay)
        _latency = State(initialValue: Double(existingEntry?.latencyMinutes ?? 20))
        _wakeCount = State(initialValue: existingEntry?.wakeCount ?? 1)
        _notes = State(initialValue: existingEntry?.notes ?? "")
    }

    var body: some View {
        Form {
            Section("昨夜情况") {
                DatePicker("日期", selection: $date, displayedComponents: .date)
                Picker("睡醒感受", selection: $mood) {
                    ForEach(Mood.allCases) { mood in
                        Text(mood.rawValue).tag(mood)
                    }
                }
                HStack {
                    Text("入睡时长")
                    Spacer()
                    Slider(value: $latency, in: 5...60, step: 5)
                        .frame(width: 180)
                    Text("\(Int(latency)) 分")
                        .foregroundColor(.secondary)
                }
                Stepper("夜间醒来：\(wakeCount) 次", value: $wakeCount, in: 0...6)
            }

            Section("备注") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
                Text("写下担忧或观察，帮自己卸载思绪。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Section {
                Button {
                    saveEntry()
                } label: {
                    Label("保存记录", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle(isEditing ? "编辑记录" : "复盘与记录")
    }

    private func saveEntry() {
        let entry = SleepEntry(
            id: existingEntry?.id ?? UUID(),
            date: date,
            mood: mood,
            latencyMinutes: Int(latency),
            wakeCount: wakeCount,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        if isEditing {
            store.updateEntry(entry)
        } else {
            store.addEntry(entry)
        }
        dismiss()
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
