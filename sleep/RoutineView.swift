//
//  RoutineView.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import SwiftUI

struct RoutineView: View {
    @EnvironmentObject private var store: SleepStore

    @State private var draftStep: RoutineStep?

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
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("编辑") {
                            draftStep = step
                        }
                        .tint(.accentColor)

                        Button(role: .destructive) {
                            store.deleteRoutineStep(id: step.id)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
                .onMove(perform: store.moveRoutineSteps)
                .onDelete(perform: store.deleteRoutineSteps)
            } header: {
                Text("睡前例行")
            } footer: {
                Text("保持一致的顺序，可以降低睡前决策消耗。长按拖动即可调整顺序。")
            }

            Section {
                Button("添加步骤") {
                    draftStep = RoutineStep(title: "", icon: RoutineIconOption.allCases.first?.symbolName ?? "moon.stars", durationMinutes: 5)
                }

                Button("重置流程进度", role: .destructive) {
                    store.resetRoutine()
                }
            }
        }
        .navigationTitle("晚间流程")
        .scrollContentBackground(.hidden)
        .background(SleepBackdrop())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $draftStep) { step in
            NavigationStack {
                RoutineStepEditor(step: step) { updatedStep in
                    if store.routineSteps.contains(where: { $0.id == updatedStep.id }) {
                        store.updateRoutineStep(updatedStep)
                    } else {
                        store.addRoutineStep(updatedStep)
                    }
                }
            }
        }
    }
}

private struct RoutineStepEditor: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var icon: RoutineIconOption
    @State private var duration: Double

    private let stepID: UUID
    private let completed: Bool
    private let isExistingStep: Bool
    private let onSave: (RoutineStep) -> Void

    init(step: RoutineStep, onSave: @escaping (RoutineStep) -> Void) {
        self.stepID = step.id
        self.completed = step.completed
        self.isExistingStep = !step.title.isEmpty
        self.onSave = onSave
        _title = State(initialValue: step.title)
        _icon = State(initialValue: RoutineIconOption(symbolName: step.icon) ?? .moonStars)
        _duration = State(initialValue: Double(step.durationMinutes))
    }

    var body: some View {
        Form {
            Section("步骤内容") {
                TextField("例如：放下手机", text: $title)

                Picker("图标", selection: $icon) {
                    ForEach(RoutineIconOption.allCases) { option in
                        Label(option.title, systemImage: option.symbolName)
                            .tag(option)
                    }
                }

                HStack {
                    Text("预计时长")
                    Spacer()
                    Slider(value: $duration, in: 5...30, step: 5)
                        .frame(width: 170)
                    Text("\(Int(duration)) 分")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button("保存步骤") {
                    onSave(
                        RoutineStep(
                            id: stepID,
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            icon: icon.symbolName,
                            durationMinutes: Int(duration),
                            completed: completed
                        )
                    )
                    dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle(isExistingStep ? "编辑步骤" : "添加步骤")
    }
}

private enum RoutineIconOption: String, CaseIterable, Identifiable {
    case moonStars = "moon.stars"
    case phoneOff = "iphone.slash"
    case shower = "shower"
    case book = "book.closed"
    case tea = "cup.and.saucer"
    case lungs = "lungs.fill"
    case waveform = "waveform"
    case lightbulb = "lightbulb.slash"

    var id: String { rawValue }

    var symbolName: String { rawValue }

    var title: String {
        switch self {
        case .moonStars:
            return "睡眠准备"
        case .phoneOff:
            return "放下屏幕"
        case .shower:
            return "洗漱"
        case .book:
            return "阅读"
        case .tea:
            return "热饮"
        case .lungs:
            return "呼吸放松"
        case .waveform:
            return "音景"
        case .lightbulb:
            return "调暗灯光"
        }
    }

    init?(symbolName: String) {
        self.init(rawValue: symbolName)
    }
}

#Preview {
    NavigationStack {
        RoutineView()
            .environmentObject(SleepStore())
    }
}
