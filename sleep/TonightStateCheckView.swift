import SwiftUI

struct TonightStateCheckView: View {
    let onSelect: (TonightState) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("今晚你卡在哪个状态？")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(SleepTheme.ink)

                Text("只选一个最像你的状态。我会据此决定今晚的呼吸、音景和流程节奏。")
                    .font(.subheadline)
                    .foregroundColor(SleepTheme.mutedInk)

                ForEach(TonightState.allCases) { state in
                    Button {
                        onSelect(state)
                    } label: {
                        HStack(alignment: .top, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(state.title)
                                    .font(.headline)
                                    .foregroundColor(SleepTheme.ink)
                                Text(state.detail)
                                    .font(.caption)
                                    .foregroundColor(SleepTheme.mutedInk)
                            }
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(SleepTheme.accent)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SleepTheme.softCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(SleepTheme.line, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(SleepBackdrop())
    }
}

#Preview {
    TonightStateCheckView { _ in }
}
