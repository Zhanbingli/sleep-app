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
                if store.summary.detailedEntryCount > 0 {
                    Section {
                        HStack {
                            Stat(label: "平均入睡", value: L10n.format("%d 分", Int(store.summary.averageLatency)))
                            Stat(label: "平均睡眠", value: L10n.format("%.1f 小时", store.summary.averageSleepHours))
                            Stat(label: "刷手机", value: "\(Int(store.summary.phoneUseRate * 100))%")
                        }
                        .padding(.vertical, 6)
                    } header: {
                        Text("最近 7 天")
                    } footer: {
                        Text(store.historyTrustLine)
                    }
                } else {
                    Section {
                        Text("已有晨间快记，补一条详细复盘后这里会开始显示趋势。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } header: {
                        Text("最近 7 天")
                    } footer: {
                        Text(store.historyTrustLine)
                    }
                }

                Section {
                    ForEach(store.sortedEntries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(Self.dateFormatter.string(from: entry.date))
                                    .font(.headline)
                                Spacer()
                                Text(entry.mood.title)
                                    .font(.subheadline)
                                    .foregroundColor(entry.mood.color)
                            }
                            if entry.isDetailed {
                                HStack(spacing: 12) {
                                    if let latencyMinutes = entry.latencyMinutes {
                                        Label(L10n.format("%d 分钟入睡", latencyMinutes), systemImage: "clock")
                                    }
                                    if let wakeCount = entry.wakeCount {
                                        Label(L10n.format("%d 次醒来", wakeCount), systemImage: "zzz")
                                    }
                                    Label(L10n.format("%.1f 小时", entry.sleepDurationHours), systemImage: "bed.double")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            } else {
                                Text("晨间快记")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(SleepTheme.accent)
                            }
                            if !entry.habitTags.isEmpty {
                                Text(entry.habitTags.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundColor(SleepTheme.accent)
                            }
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
                } footer: {
                    Text("左滑记录可编辑或删除。")
                }
            }
        }
        .navigationTitle("睡眠历史")
        .scrollContentBackground(.hidden)
        .background(SleepBackdrop())
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
                ReflectionDetailView(existingEntry: entry)
                    .environmentObject(store)
            }
        }
        .sheet(isPresented: $showNewEntry) {
            NavigationStack {
                ReflectionDetailView()
                    .environmentObject(store)
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()
}

private struct Stat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.tr(label))
                .font(.caption)
                .foregroundColor(.secondary)
            Text(L10n.tr(value))
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
