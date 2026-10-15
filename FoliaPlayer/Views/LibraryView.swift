import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @ObservedObject var player: PlayerViewModel
    @State private var showingAudioImporter = false
    @State private var showingLyricsImporter = false
    @State private var showingFullscreenLyrics = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Label("本地曲库", systemImage: "waveform")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Button {
                        showingAudioImporter = true
                    } label: {
                        Label("导入音乐", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)

                    Button {
                        showingLyricsImporter = true
                    } label: {
                        Image(systemName: "text.alignleft")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("为当前歌曲导入 LRC 歌词")
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                List {
                    if player.tracks.isEmpty {
                        ContentUnavailableView(
                            "曲库还是空的",
                            systemImage: "music.note",
                            description: Text("从“文件”App 导入音频，支持系统可识别的音频格式。")
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(player.tracks) { track in
                            Button {
                                player.play(track)
                            } label: {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(player.currentTrack?.id == track.id ? Color.primary.opacity(0.16) : Color.secondary.opacity(0.10))
                                        .frame(width: 46, height: 46)
                                        .overlay {
                                            Image(systemName: player.currentTrack?.id == track.id && player.isPlaying ? "waveform" : "music.note")
                                                .font(.system(size: 17, weight: .medium))
                                        }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(track.title)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        Text(track.artist + (track.lyricFileName == nil ? "" : "  ·  有歌词"))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer(minLength: 4)
                                    if player.currentTrack?.id == track.id {
                                        Image(systemName: player.isPlaying ? "speaker.wave.2.fill" : "pause.fill")
                                            .foregroundStyle(.primary)
                                            .font(.subheadline)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.plain)

                if player.currentTrack != nil {
                    NowPlayingPanel(player: player) {
                        showingFullscreenLyrics = true
                    }
                }
            }
            .navigationTitle("Folia")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAudioImporter = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .accessibilityLabel("导入音乐")
                }
            }
            .fileImporter(
                isPresented: $showingAudioImporter,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls): player.importAudio(from: urls)
                case .failure(let error): player.errorMessage = "选择音频失败：\(error.localizedDescription)"
                }
            }
            .fileImporter(
                isPresented: $showingLyricsImporter,
                allowedContentTypes: [UTType(filenameExtension: "lrc") ?? .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first { player.importLyrics(from: url) }
                case .failure(let error): player.errorMessage = "选择歌词失败：\(error.localizedDescription)"
                }
            }
            .fullScreenCover(isPresented: $showingFullscreenLyrics) {
                FullscreenLyricsView(player: player)
            }
            .alert(
                "提示",
                isPresented: Binding(
                    get: { player.errorMessage != nil },
                    set: { if !$0 { player.errorMessage = nil } }
                )
            ) {
                Button("好", role: .cancel) { player.errorMessage = nil }
            } message: {
                Text(player.errorMessage ?? "")
            }
        }
    }
}

private struct NowPlayingPanel: View {
    @ObservedObject var player: PlayerViewModel
    var showLyrics: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(player.currentTrack?.title ?? "未播放")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(player.currentTrack?.artist ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: showLyrics) {
                    Image(systemName: "quote.bubble")
                        .font(.title3)
                        .padding(6)
                }
                .accessibilityLabel("打开全屏歌词")
                Button(action: player.togglePlayback) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 42, height: 42)
                        .background(Color.primary.opacity(0.08), in: Circle())
                }
                .accessibilityLabel(player.isPlaying ? "暂停" : "播放")
            }

            Slider(
                value: Binding(
                    get: { player.currentTime },
                    set: { player.seek(to: $0) }
                ),
                in: 0...max(player.duration, 1)
            )
            HStack {
                Text(player.formattedTime(player.currentTime))
                Spacer()
                Text(player.formattedTime(player.duration))
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}
