import SwiftUI

struct FullscreenLyricsView: View {
    @ObservedObject var player: PlayerViewModel
    @EnvironmentObject private var settings: PlayerSettings
    @Environment(\.dismiss) private var dismiss
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: settings.theme.colors,
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .hueRotation(.degrees(animateGradient ? 16 : -16))
            .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animateGradient)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.headline)
                            .frame(width: 42, height: 42)
                            .background(.white.opacity(0.12), in: Circle())
                    }
                    Spacer()
                    VStack(spacing: 3) {
                        Text(player.currentTrack?.title ?? "Folia")
                            .font(.headline)
                            .lineLimit(1)
                        Text(player.currentTrack?.artist ?? "沉浸式歌词")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    Spacer()
                    Button(action: player.togglePlayback) {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.headline)
                            .frame(width: 42, height: 42)
                            .background(.white.opacity(0.12), in: Circle())
                    }
                    .accessibilityLabel(player.isPlaying ? "暂停" : "播放")
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .foregroundStyle(.white)

                Spacer(minLength: 24)

                if player.lyrics.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 42, weight: .light))
                            .foregroundStyle(.white.opacity(0.55))
                        Text("还没有匹配的 LRC 歌词")
                            .font(.title3.weight(.medium))
                        Text("播放歌曲后，点击歌词按钮导入对应的 .lrc 文件")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    .foregroundStyle(.white)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 26) {
                                ForEach(Array(player.lyrics.enumerated()), id: \.offset) { pair in
                                    let index = pair.offset
                                    let line = pair.element
                                    Text(line.text.isEmpty ? "♪" : line.text)
                                        .font(.system(size: index == player.currentLyricIndex ? settings.lyricFontSize : settings.lyricFontSize * 0.78, weight: index == player.currentLyricIndex ? .bold : .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(index == player.currentLyricIndex ? 1.0 : 0.38))
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                        .scaleEffect(index == player.currentLyricIndex ? 1.0 : 0.97)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.78), value: player.currentLyricIndex)
                                        .id(index)
                                }
                            }
                            .padding(.horizontal, 28)
                            .padding(.vertical, 180)
                        }
                        .onAppear {
                            proxy.scrollTo(player.currentLyricIndex, anchor: .center)
                        }
                        .onChange(of: player.currentLyricIndex) { _, newIndex in
                            withAnimation(.easeInOut(duration: 0.45)) {
                                proxy.scrollTo(newIndex, anchor: .center)
                            }
                        }
                    }
                }

                Spacer(minLength: 24)

                VStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { player.currentTime },
                            set: { player.seek(to: $0) }
                        ),
                        in: 0...max(player.duration, 1)
                    )
                    .tint(.white)
                    HStack {
                        Text(player.formattedTime(player.currentTime))
                        Spacer()
                        Text(player.formattedTime(player.duration))
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .onAppear { animateGradient = true }
    }
}
