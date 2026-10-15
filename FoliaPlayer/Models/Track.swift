import Foundation

struct Track: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var artist: String
    var fileName: String
    var lyricFileName: String?
    var duration: TimeInterval?

    init(
        id: UUID = UUID(),
        title: String,
        artist: String = "本地音乐",
        fileName: String,
        lyricFileName: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.fileName = fileName
        self.lyricFileName = lyricFileName
        self.duration = duration
    }
}
