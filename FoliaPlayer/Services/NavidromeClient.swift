import CryptoKit
import Foundation

struct NavidromeClient {
    private let baseURL: URL
    private let username: String
    private let password: String
    private let clientName = "FoliaPlayer"
    private let apiVersion = "1.16.1"

    init(serverURL: String, username: String, password: String) throws {
        let trimmed = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            throw NavidromeError.invalidServerURL
        }
        self.baseURL = url
        self.username = username
        self.password = password
    }

    func ping() async throws {
        _ = try await request(endpoint: "ping", additionalParameters: [:])
    }

    func getAlbums(limit: Int = 50) async throws -> [String] {
        let json = try await request(
            endpoint: "getAlbumList2",
            additionalParameters: [
                "type": "alphabeticalByName",
                "size": String(max(1, min(limit, 500)))
            ]
        )
        let root = json["subsonic-response"] as? [String: Any] ?? json
        let albumList = root["albumList2"] as? [String: Any] ?? [:]
        let albums = albumList["album"] as? [[String: Any]] ?? []
        return albums.compactMap { album in
            guard let title = album["name"] as? String ?? album["title"] as? String else { return nil }
            let artist = album["artist"] as? String
            return artist.map { "\(title)  ·  \($0)" } ?? title
        }
    }

    private func request(
        endpoint: String,
        additionalParameters: [String: String]
    ) async throws -> [String: Any] {
        let salt = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12).lowercased()
        let token = md5(password + String(salt))
        let endpointURL = baseURL.appendingPathComponent("rest/\(endpoint).view")
        guard var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false) else {
            throw NavidromeError.invalidServerURL
        }

        var parameters = [
            "u": username,
            "t": token,
            "s": String(salt),
            "v": apiVersion,
            "c": clientName,
            "f": "json"
        ]
        additionalParameters.forEach { parameters[$0.key] = $0.value }
        components.queryItems = parameters.keys.sorted().map {
            URLQueryItem(name: $0, value: parameters[$0])
        }

        guard let url = components.url else { throw NavidromeError.invalidServerURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NavidromeError.serverResponse
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NavidromeError.invalidResponse
        }
        let root = json["subsonic-response"] as? [String: Any] ?? json
        if let status = root["status"] as? String, status != "ok" {
            let detail = (root["error"] as? [String: Any])?["message"] as? String
            throw NavidromeError.api(detail ?? "服务器拒绝请求，请检查地址和账号")
        }
        return json
    }

    private func md5(_ value: String) -> String {
        Insecure.MD5.hash(data: Data(value.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

enum NavidromeError: LocalizedError {
    case invalidServerURL
    case serverResponse
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            return "服务器地址无效，请填写包含 http:// 或 https:// 的完整地址。"
        case .serverResponse:
            return "服务器返回了异常 HTTP 状态。"
        case .invalidResponse:
            return "服务器返回的数据无法识别。"
        case .api(let message):
            return message
        }
    }
}
