//
//  RoutineView.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import SwiftUI

struct RoutineView: View {
    @EnvironmentObject var store: SleepStore

    var body: some View {
        List {
            Section {
                ForEach(store.routineSteps) { step in
                    HStack {
                        Image(systemName: step.icon)
                            .foregroundColor(step.completed ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                            Text("\(step.durationMinutes) 分钟")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button {
                            store.toggleRoutineStep(id: step.id)
                        } label: {
                            Image(systemName: step.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(step.completed ? .green : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("睡前例行")
            } footer: {
                Text("保持一致的序列，可以降低睡前决策消耗。")
            }

            Section {
                Button("重置流程进度", role: .destructive) {
                    store.resetRoutine()
                }
            }
        }
        .navigationTitle("晚间流程")
    }
}

#Preview {
    NavigationStack {
        RoutineView()
            .environmentObject(SleepStore())
    }
}
