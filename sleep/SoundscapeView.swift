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
            SleepBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    trackList
                    fadeSection
                    primaryAction
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("音景")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.isPlaying ? (viewModel.isFadingOut ? "渐弱中" : "播放中") : "未播放")
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundColor(viewModel.isPlaying ? SleepTheme.accent : SleepTheme.mutedInk)
            Text(viewModel.statusText)
                .font(.subheadline)
                .foregroundColor(SleepTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var trackList: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.tracks) { track in
                TrackRow(
                    track: track,
                    onToggle: { viewModel.setEnabled(for: track, enabled: $0) },
                    onVolumeChange: { viewModel.updateVolume(for: track, volume: $0) }
                )
            }
        }
    }

    private var fadeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("渐弱")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SleepTheme.ink)
                Spacer()
                Text("\(Int(viewModel.fadeMinutes)) 分钟")
                    .font(.subheadline)
                    .foregroundColor(SleepTheme.mutedInk)
            }
            Slider(
                value: Binding(
                    get: { viewModel.fadeMinutes },
                    set: { viewModel.fadeMinutes = $0 }
                ),
                in: 10...60,
                step: 5
            )
            .tint(SleepTheme.accent)
        }
        .padding(18)
        .background(SleepTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SleepTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var primaryAction: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.togglePlayback()
            } label: {
                Text(viewModel.isPlaying ? "停止" : "开始")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.isPlaying ? SleepTheme.surfaceHigh : SleepTheme.indigo)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                viewModel.startFadeOut()
            } label: {
                Text("开始渐弱")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(viewModel.isPlaying ? SleepTheme.ink : SleepTheme.mutedInk.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(SleepTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(SleepTheme.line, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.isPlaying)
        }
    }
}

private struct TrackRow: View {
    let track: SoundscapeTrack
    let onToggle: (Bool) -> Void
    let onVolumeChange: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: track.kind.icon)
                    .font(.subheadline)
                    .foregroundColor(track.isEnabled ? SleepTheme.accent : SleepTheme.mutedInk)
                    .frame(width: 24)
                Text(track.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(SleepTheme.ink)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { track.isEnabled },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
                .tint(SleepTheme.accent)
            }

            if track.isEnabled {
                Slider(
                    value: Binding(
                        get: { track.volume },
                        set: { onVolumeChange($0) }
                    ),
                    in: 0...1
                )
                .tint(SleepTheme.accent)
            }
        }
        .padding(16)
        .background(SleepTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SleepTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        SoundscapeView()
            .environmentObject(SleepStore())
            .environmentObject(SoundscapeEngine())
    }
    .preferredColorScheme(.dark)
}
