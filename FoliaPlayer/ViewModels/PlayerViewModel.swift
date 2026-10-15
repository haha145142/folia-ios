import AVFoundation
import Combine
import Foundation
import MediaPlayer
import UIKit

@MainActor
final class PlayerViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var tracks: [Track] = []
    @Published private(set) var currentTrack: Track?
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var lyrics: [LyricLine] = []
    @Published var errorMessage: String?

    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private let tracksStorageKey = "folia.player.tracks.v1"

    var currentLyricIndex: Int {
        guard !lyrics.isEmpty else { return 0 }
        return lyrics.lastIndex(where: { currentTime >= $0.time }) ?? 0
    }

    override init() {
        super.init()
        configureAudioSession()
        loadTracks()
        configureRemoteCommands()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    deinit {
        progressTimer?.invalidate()
    }

    func play(_ track: Track) {
        if currentTrack?.id == track.id, audioPlayer != nil {
            togglePlayback()
            return
        }

        let url = mediaDirectory.appendingPathComponent(track.fileName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "找不到音频文件：\(track.title)"
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.prepareToPlay()
            audioPlayer = player
            currentTrack = track
            duration = player.duration
            currentTime = 0
            loadLyrics(for: track)
            try AVAudioSession.sharedInstance().setActive(true)
            isPlaying = player.play()
            startProgressTimer()
            updateNowPlayingInfo()
        } catch {
            errorMessage = "无法播放该文件：\(error.localizedDescription)"
        }
    }

    func togglePlayback() {
        guard let player = audioPlayer else {
            if let track = currentTrack { play(track) }
            return
        }
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                isPlaying = player.play()
            } catch {
                errorMessage = "无法恢复音频会话：\(error.localizedDescription)"
            }
        }
        updateNowPlayingInfo()
    }

    func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        let bounded = min(max(0, time), max(0, player.duration))
        player.currentTime = bounded
        currentTime = bounded
        updateNowPlayingInfo()
    }

    func importAudio(from urls: [URL]) {
        var imported = 0
        for sourceURL in urls {
            let accessed = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if accessed { sourceURL.stopAccessingSecurityScopedResource() }
            }

            let ext = sourceURL.pathExtension.isEmpty ? "audio" : sourceURL.pathExtension
            let destination = mediaDirectory.appendingPathComponent("\(UUID().uuidString).\(ext)")
            do {
                try FileManager.default.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: sourceURL, to: destination)
                let track = Track(
                    title: sourceURL.deletingPathExtension().lastPathComponent,
                    fileName: destination.lastPathComponent
                )
                tracks.append(track)
                imported += 1
            } catch {
                errorMessage = "导入失败：\(sourceURL.lastPathComponent)（\(error.localizedDescription)）"
            }
        }
        saveTracks()
        if imported > 0 {
            errorMessage = "已导入 \(imported) 首音频。"
        }
    }

    func importLyrics(from sourceURL: URL) {
        guard let track = currentTrack else {
            errorMessage = "请先选择并播放一首歌曲，再导入对应的 LRC 歌词。"
            return
        }

        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessed { sourceURL.stopAccessingSecurityScopedResource() }
        }
        guard let source = try? String(contentsOf: sourceURL, encoding: .utf8) else {
            errorMessage = "无法读取歌词文件，请确认它是 UTF-8 编码的 LRC。"
            return
        }

        do {
            try FileManager.default.createDirectory(at: lyricsDirectory, withIntermediateDirectories: true)
            let filename = "\(track.id.uuidString).lrc"
            let destination = lyricsDirectory.appendingPathComponent(filename)
            try source.write(to: destination, atomically: true, encoding: .utf8)
            if let index = tracks.firstIndex(where: { $0.id == track.id }) {
                tracks[index].lyricFileName = filename
                currentTrack = tracks[index]
            }
            lyrics = LRCParser.parse(source)
            saveTracks()
            errorMessage = lyrics.isEmpty ? "歌词文件已导入，但没有识别到时间戳。" : "LRC 歌词已导入。"
        } catch {
            errorMessage = "保存歌词失败：\(error.localizedDescription)"
        }
    }

    func formattedTime(_ time: TimeInterval) -> String {
        guard time.isFinite else { return "0:00" }
        let totalSeconds = max(0, Int(time))
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = duration
        updateNowPlayingInfo()
    }

    private var mediaDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Media", isDirectory: true)
    }

    private var lyricsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Lyrics", isDirectory: true)
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        } catch {
            errorMessage = "音频会话初始化失败：\(error.localizedDescription)"
        }
    }

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.changePlaybackPositionCommand.isEnabled = true

        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if !self.isPlaying { self.togglePlayback() }
            }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isPlaying else { return }
                self.togglePlayback()
            }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlayback() }
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in self?.seek(to: event.positionTime) }
            return .success
        }
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let player = self.audioPlayer else { return }
                self.currentTime = player.currentTime
                self.duration = player.duration
                self.isPlaying = player.isPlaying
                self.updateNowPlayingInfo()
            }
        }
    }

    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyAlbumTitle: "Folia Player",
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
    }

    private func loadLyrics(for track: Track) {
        guard let filename = track.lyricFileName else {
            lyrics = []
            return
        }
        let url = lyricsDirectory.appendingPathComponent(filename)
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            lyrics = []
            return
        }
        lyrics = LRCParser.parse(contents)
    }

    private func loadTracks() {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? fileManager.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)

        var restored: [Track] = []
        if let data = UserDefaults.standard.data(forKey: tracksStorageKey),
           let saved = try? JSONDecoder().decode([Track].self, from: data) {
            restored = saved.filter {
                fileManager.fileExists(atPath: mediaDirectory.appendingPathComponent($0.fileName).path)
            }
        }

        // iTunes/Finder File Sharing places copied files in Documents. Move supported audio
        // files into the media folder, then index any files that are not in UserDefaults yet.
        let supportedExtensions: Set<String> = ["mp3", "m4a", "m4b", "aac", "wav", "aif", "aiff", "caf", "alac", "mp4"]
        if let topLevelFiles = try? fileManager.contentsOfDirectory(
            at: documents,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            for source in topLevelFiles where supportedExtensions.contains(source.pathExtension.lowercased()) {
                let originalName = source.lastPathComponent
                var destination = mediaDirectory.appendingPathComponent(originalName)
                if fileManager.fileExists(atPath: destination.path) {
                    destination = mediaDirectory.appendingPathComponent("\(UUID().uuidString)_\(originalName)")
                }
                do {
                    try fileManager.moveItem(at: source, to: destination)
                    restored.append(Track(
                        title: source.deletingPathExtension().lastPathComponent,
                        fileName: destination.lastPathComponent
                    ))
                } catch {
                    continue
                }
            }
        }

        let knownNames = Set(restored.map(\.fileName))
        if let mediaFiles = try? fileManager.contentsOfDirectory(
            at: mediaDirectory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            for file in mediaFiles where supportedExtensions.contains(file.pathExtension.lowercased()) {
                guard !knownNames.contains(file.lastPathComponent) else { continue }
                restored.append(Track(
                    title: file.deletingPathExtension().lastPathComponent,
                    fileName: file.lastPathComponent
                ))
            }
        }

        tracks = restored
        saveTracks()
    }

    private func saveTracks() {
        guard let data = try? JSONEncoder().encode(tracks) else { return }
        UserDefaults.standard.set(data, forKey: tracksStorageKey)
    }
}
