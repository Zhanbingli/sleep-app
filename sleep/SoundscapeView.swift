import SwiftUI

struct SoundscapeView: View {
    @EnvironmentObject private var store: SleepStore
    @EnvironmentObject private var engine: SoundscapeEngine

    var body: some View {
        SoundscapeScreen(store: store, engine: engine)
    }
}

private struct SoundscapeScreen: View {
    @ObservedObject private var store: SleepStore
    @StateObject private var viewModel: SoundscapeViewModel

    init(store: SleepStore, engine: SoundscapeEngine) {
        _store = ObservedObject(wrappedValue: store)
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
            Text(viewModel.isPlaying ? (viewModel.isFadingOut ? L10n.tr("渐弱中") : L10n.tr("播放中")) : L10n.tr("未播放"))
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundColor(viewModel.isPlaying ? SleepTheme.accent : SleepTheme.mutedInk)
            Text(L10n.format("推荐：%@ · %d 分钟渐弱", store.tonightPlan.recommendedSoundKind.displayName, store.tonightPlan.fadeMinutes))
                .font(.footnote)
                .foregroundColor(SleepTheme.ink.opacity(0.82))
            Text(viewModel.statusText)
                .font(.subheadline)
                .foregroundColor(SleepTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
            Text(store.tonightPlan.insight)
                .font(.footnote)
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
                Text(L10n.format("%d 分钟", Int(viewModel.fadeMinutes)))
                    .font(.subheadline)
                    .foregroundColor(SleepTheme.mutedInk)
            }
            Slider(
                value: Binding(
                    get: { viewModel.fadeMinutes },
                    set: { viewModel.setFadeMinutes($0) }
                ),
                in: 10...60,
                step: 5
            )
            .tint(SleepTheme.accent)
            Text("会记住你的默认渐弱时长。")
                .font(.caption)
                .foregroundColor(SleepTheme.mutedInk)
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
                Text(viewModel.isPlaying ? L10n.tr("停止") : L10n.tr("开始"))
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
                Text(L10n.tr("开始渐弱"))
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
                Text(track.kind.displayName)
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

            Text(track.kind.trackDescription)
                .font(.caption)
                .foregroundColor(SleepTheme.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
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
