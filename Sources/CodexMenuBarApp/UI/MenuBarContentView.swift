import SwiftUI

struct MenuBarContentView: View {
    let snapshot: MenuBarSnapshot
    let launchAtLoginEnabled: Bool
    let onRefresh: () -> Void
    let onToggleLaunchAtLogin: (Bool) -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            metrics
            projectSection
            pricingSection
            weeklySection
            footer
        }
        .padding(16)
        .frame(width: 320)
    }

    private var projectSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日项目")
                .font(.subheadline)
                .fontWeight(.medium)

            if snapshot.projectRows.isEmpty {
                Text("暂无项目用量")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(snapshot.projectRows, id: \.cwd) { row in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("输入 \(row.inputTokensText)  输出 \(row.outputTokensText)")
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(row.costText)
                            .font(.caption.monospacedDigit())
                    }
                }
            }
        }
    }

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("模型价格")
                .font(.subheadline)
                .fontWeight(.medium)

            if snapshot.pricingRows.isEmpty {
                Text("价格暂不可用")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(snapshot.pricingRows, id: \.model) { row in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.model)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("输入 \(row.inputPerMillionText)  输出 \(row.outputPerMillionText)  缓存 \(row.cacheReadPerMillionText)")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Codex 用量")
                .font(.headline)
            Text(snapshot.todayCostText)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
            if let errorMessage = snapshot.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var metrics: some View {
        HStack(spacing: 16) {
            metric(title: "输入", value: snapshot.inputTokensText)
            metric(title: "输出", value: snapshot.outputTokensText)
        }
    }

    private var weeklySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近 7 天")
                .font(.subheadline)
                .fontWeight(.medium)

            if snapshot.weeklyRows.isEmpty {
                Text("暂无最近用量")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(snapshot.weeklyRows, id: \.dateLabel) { row in
                    HStack {
                        Text(row.dateLabel)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "$%.2f", row.costUSD))
                            .monospacedDigit()
                    }
                    .font(.caption)
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("登录时打开", isOn: Binding(
                get: { launchAtLoginEnabled },
                set: { onToggleLaunchAtLogin($0) }
            ))
            .toggleStyle(.switch)

            HStack {
            Text("更新于 \(snapshot.lastUpdatedText)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Button("刷新") {
                onRefresh()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            Button("退出") {
                onQuit()
            }
            .controlSize(.small)
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }
}
