import SwiftUI

struct NavidromeView: View {
    @StateObject private var model = NavidromeViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("服务器连接") {
                    TextField("服务器地址，例如 https://music.example.com", text: $model.serverURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                    TextField("用户名", text: $model.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("密码", text: $model.password)
                    Button {
                        model.connect()
                    } label: {
                        HStack {
                            if model.isLoading { ProgressView().padding(.trailing, 4) }
                            Text(model.isLoading ? "连接中…" : "连接并读取专辑")
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                        }
                    }
                    .disabled(model.isLoading || model.serverURL.isEmpty || model.username.isEmpty || model.password.isEmpty)
                }

                if let message = model.statusMessage {
                    Section("连接状态") {
                        Label(message, systemImage: model.isConnected ? "checkmark.circle.fill" : "info.circle")
                            .font(.subheadline)
                    }
                }

                if !model.albums.isEmpty {
                    Section("专辑（\(model.albums.count)）") {
                        ForEach(Array(model.albums.enumerated()), id: \.offset) { entry in
                            Label(entry.element, systemImage: "opticaldisc")
                        }
                    }
                } else {
                    Section("说明") {
                        Text("当前通过 Subsonic 兼容 API 的 ping 与专辑列表接口连接 Navidrome。此 MVP 尚未实现远程音频流播放和凭据持久化。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Navidrome")
        }
    }
}
