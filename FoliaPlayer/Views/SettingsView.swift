import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: PlayerSettings

    var body: some View {
        NavigationStack {
            Form {
                Section("歌词外观") {
                    Picker("动态背景主题", selection: $settings.theme) {
                        ForEach(PlayerTheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("歌词字号")
                            Spacer()
                            Text("\(Int(settings.lyricFontSize)) pt")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $settings.lyricFontSize, in: 18...48, step: 1)
                    }
                    VStack(spacing: 12) {
                        Text("此刻的歌词")
                            .font(.system(size: settings.lyricFontSize, weight: .bold, design: .rounded))
                        Text("Folia · 沉浸式聆听")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }

                Section("关于") {
                    LabeledContent("版本", value: "MVP 0.1.0")
                    LabeledContent("最低系统", value: "iOS 17.0")
                    LabeledContent("播放引擎", value: "AVAudioPlayer")
                    LabeledContent("歌词格式", value: "LRC")
                }

                Section {
                    Text("本项目为独立实现的播放器原型，未包含网易云音乐搜索，也不使用 Folia 上游项目的专有资源。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
        }
    }
}
