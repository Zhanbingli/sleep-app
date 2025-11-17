//
//  SoundscapeView.swift
//  sleep
//
//  Created by ChatGPT on 17/11/25.
//

import SwiftUI

struct SoundscapeView: View {
    @EnvironmentObject var store: SleepStore
    @EnvironmentObject var engine: SoundscapeEngine
    @State private var fadeMinutes: Double = 30

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(engine.isPlaying ? "音景播放中" : "未播放")
                                .font(.headline)
                            Text(statusText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button {
                            engine.isPlaying ? engine.stop() : startPlayback()
                        } label: {
                            Label(engine.isPlaying ? "停止" : "开始", systemImage: engine.isPlaying ? "stop.fill" : "play.fill")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(engine.isPlaying ? .red : .accentColor)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("渐弱定时")
                            Spacer()
                            Text("\(Int(fadeMinutes)) 分钟")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $fadeMinutes, in: 10...60, step: 5)
                        HStack(spacing: 12) {
                            ForEach([20.0, 30.0, 40.0], id: \.self) { preset in
                                Button("\(Int(preset)) 分") { fadeMinutes = preset }
                                    .buttonStyle(.bordered)
                            }
                            Spacer()
                            Button("开始渐弱") {
                                engine.fadeOut(duration: fadeMinutes * 60)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!engine.isPlaying)
                        }
                        if engine.isFadingOut {
                            Text("渐弱中，完成后会自动停止。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("控制")
            }

            Section {
                ForEach(store.soundscapeTracks) { track in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: track.kind.icon)
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(track.title)
                                    .font(.headline)
                                Text(track.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { track.isEnabled },
                                set: { newValue in
                                    store.toggleSoundscape(id: track.id)
                                    engine.setEnabled(for: track.id, enabled: newValue)
                                }
                            ))
                            .labelsHidden()
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "speaker.wave.2")
                                    .foregroundColor(.secondary)
                                Slider(
                                    value: Binding(
                                        get: { track.volume },
                                        set: {
                                            store.updateSoundscapeVolume(id: track.id, volume: $0)
                                            engine.setVolume(for: track.id, volume: $0)
                                        }
                                    ),
                                    in: 0...1
                                )
                            }
                            Text("音量 \(Int(track.volume * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            } header: {
                Text("音景与噪声")
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("说明")
                        .font(.subheadline).bold()
                    Text("当前版本内置合成的粉噪/雨噪/壁炉噪声，无需音频资源，可后台播放，支持渐弱。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 6)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("音景")
        .onAppear {
            engine.configureTracks(store.soundscapeTracks)
        }
    }

    private func startPlayback() {
        engine.configureTracks(store.soundscapeTracks)
        // 若无开启的音景，默认开启粉噪声以避免无声播放
        if !store.soundscapeTracks.contains(where: { $0.isEnabled }) {
            if let first = store.soundscapeTracks.first {
                store.toggleSoundscape(id: first.id)
                engine.setEnabled(for: first.id, enabled: true)
            }
        }
        engine.start()
    }

    private var statusText: String {
        if engine.isFadingOut {
            return "渐弱进行中..."
        }
        return engine.isPlaying ? "建议搭配 20-40 分钟渐弱，减少夜间惊醒。" : "选择开启的音景后点击开始。"
    }
}

#Preview {
    NavigationStack {
        SoundscapeView()
            .environmentObject(SleepStore())
    }
}
