import SwiftUI

struct TonightStateCheckView: View {
    let onSelect: (TonightState) -> Void

    var body: some View {
        ZStack {
            SleepBackdrop()

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("今晚")
                        .font(.subheadline.weight(.medium))
                        .tracking(2)
                        .foregroundColor(SleepTheme.mutedInk)
                    Text("你卡在哪里？")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundColor(SleepTheme.ink)
                }
                .padding(.top, 28)

                VStack(spacing: 12) {
                    ForEach(TonightState.allCases) { state in
                        Button {
                            onSelect(state)
                        } label: {
                            Text(state.title)
                                .font(.headline.weight(.semibold))
                                .foregroundColor(SleepTheme.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 22)
                                .background(SleepTheme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(SleepTheme.line, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    TonightStateCheckView { _ in }
        .preferredColorScheme(.dark)
}
