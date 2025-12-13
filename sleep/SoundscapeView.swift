import SwiftUI

struct SoundscapeView: View {
    @EnvironmentObject private var store: SleepStore
    @EnvironmentObject private var engine: SoundscapeEngine

    var body: some View {
        SoundscapeScreen(store: store, engine: engine)
    }
}

private struct SoundscapeScreen: View {
    @StateObject private var viewModel: SoundscapeViewModel

    init(store: SleepStore, engine: SoundscapeEngine) {
        _viewModel = StateObject(wrappedValue: SoundscapeViewModel(store: store, engine: engine))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.indigo.opacity(0.18), Color.blue.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    SoundscapeHero(
                        isPlaying: viewModel.isPlaying,
                        isFadingOut: viewModel.isFadingOut,
                        statusText: viewModel.statusText,
                        toggleAction: viewModel.togglePlayback
                    )

                    SoundscapeCard {
                        SoundscapeControls(viewModel: viewModel)
                    }

                    SoundscapeCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("音景与噪声")
                                    .font(.headline)
                                Spacer()
                                if viewModel.isPlaying {
                                    StatusPill(text: "播放中", color: .green)
                                }
                            }
                            ForEach(viewModel.tracks) { track in
                                SoundscapeTrackRow(
                                    track: track,
                                    onToggle: { viewModel.setEnabled(for: track, enabled: $0) },
                                    onVolumeChange: { viewModel.updateVolume(for: track, volume: $0) }
                                )
                                if track.id != viewModel.tracks.last?.id {
                                    Divider()
                                }
                            }
                            Text("当前版本内置合成的粉噪/雨噪/壁炉噪声，无需音频资源，可后台播放，支持渐弱。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 18)
            }
        }
        .navigationTitle("音景")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct SoundscapeHero: View {
    let isPlaying: Bool
    let isFadingOut: Bool
    let statusText: String
    let toggleAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("舒缓音景")
                        .font(.largeTitle.bold())
                    Text(statusText)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: toggleAction) {
                    Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(isPlaying ? .red : .white)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
            }
            HStack(spacing: 10) {
                StatusPill(text: isPlaying ? "播放中" : "未播放", color: isPlaying ? .green : .secondary)
                if isFadingOut {
                    StatusPill(text: "渐弱", color: .orange)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.indigo.opacity(0.6), Color.blue.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .foregroundColor(.white)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

private struct SoundscapeCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

private struct SoundscapeControls: View {
    @ObservedObject var viewModel: SoundscapeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("播放控制")
                        .font(.headline)
                    Text("随时开始/停止，或设置渐弱时长")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                Spacer()
                Button {
                    viewModel.togglePlayback()
                } label: {
                    Label(viewModel.isPlaying ? "停止" : "开始", systemImage: viewModel.isPlaying ? "stop.fill" : "play.fill")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isPlaying ? .red : .accentColor)
            }

            VStack(alignment: .leading, spacing: 10) {
                LabeledContent {
                    Text("\(Int(viewModel.fadeMinutes)) 分钟")
                        .foregroundColor(.secondary)
                } label: {
                    Label("渐弱定时", systemImage: "timer")
                }
                Slider(
                    value: Binding(
                        get: { viewModel.fadeMinutes },
                        set: { viewModel.fadeMinutes = $0 }
                    ),
                    in: 10...60,
                    step: 5
                )
                HStack(spacing: 12) {
                    ForEach([20.0, 30.0, 40.0], id: \.self) { preset in
                        Button("\(Int(preset)) 分") {
                            viewModel.fadeMinutes = preset
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                    Button("开始渐弱") {
                        viewModel.startFadeOut()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.isPlaying)
                }
                if viewModel.isFadingOut {
                    Text("渐弱中，完成后会自动停止。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct SoundscapeTrackRow: View {
    let track: SoundscapeTrack
    let onToggle: (Bool) -> Void
    let onVolumeChange: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: track.kind.icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 24, height: 24)
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
                    set: { newValue in onToggle(newValue) }
                ))
                .labelsHidden()
            }
            LabeledContent {
                Slider(
                    value: Binding(
                        get: { track.volume },
                        set: { onVolumeChange($0) }
                    ),
                    in: 0...1
                )
            } label: {
                Label("音量 \(Int(track.volume * 100))%", systemImage: "speaker.wave.2")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        SoundscapeView()
            .environmentObject(SleepStore())
            .environmentObject(SoundscapeEngine())
    }
}
