import SwiftUI

struct AboutView: View {
    var body: some View {
        InfoPageScaffold {
            VStack(alignment: .leading, spacing: 18) {
                SleepSectionHeader(
                    eyebrow: "About",
                    title: "为睡前降速准备的一段短流程",
                    detail: "把呼吸、音景和晨间复盘收在一个足够轻的入口里。"
                )

                InfoCard(
                    title: "版本信息",
                    lines: [
                        "\(AppMetadata.appName)",
                        L10n.format("版本 %@ · Build %@", AppMetadata.version, AppMetadata.build),
                        AppMetadata.bundleIdentifier
                    ]
                )

                InfoCard(
                    title: "这个 app 适合什么",
                    lines: [
                        "睡前脑子停不下来",
                        "容易被手机或环境声拖走",
                        "想用很短的流程先把自己拉回睡眠准备状态"
                    ]
                )

                InfoCard(
                    title: "它不做什么",
                    lines: [
                        "不提供医疗诊断",
                        "不替代医生、心理咨询或睡眠治疗",
                        "如果你的失眠、呼吸暂停或情绪问题已经明显影响生活，应该尽快寻求专业帮助"
                    ]
                )
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyView: View {
    var body: some View {
        InfoPageScaffold {
            VStack(alignment: .leading, spacing: 18) {
                SleepSectionHeader(
                    eyebrow: "Privacy",
                    title: "当前版本以本地存储为主",
                    detail: "让用户先知道数据放在哪里、会不会被传走。"
                )

                InfoCard(
                    title: "会保存什么",
                    lines: [
                        "睡眠记录和晨间反馈",
                        "睡前流程步骤",
                        "音景偏好、渐弱时长和睡前画像"
                    ]
                )

                InfoCard(
                    title: "当前版本怎么处理数据",
                    lines: [
                        "这些内容保存在当前设备上",
                        "音景是在设备本地生成的，不依赖外部音频资源",
                        "当前版本没有登录、云同步或广告跟踪入口"
                    ]
                )

                if let destination = AppMetadata.privacyDestination, let url = AppMetadata.privacyPolicyURL {
                    ExternalLinkCard(
                        title: "完整隐私政策",
                        detail: destination,
                        buttonTitle: "打开隐私政策",
                        url: url
                    )
                } else {
                    SubmissionNoteCard(
                        title: "上架前还要补什么",
                        lines: [
                            "在 App Store Connect 填写 Privacy Policy URL",
                            "把公开可访问的隐私政策链接填到 AppMetadata.privacyPolicyURL",
                            "确保页面内容和你在 App Store Connect 勾选的数据处理问卷一致"
                        ]
                    )
                }
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SupportView: View {
    var body: some View {
        InfoPageScaffold {
            VStack(alignment: .leading, spacing: 18) {
                SleepSectionHeader(
                    eyebrow: "Support",
                    title: "给用户一个能自助排查的入口",
                    detail: "先回答最常见的问题，再补上真实支持链接。"
                )

                InfoCard(
                    title: "常见问题",
                    lines: [
                        "听不到音景时，先检查静音键、媒体音量和蓝牙输出设备",
                        "历史页暂时没有趋势，通常是因为还缺详细复盘记录",
                        "英文界面跟随系统语言切换；用户自己写的备注不会自动翻译"
                    ]
                )

                InfoCard(
                    title: "反馈问题时最好附上这些信息",
                    lines: [
                        L10n.format("版本 %@ · Build %@", AppMetadata.version, AppMetadata.build),
                        AppMetadata.bundleIdentifier,
                        "出现问题的页面和大致操作路径"
                    ]
                )

                if let destination = AppMetadata.supportDestination, let url = AppMetadata.supportLink {
                    ExternalLinkCard(
                        title: "联系支持",
                        detail: destination,
                        buttonTitle: "打开支持入口",
                        url: url
                    )
                } else {
                    SubmissionNoteCard(
                        title: "上架前还要补什么",
                        lines: [
                            "准备公开可访问的支持页、邮箱或 FAQ",
                            "把链接填到 AppMetadata.supportURL 或 supportEmail",
                            "在 App Store Connect 的 App Information 里同步补齐 Support / Marketing 文案"
                        ]
                    )
                }
            }
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataManagementView: View {
    @EnvironmentObject private var store: SleepStore
    @Environment(\.dismiss) private var dismiss

    @State private var showResetAlert = false

    var body: some View {
        InfoPageScaffold {
            VStack(alignment: .leading, spacing: 18) {
                SleepSectionHeader(
                    eyebrow: "Data",
                    title: "让用户知道怎么清理本地数据",
                    detail: "这也是审核时比较容易被问到的基础能力。"
                )

                InfoCard(
                    title: "当前设备上的内容",
                    lines: [
                        L10n.format("睡眠记录 %d 条", store.entries.count),
                        L10n.format("睡前流程 %d 个步骤", store.routineSteps.count),
                        L10n.format("已启用音景 %d 个", store.soundscapeTracks.filter { $0.isEnabled }.count)
                    ]
                )

                InfoCard(
                    title: "重置会发生什么",
                    lines: [
                        "清空睡眠记录和睡前画像",
                        "把音景设置恢复成默认状态",
                        "把睡前流程恢复成默认建议步骤"
                    ]
                )

                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Text("重置本地数据")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red.opacity(0.78))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("确认重置本地数据？", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) {}
            Button("重置", role: .destructive) {
                store.resetLocalData()
                dismiss()
            }
        } message: {
            Text("这会清空当前设备上的睡眠记录和画像设置，并把流程与音景恢复到默认状态。")
        }
    }
}

private struct InfoPageScaffold<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            SleepBackdrop()

            ScrollView(showsIndicators: false) {
                content
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    .padding(.bottom, 36)
            }
        }
    }
}

private struct InfoCard: View {
    let title: String
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.tr(title))
                .font(.headline)
                .foregroundColor(SleepTheme.ink)

            ForEach(lines, id: \.self) { line in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(SleepTheme.accent.opacity(0.85))
                        .frame(width: 5, height: 5)
                        .padding(.top, 7)
                    Text(L10n.tr(line))
                        .font(.subheadline)
                        .foregroundColor(SleepTheme.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .background(SleepTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(SleepTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct SubmissionNoteCard: View {
    let title: String
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.tr(title))
                .font(.headline)
                .foregroundColor(SleepTheme.ink)

            ForEach(lines, id: \.self) { line in
                Text(L10n.tr(line))
                    .font(.subheadline)
                    .foregroundColor(SleepTheme.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(SleepTheme.softCard)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(SleepTheme.accent.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct ExternalLinkCard: View {
    @Environment(\.openURL) private var openURL

    let title: String
    let detail: String
    let buttonTitle: String
    let url: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr(title))
                .font(.headline)
                .foregroundColor(SleepTheme.ink)
            Text(detail)
                .font(.footnote)
                .foregroundColor(SleepTheme.mutedInk)
                .textSelection(.enabled)
            Button {
                openURL(url)
            } label: {
                Text(L10n.tr(buttonTitle))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(SleepTheme.indigo)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(SleepTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(SleepTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
