//
//  SleepHistoryView.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import SwiftUI

struct SleepHistoryView: View {
    @EnvironmentObject var store: SleepStore

    @State private var entryToEdit: SleepEntry?
    @State private var showNewEntry = false

    var body: some View {
        List {
            if store.sortedEntries.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.secondary)
                        Text("还没有记录")
                            .font(.headline)
                        Text("睡前复盘一下，积累 7 天后即可看到趋势。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                }
            } else {
                Section {
                    HStack {
                        Stat(label: "平均入睡", value: "\(Int(store.summary.averageLatency)) 分")
                        Stat(label: "平均醒来", value: String(format: "%.1f 次", store.summary.averageWakeCount))
                        Stat(label: "最近心情", value: store.summary.recentMood?.rawValue ?? "—")
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("最近 7 天")
                }

                Section {
                    ForEach(store.sortedEntries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(Self.dateFormatter.string(from: entry.date))
                                    .font(.headline)
                                Spacer()
                                Text(entry.mood.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(entry.mood.color)
                            }
                            HStack(spacing: 12) {
                                Label("\(entry.latencyMinutes) 分钟入睡", systemImage: "clock")
                                Label("\(entry.wakeCount) 次醒来", systemImage: "zzz")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            if !entry.notes.isEmpty {
                                Text(entry.notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                        .swipeActions {
                            Button("编辑") {
                                entryToEdit = entry
                            }
                            .tint(.accentColor)
                            Button(role: .destructive) {
                                store.deleteEntry(id: entry.id)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("全部记录")
                }
            }
        }
        .navigationTitle("睡眠历史")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewEntry = true
                } label: {
                    Label("添加记录", systemImage: "plus")
                }
            }
        }
        .sheet(item: $entryToEdit) { entry in
            NavigationStack {
                ReflectionView(existingEntry: entry)
                    .environmentObject(store)
            }
        }
        .sheet(isPresented: $showNewEntry) {
            NavigationStack {
                ReflectionView()
                    .environmentObject(store)
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

private struct Stat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        SleepHistoryView()
            .environmentObject(SleepStore())
    }
}
