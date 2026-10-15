import Combine
import Foundation

@MainActor
final class NavidromeViewModel: ObservableObject {
    @Published var serverURL = ""
    @Published var username = ""
    @Published var password = ""
    @Published private(set) var isLoading = false
    @Published private(set) var isConnected = false
    @Published private(set) var albums: [String] = []
    @Published var statusMessage: String?

    func connect() {
        guard !isLoading else { return }
        isLoading = true
        isConnected = false
        albums = []

        Task {
            defer { isLoading = false }
            do {
                let client = try NavidromeClient(
                    serverURL: serverURL,
                    username: username,
                    password: password
                )
                try await client.ping()
                isConnected = true
                statusMessage = "连接成功，正在读取专辑列表。"
                do {
                    albums = try await client.getAlbums()
                    statusMessage = albums.isEmpty ? "已连接，但服务器没有返回专辑；可检查曲库扫描状态。" : "已读取 \(albums.count) 张专辑。"
                } catch {
                    statusMessage = "已连接，但读取专辑失败：\(error.localizedDescription)"
                }
            } catch {
                statusMessage = "连接失败：\(error.localizedDescription)"
            }
        }
    }
}
